import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.modules
import qs.services
import qs.theme

// the only window that paints. it covers the whole screen so the border, the
// notches and (stage 2) the panels that drop out of them share one coordinate
// space, which is the only way the rounded corners come out seamless.
PanelWindow {
  id: root

  // anchored to every edge with exclusion ignored, so this item's origin is the
  // monitor's top-left in logical pixels -- the same space hyprland reports window
  // positions in, offset by the monitor's own origin.
  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // a surface anchored to all four edges can never reserve space, and without
  // Ignore hyprland would place this one inside the area the reservation windows
  // already claimed, pulling the frame inboard on every reload.
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  // the border is decoration and never takes a click; only the tabs do. a wayland
  // input region gates pointer enter and leave as well as clicks, so hover in
  // stage 2 only works for what is listed here. the focus mark is deliberately
  // absent: it sits on top of a window and must never eat its clicks.
  mask: Region {
    Region { item: workspaces.hitArea }
    Region { item: clock.hitArea }
    Region { item: system.hitArea }
  }

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "qs-frame"

  // a press that lands over a window hands focus to that window, and the pointer
  // leave that follows cancels the click before it finishes. the grab keeps input
  // on the shell while a panel is out, which is also what makes a click anywhere
  // else dismiss it.
  HyprlandFocusGrab {
    windows: [root]
    active: Notches.open !== ""

    onCleared: Notches.close()
  }

  // before the frame on purpose: the band is drawn over the top of these, so a
  // notch casts onto the desktop below it without smearing the rail it hangs off.
  NotchShadow { notch: workspaces }
  NotchShadow { notch: clock }
  NotchShadow { notch: system }

  DesktopFrame {
    anchors.fill: parent
  }

  // between the frame and the notches, so a window sitting against the top edge
  // gets its indicator drawn under the tabs rather than over them.
  FocusIndicator {
    monitor: root.monitor
  }

  Notch {
    id: workspaces

    x: Theme.borderWidth
    y: Theme.borderWidth
    placement: "left"
    notchId: "workspaces"

    panel: Component {
      WorkspacePanel {}
    }

    WorkspaceDots {}
  }

  Notch {
    id: clock

    x: Math.round((root.width - width) / 2)
    y: Theme.borderWidth
    placement: "center"
    notchId: "clock"
    trigger: "click"

    panel: Component {
      ClockPanel {}
    }

    ClockLabel {
      peeking: clock.hovered
    }
  }

  Notch {
    id: system

    x: root.width - width - Theme.borderWidth
    y: Theme.borderWidth
    placement: "right"
    notchId: "system"
    trigger: "click"

    panel: Component {
      SystemPanel {}
    }

    SystemStatus {}
  }
}
