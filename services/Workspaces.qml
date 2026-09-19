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

  // switch to a slot. an existing workspace has an object to activate; one
  // hyprland has never heard of does not, so it has to be summoned by id.
  //
  // that dispatch is lua, not the classic "workspace 4" string: this config is a
  // lua one, and hyprland answers the old form with a syntax error that nothing
  // here would ever see. it lives in the service so the dots and the panel cannot
  // drift apart on it again.
  function focus(id: int): void {
    const ws = root.slots[id - 1] ?? null

    if (ws) ws.activate()
    else Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`)
  }
}
