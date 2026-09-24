pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.theme

// where the focused window is, for whatever wants to mark it. a singleton because
// the geometry is one global fact and FrameWindow is instantiated once per
// monitor: three frames each refreshing on their own would be three `hyprctl
// clients` round-trips for one focus change.
//
// hyprland keeps Hyprland.activeToplevel current by itself off activewindowv2, so
// *which* window has focus needs no work here. this exists entirely for *where* it
// is, which quickshell only exposes through lastIpcObject -- a snapshot of
// `hyprctl clients` that nothing refreshes implicitly.
Singleton {
  id: root

  // Hyprland.activeToplevel is driven off activewindowv2, which only fires when
  // focus *changes*. on a freshly started shell nothing has changed yet, so it is
  // null and stays null until you switch windows once: the indicator was dark for
  // the whole session if you never did, which on a single window desktop is every
  // session. the refreshed snapshot carries focusHistoryID, where 0 is the window
  // that has focus, so the opening state can be read straight out of it.
  //
  // only a fallback: the live property wins the moment hyprland fills it in, and
  // the snapshot only moves when something refreshes it.
  readonly property HyprlandToplevel toplevel: Hyprland.activeToplevel ?? root.snapshotToplevel

  readonly property HyprlandToplevel snapshotToplevel: {
    const all = Hyprland.toplevels.values

    return all.find(tl => (tl.lastIpcObject?.focusHistoryID ?? -1) === 0) ?? null
  }

  // the monitor the focused window is on, so a per-screen consumer can tell
  // whether the mark belongs to it.
  readonly property HyprlandMonitor monitor: root.toplevel?.monitor ?? null

  // hyprland reports `at` and `size` in global logical pixels, the same space
  // HyprlandMonitor.x/y are in, so a consumer converts to screen-local by
  // subtracting the monitor's origin. (HyprlandMonitor.width/height are *physical*
  // pixels and do not belong in that arithmetic.)
  //
  // an empty rect while the snapshot has no geometry for this window yet, which is
  // the state on the first frame and for a window that is mapped but not placed.
  readonly property rect geometry: {
    const ipc = root.toplevel?.lastIpcObject
    if (!ipc?.at || !ipc?.size) return Qt.rect(0, 0, 0, 0)

    return Qt.rect(ipc.at[0], ipc.at[1], ipc.size[0], ipc.size[1])
  }

  // a fullscreen window is the only thing on its monitor, so there is nothing to
  // disambiguate and nothing to mark.
  readonly property bool fullscreen: (root.toplevel?.lastIpcObject?.fullscreen ?? 0) !== 0

  readonly property bool floating: root.toplevel?.lastIpcObject?.floating ?? false

  // every event that can move a window, and none that cannot. the omission that
  // matters is windowtitlev2: a terminal running anything with a spinner emits it
  // several times a second, and refreshing on it would mean an ipc round-trip plus
  // a json parse of every client on the system, continuously, to learn nothing.
  //
  // hyprland emits no event at all for a resize or a layout reflow, so a window
  // dragged or resized with the mouse only settles when something else fires.
  // acceptable for a mark in one corner; it would not be for an outline.
  readonly property var geometryEvents: [
    "activewindowv2",
    "openwindow",
    "closewindow",
    "movewindow",
    "movewindowv2",
    "changefloatingmode",
    "fullscreen",
    "workspacev2",
    "moveintogroup",
    "moveoutofgroup",
    "togglegroup",
    "monitoradded",
    "monitoraddedv2",
    "monitorremoved",
    "monitorremovedv2",
    "configreloaded",
  ]

  // lastIpcObject is empty until something asks for it, so an indicator would have
  // nowhere to sit until the first focus change without this.
  //
  // and again once the shell has settled. this refresh runs before the shell's own
  // reservation windows have claimed their edges, so it reads the layout as it was
  // before everything reflowed around them -- a window five pixels wider and thirty
  // higher than it ends up. hyprland emits no event for that reflow, and on a quiet
  // single window desktop nothing else ever fires, so without the second pass the
  // stale rect is what the indicator sits on for the whole session.
  Component.onCompleted: {
    Hyprland.refreshToplevels()
    settle.restart()
  }

  Connections {
    target: Hyprland

    function onRawEvent(event: HyprlandEvent): void {
      if (!root.geometryEvents.includes(event.name)) return

      debounce.restart()
      settle.restart()
    }
  }

  // hyprland fires several of these at once when a window opens or closes. one
  // refresh for the burst.
  Timer {
    id: debounce

    interval: Theme.focusDebounce
    onTriggered: Hyprland.refreshToplevels()
  }

  // and one more once the open/close animation has finished moving everything
  // else. the debounced refresh lands mid-animation and reads the layout as it was
  // before the reflow, which would leave the mark on the focused window's old rect
  // until the next event happened to correct it.
  Timer {
    id: settle

    interval: Theme.focusSettle
    onTriggered: Hyprland.refreshToplevels()
  }
}
