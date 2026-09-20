import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.modules
import qs.services
import qs.theme

// the surface the authentication dialog lives on. the same shape as the launcher
// window, and for the same reasons -- see LauncherWindow for the long versions.
PanelWindow {
  id: root

  property bool shown: false

  signal dismissed()

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  // Overlay, not Top: a password prompt that a fullscreen window can cover is
  // worse than no prompt at all.
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "qs-polkit"

  // whatever was focused when this appeared did not ask for the next keystroke,
  // and the next keystroke is a password.
  WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  mask: Region { item: root.shown ? scrim : null }

  Component.onCompleted: root.shown = true

  onShownChanged: {
    if (root.shown) {
      exit.stop()
      return
    }

    grab.active = false
    exit.restart()
  }

  // a Behavior runs its animation without ever emitting finished(), so the
  // teardown is timed rather than chained off it.
  Timer {
    id: exit

    interval: Theme.pkFade

    onTriggered: root.dismissed()
  }

  Connections {
    target: Polkit

    function onFlowChanged(): void {
      root.shown = Polkit.flow !== null
    }
  }

  HyprlandFocusGrab {
    id: grab

    windows: [root]

    // clicking away does not answer the question. polkit is still waiting, so the
    // card stays and only Cancel or a password ends it.
    onCleared: grab.active = true
  }

  Timer {
    interval: 1
    running: root.shown

    onTriggered: grab.active = true
  }

  MouseArea {
    id: scrim

    anchors.fill: parent
    opacity: root.shown ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Theme.pkFade }
    }

    Rectangle {
      anchors.fill: parent
      color: Theme.pkScrim
    }
  }

  RectangularShadow {
    x: dialog.x
    y: dialog.y
    width: dialog.width
    height: dialog.height
    radius: Theme.notchRadius
    blur: Theme.pkShadowBlur
    spread: 0
    offset.y: Theme.pkShadowOffset
    color: Theme.pkShadow
    opacity: dialog.opacity
  }

  PolkitDialog {
    id: dialog

    x: Math.round((root.width - width) / 2)
    y: Math.round((root.height - height) / 2)

    flow: Polkit.flow
    opacity: root.shown ? 1 : 0
    scale: root.shown ? 1 : Theme.pkScaleFrom

    onSubmitted: value => Polkit.flow?.submit(value)
    onCancelled: Polkit.flow?.cancelAuthenticationRequest()

    Behavior on opacity {
      NumberAnimation { duration: Theme.pkFade }
    }

    Behavior on scale {
      NumberAnimation {
        duration: Theme.pkRise
        easing.type: Easing.Bezier
        easing.bezierCurve: Theme.easeStandard
      }
    }
  }
}
