import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.components
import qs.modules
import qs.services
import qs.theme

// the launcher surface: a fullscreen overlay on one monitor holding the scrim and
// the panel. exists only while the launcher is open.
ModalWindow {
  id: root

  fade: Theme.launcherFade
  scrimColor: Theme.launcherScrim

  WlrLayershell.namespace: "qs-launcher"

  onScrimClicked: Launcher.close()
  onGrabCleared: Launcher.close()

  Connections {
    target: Launcher

    // re-opening during the fade-out simply reverses it: same property, same
    // Behavior, no second window.
    function onOpenedChanged(): void {
      root.shown = Launcher.opened
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
      Glide { duration: Theme.launcherSlideDuration }
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

    // the polkit card's shadow, which this card borrows along with its width.
    RectangularShadow {
      x: card.x
      y: card.y
      width: card.width
      height: card.height
      scale: card.scale
      radius: Theme.notchRadius
      blur: Theme.pkShadowBlur
      spread: 0
      offset.y: Theme.pkShadowOffset
      color: Theme.pkShadow
    }

    ConfirmDialog {
      id: card

      anchors.centerIn: parent

      // kept alive through the fade out: reading the row's name off a row that
      // has already gone would empty the card while it is still on screen.
      action: panel.pending ?? lastPending.row

      confirming: panel.confirmChoice

      scale: panel.pending ? 1 : Theme.pkScaleFrom

      Behavior on scale {
        Glide { duration: Theme.pkRise }
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
