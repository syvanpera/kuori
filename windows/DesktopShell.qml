import Quickshell
import qs.services
import qs.theme

// everything one monitor needs. all five windows live in one scope so Variants
// creates and destroys them together when a monitor is plugged or unplugged,
// which stops a screen ever having reserved space with no frame drawn in it.
Scope {
  id: root

  required property var modelData

  // whether this monitor carries the tabs (Theme.tabScreens). one that does not
  // keeps the border and gives the band the tabs hang in back to windows.
  readonly property bool tabs: Screens.hasTabs(root.modelData.name)

  FrameWindow {
    screen: root.modelData
    tabs: root.tabs
  }

  EdgeReservation {
    screen: root.modelData
    edge: "top"
    zone: Theme.borderWidth + (root.tabs ? Theme.notchHeight : 0)
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
