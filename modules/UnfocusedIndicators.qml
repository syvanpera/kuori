import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.services
import qs.theme

// the same mark as the focused window's, in Theme.focusUnfocusedColor, on every
// other window this monitor is showing. one delegate per window rather than one
// indicator that moves, so nothing here has the travelling problem FocusIndicator
// blanks a frame to avoid: each mark only ever follows its own window.
//
// the geometry comes from the same refreshed snapshot FocusedWindow reads, and
// refreshToplevels() refreshes every window at once, so these are exactly as fresh
// as the focused one's.
Item {
  id: root

  required property HyprlandMonitor monitor

  anchors.fill: parent

  visible: Theme.focusMarkUnfocused

  Repeater {
    model: Theme.focusMarkUnfocused ? Hyprland.toplevels : null

    WindowMarker {
      id: marker

      required property HyprlandToplevel modelData

      readonly property var ipc: marker.modelData.lastIpcObject ?? {}

      // a special workspace is open over a normal one and is never its monitor's
      // activeWorkspace, so which one is showing comes from SpecialWorkspaces.
      // while one is, the windows of the workspace underneath go unmarked: these
      // marks are drawn above every window, so theirs landed across whatever the
      // special workspace put over them, and hyprland has dimmed them out of the
      // picture anyway.
      readonly property bool onShownWorkspace: {
        const ws = marker.modelData.workspace
        if (!ws) return false

        const special = SpecialWorkspaces.on(root.monitor?.name ?? "")

        if (ws.id < 0) return ws.name === special

        return special === "" && ws === root.monitor?.activeWorkspace
      }

      // a fullscreen window covers the rest of its workspace, so there is nothing
      // on it left to mark; a hidden one is a group member behind its tab; a
      // floating one is hyprland's to border, as in FocusIndicator; the console
      // has its notch.
      readonly property bool lit: marker.modelData !== FocusedWindow.toplevel
        && marker.modelData.monitor === root.monitor
        && marker.onShownWorkspace
        && !SpecialWorkspaces.framed(marker.modelData)
        && !(marker.modelData.workspace?.hasFullscreen ?? false)
        && !(marker.ipc.hidden ?? false)
        && (Theme.focusMarkFloating || !(marker.ipc.floating ?? false))
        && (marker.ipc.mapped ?? true)
        && (marker.ipc.size?.[0] ?? 0) > 0

      // global logical pixels, less the monitor's origin, as in FocusIndicator.
      windowX: (marker.ipc.at?.[0] ?? 0) - (root.monitor?.x ?? 0)
      windowY: (marker.ipc.at?.[1] ?? 0) - (root.monitor?.y ?? 0)
      windowWidth: marker.ipc.size?.[0] ?? 0
      windowHeight: marker.ipc.size?.[1] ?? 0

      color: Theme.focusUnfocusedColor

      opacity: marker.lit ? 1 : 0
      visible: marker.opacity > 0

      // in on the same fade as the focused mark, out at once, so the window focus
      // just left greys in step with the one it went to lighting up.
      Behavior on opacity {
        NumberAnimation {
          duration: marker.lit ? Theme.focusFade : 0
          easing.type: Easing.OutCubic
        }
      }
    }
  }
}
