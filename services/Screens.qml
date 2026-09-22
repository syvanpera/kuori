pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// which monitor a window with no monitor of its own should appear on.
//
// the launcher, the polkit dialog and the toast stack are one surface each for the
// whole session rather than one per screen, so each of them has to answer this --
// and all three answered it with the same block of code until this existed.
Singleton {
  id: root

  // hyprland names its focused monitor and quickshell's screens carry the same
  // name. that name is the only link between the two: HyprlandMonitor has no
  // handle back onto a ShellScreen.
  readonly property var focused: {
    const name = Hyprland.focusedMonitor?.name ?? ""

    // Quickshell.screens is a qml list, not a js array. copying it once is cheaper
    // than being wrong about which array methods a sequence carries.
    const screens = Array.from(Quickshell.screens)

    return screens.find(screen => screen.name === name) ?? screens[0] ?? null
  }
}
