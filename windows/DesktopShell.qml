import Quickshell
import qs.theme

// everything one monitor needs. all five windows live in one scope so Variants
// creates and destroys them together when a monitor is plugged or unplugged,
// which stops a screen ever having reserved space with no frame drawn in it.
Scope {
  id: root

  required property var modelData

  FrameWindow {
    screen: root.modelData
  }

  EdgeReservation {
    screen: root.modelData
    edge: "top"
    zone: Theme.borderWidth + Theme.notchHeight
  }

  EdgeReservation {
    screen: root.modelData
    edge: "bottom"
    zone: Theme.borderWidth
  }

  EdgeReservation {
    screen: root.modelData
    edge: "left"
    zone: Theme.borderWidth
  }

  EdgeReservation {
    screen: root.modelData
    edge: "right"
    zone: Theme.borderWidth
  }
}
