import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.components
import qs.modules
import qs.services
import qs.theme

// the surface the authentication dialog lives on: a ModalWindow whose scrim does
// not dismiss it, because polkit has a caller waiting on an answer.
ModalWindow {
  id: root

  fade: Theme.pkFade
  scrimColor: Theme.pkScrim

  WlrLayershell.namespace: "qs-polkit"

  // clicking away does not answer the question. polkit is still waiting, so the
  // card stays and only Cancel or a password ends it.
  onGrabCleared: root.holdGrab()

  Connections {
    target: Polkit

    function onFlowChanged(): void {
      root.shown = Polkit.flow !== null
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
    scale: dialog.scale
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
      Glide { duration: Theme.pkRise }
    }
  }
}
