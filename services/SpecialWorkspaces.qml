pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.theme

// which special workspace each monitor is showing, and where the console's windows
// sit on it.
//
// a special workspace is drawn over a normal one and is never its monitor's
// activeWorkspace, and quickshell's HyprlandMonitor has no property for it. the
// monitors snapshot carries it, as specialWorkspace.name, which is what the state
// at startup comes from; after that activespecialv2 says so directly. the event
// wins because it is a round-trip sooner, and the console notch's retract has to
// start in step with hyprland's.
Singleton {
  id: root

  // monitor name -> what activespecialv2 last said it is showing.
  property var heard: ({})

  // monitor name -> the special workspace it is showing, "" for none.
  readonly property var shown: {
    const out = {}

    for (const monitor of Hyprland.monitors.values) {
      out[monitor.name] = monitor.name in root.heard
        ? root.heard[monitor.name]
        : monitor.lastIpcObject?.specialWorkspace?.name ?? ""
    }

    return out
  }

  function on(monitorName: string): string {
    return root.shown[monitorName] ?? ""
  }

  // a window the console notch frames. those carry no focus mark of their own: the
  // notch around them already says where they are, and a mark above one would sit
  // in the tab band, half under the tabs.
  function framed(toplevel: HyprlandToplevel): bool {
    return Theme.consoleWorkspace !== ""
      && (toplevel?.workspace?.name ?? "") === Theme.consoleWorkspace
  }

  // the rects of the console's tiled windows on a monitor, in global logical
  // pixels. floating windows are left out: qconsole.lua sizes the panel by its
  // gaps, which only lay out tiled ones.
  //
  // as fresh as the toplevels snapshot, which FocusedWindow refreshes; focus moves
  // onto the console as it opens, and that is one of its events.
  function windows(monitor: HyprlandMonitor): var {
    const out = []

    for (const toplevel of Hyprland.toplevels.values) {
      if (!root.framed(toplevel) || toplevel.monitor !== monitor) continue

      const ipc = toplevel.lastIpcObject ?? {}
      if (ipc.floating || ipc.hidden || !ipc.at || !(ipc.size?.[0] > 0)) continue

      out.push(Qt.rect(ipc.at[0], ipc.at[1], ipc.size[0], ipc.size[1]))
    }

    return out
  }

  Component.onCompleted: Hyprland.refreshMonitors()

  Connections {
    target: Hyprland

    // activespecialv2 is `id,name,monitor`, with the first two empty on a close. a
    // special workspace moved to another monitor is a moveworkspacev2, which says
    // where it went but not what the monitor it left is showing now, so that one
    // forgets what was heard and goes back to the snapshot.
    function onRawEvent(event: HyprlandEvent): void {
      if (event.name === "activespecialv2") {
        const [, name, monitor] = event.parse(3)

        root.heard = Object.assign({}, root.heard, { [monitor]: name })
      } else if (event.name === "moveworkspacev2") {
        root.heard = {}
        Hyprland.refreshMonitors()
      }
    }
  }
}
