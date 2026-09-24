pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.theme

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

  // the main monitor. hyprland has no such thing -- no monitor is marked primary
  // anywhere in what it reports -- so it is the one workspace 1 is on: the user's
  // own monitors.lua pins that workspace, so this follows their config and has
  // nothing of its own to keep in step. the focused screen stands in until
  // hyprland has said where workspace 1 is, or if it does not exist.
  readonly property var main: {
    const name = Hyprland.workspaces.values.find(ws => ws.id === 1)?.monitor?.name ?? ""
    const screens = Array.from(Quickshell.screens)

    return screens.find(screen => screen.name === name) ?? root.focused
  }

  readonly property string mainName: root.main?.name ?? ""

  // the screen a keybind or an ipc call means when it names none: the one with
  // the tabs on it, or with tabs everywhere, the one being worked on.
  readonly property string tabsName: Theme.tabScreens === "all" ? (root.focused?.name ?? "") : root.mainName

  // whether a screen carries the tabs. every question about it comes here, so
  // Theme.tabScreens means the same thing everywhere.
  function hasTabs(name: string): bool {
    return Theme.tabScreens === "all" || name === root.mainName
  }
}
