pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// every open window, most recently focused first.
//
// hyprland is the only thing that knows the workspace and the focus order, and
// the wayland foreign-toplevel handle is the only thing that can raise a window
// without a dispatch string -- which on this machine would have to be a lua
// expression. so the two halves of a window row come from two places.
Singleton {
  id: root

  // one record per window: { toplevel, cls, title, workspace, history }
  //
  // empty while the launcher is not on screen. every title is read in here, and
  // titles change constantly -- a terminal with a spinner in it renames itself
  // several times a second -- so a list nobody is looking at would be rebuilt and
  // re-sorted on every one of them.
  readonly property var entries: {
    if (!Launcher.mapped) return []

    const list = []

    for (const toplevel of Hyprland.toplevels.values) {
      const ipc = toplevel.lastIpcObject ?? {}

      list.push({
        toplevel: toplevel,
        cls: ipc.class ?? "",
        title: toplevel.title ?? "",
        workspace: toplevel.workspace?.name ?? "",

        // 0 is the focused window and hyprland counts back from there, which is
        // the only order a window switcher should offer. `activated` is not a
        // substitute: like activeToplevel it is driven by events a freshly
        // started shell never saw, and reads false for every window until focus
        // next changes (see services/FocusedWindow.qml).
        history: ipc.focusHistoryID ?? 9999
      })
    }

    return list.sort((a, b) => a.history - b.history)
  }

  // a dispatch, and not for want of trying the tidier route: the wayland
  // foreign-toplevel handle has an activate() and hyprland ignores it. it returns
  // without error and focus does not move, with no launcher and no focus grab
  // anywhere near it, so it is the compositor refusing rather than anything here.
  //
  // the lua form is the one thing that has to be right (see CLAUDE.md), and
  // hyprland's own error names the alternatives: "expected one of: direction,
  // monitor, window, urgent_or_last". the address needs its 0x, which the
  // toplevel's own property does not carry.
  function focus(entry: var): void {
    const address = entry?.toplevel?.address ?? ""

    if (address.length === 0) return

    Hyprland.dispatch(`hl.dsp.focus({ window = "address:${address.startsWith("0x") ? address : `0x${address}`}" })`)
  }

  function refresh(): void {
    Hyprland.refreshToplevels()
  }

  // titles change constantly and focusHistoryID only moves when refreshed, so the
  // list is re-read at the one moment it is about to be looked at. the first read
  // is here rather than in the connection below for the same reason Clipboard's
  // is: this singleton is not built until the panel asks it for rows, by which
  // time Launcher.opened has already changed.
  Component.onCompleted: root.refresh()

  Connections {
    target: Launcher

    function onOpenedChanged(): void {
      if (Launcher.opened) root.refresh()
    }
  }
}
