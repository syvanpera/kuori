pragma Singleton
import Quickshell
import Quickshell.Hyprland

// the workspace slots the shell shows, in one place because the collapsed dots
// and the panel they open onto have to agree: a tab showing three dots that opens
// onto five pills would be its own kind of wrong.
Singleton {
  id: root

  // hyprland only reports workspaces that exist. padding up to a floor stops the
  // tab resizing every time the last window on a workspace closes.
  property int minimum: 5

  // one entry per slot, null where the workspace does not exist. this rebuilds
  // only when workspaces appear or disappear; per-slot state is read off the
  // workspace objects themselves, so it stays live without rebuilding the list.
  readonly property var slots: {
    // negative ids are hyprland's special workspaces, which get no slot.
    const live = Hyprland.workspaces.values.filter(ws => ws.id > 0)
    const highest = live.reduce((max, ws) => Math.max(max, ws.id), 0)
    const out = []

    for (let id = 1; id <= Math.max(root.minimum, highest); id++) {
      out.push(live.find(ws => ws.id === id) ?? null)
    }

    return out
  }
}
