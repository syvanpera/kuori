import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.modules
import qs.services
import qs.theme

// the launcher surface: a fullscreen overlay on one monitor holding the scrim and
// the panel. exists only while the launcher is open.
PanelWindow {
  id: root

  // drives every transition. false for the first frame because a Behavior never
  // runs on the value a property was initialised with, and the design's entry
  // animation needs somewhere to come from.
  property bool shown: false

  // the loader waits for this instead of destroying the window the moment the
  // launcher closes, which would cut the exit animation off at frame one.
  signal dismissed()

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // same reasoning as the frame: a surface anchored to all four edges can never
  // reserve space, and anything but Ignore would fight the reservation windows
  // for the area they already claimed.
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  // Overlay, not Top: the frame sits on Top, and hyprland draws fullscreen windows
  // above Top, so a launcher on Top would be invisible in exactly the case where
  // it is most needed.
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "qs-launcher"

  // Exclusive because the keybind that opens this never clicks it, and without an
  // exclusive grab the first keystroke goes to whatever hyprland still thinks is
  // focused. dropped the instant we start closing, so the app just launched gets
  // the keyboard rather than an overlay on its way out. do not also set
  // PanelWindow.focusable: it writes this same value.
  WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  // and the input region goes with it. a mapped layer surface eats every click in
  // its region, including through the fade; an empty region hands the pointer back
  // to the desktop for those frames.
  mask: Region { item: root.shown ? scrim : null }

  Component.onCompleted: root.shown = true

  onShownChanged: {
    if (root.shown) {
      exit.stop()
      return
    }

    // the grab goes the moment we start closing, so the app just launched gets
    // the keyboard rather than an overlay on its way out.
    grab.active = false
    exit.restart()
  }

  // the window outlives the close only to play the fade out. a Behavior runs its
  // animation without ever emitting finished(), so the teardown is timed rather
  // than chained off the animation.
  Timer {
    id: exit

    interval: Theme.launcherFade

    onTriggered: root.dismissed()
  }

  Connections {
    target: Launcher

    // re-opening during the fade-out simply reverses it: same property, same
    // Behavior, no second window.
    function onOpenedChanged(): void {
      root.shown = Launcher.opened
    }
  }

  // the compositor is the only thing that can see a click on another monitor, or
  // focus being handed to a window by a keybind. cleared(), not activeChanged:
  // active also drops when we release the grab ourselves, and closing on that
  // would be a loop.
  HyprlandFocusGrab {
    id: grab

    windows: [root]

    onCleared: Launcher.close()
  }

  // one turn of the event loop after the surface is mapped. asking hyprland to
  // grab a surface it has not seen yet is answered with an immediate cleared(),
  // which would close the launcher on the frame it opened.
  Timer {
    interval: 1
    running: root.shown

    onTriggered: grab.active = true
  }

  // the backdrop, and the click-outside target: the panel sits on top and eats its
  // own clicks, so anything reaching here is outside the panel.
  MouseArea {
    id: scrim

    anchors.fill: parent
    opacity: root.shown ? 1 : 0

    onClicked: Launcher.close()

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.launcherFade
      }
    }

    Rectangle {
      anchors.fill: parent
      color: Theme.launcherScrim
    }
  }

  // the design's `0 24px 70px rgba(0,0,0,.5)`. analytic, like the workspace dot
  // glow: MultiEffect would rasterise a 520px panel into its own framebuffer on
  // every frame of the entry animation.
  RectangularShadow {
    x: panel.x
    y: panel.y
    width: panel.width
    height: panel.height
    radius: Theme.notchRadius
    blur: Theme.launcherShadowBlur
    spread: 0
    offset.y: Theme.launcherShadowOffset
    color: Theme.launcherShadow
    opacity: panel.opacity
  }

  AppLauncher {
    id: panel

    x: Math.round((root.width - width) / 2)

    // placed in the area windows actually get, not on the screen: the notches hang
    // 25px into the top of the desktop and the border takes 5 off the bottom, so
    // measuring against root.height alone would sit the panel low and let a tall
    // one run under the tabs. fullHeight rather than the panel's own height, so
    // neither a query that shortens the grid nor the clipboard's preview slides
    // the whole thing.
    y: Theme.borderWidth + Theme.notchHeight
      + Math.round((root.height - Theme.borderWidth * 2 - Theme.notchHeight - panel.fullHeight) * Theme.launcherBias)
      - (root.shown ? 0 : Theme.launcherRise)
    opacity: root.shown ? 1 : 0

    Behavior on y {
      NumberAnimation {
        duration: Theme.launcherSlideDuration
        easing.type: Easing.Bezier
        easing.bezierCurve: Theme.easeStandard
      }
    }

    Behavior on opacity {
      NumberAnimation { duration: Theme.launcherFade }
    }
  }
  // over the panel and its own scrim, because it is a question about the row that
  // was just chosen and nothing behind it should answer first. the launcher stays
  // up underneath: cancelling puts you back where you were.
  MouseArea {
    id: confirmScrim

    anchors.fill: parent
    visible: opacity > 0
    opacity: panel.pending ? 1 : 0

    // the design dismisses on a click outside the card, unlike the polkit dialog,
    // which has a caller waiting on an answer.
    onClicked: panel.resolve(false)

    Behavior on opacity {
      NumberAnimation { duration: Theme.pkFade }
    }

    Rectangle {
      anchors.fill: parent
      color: Theme.cfScrim
    }

    ConfirmDialog {
      anchors.centerIn: parent

      // kept alive through the fade out: reading the row's name off a row that
      // has already gone would empty the card while it is still on screen.
      action: panel.pending ?? lastPending.row

      confirming: panel.confirmChoice

      scale: panel.pending ? 1 : Theme.pkScaleFrom

      Behavior on scale {
        NumberAnimation {
          duration: Theme.pkRise
          easing.type: Easing.Bezier
          easing.bezierCurve: Theme.easeStandard
        }
      }

      onAccepted: panel.resolve(true)
      onRejected: panel.resolve(false)
    }
  }

  // the last row asked about, held one frame longer than the question itself.
  QtObject {
    id: lastPending

    property var row: null
  }

  Connections {
    target: panel

    function onPendingChanged(): void {
      if (panel.pending) lastPending.row = panel.pending
    }
  }
}
