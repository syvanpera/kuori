import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.modules
import qs.theme

// the only window that paints. it covers the whole screen so the border, the
// notches and (stage 2) the panels that drop out of them share one coordinate
// space, which is the only way the rounded corners come out seamless.
PanelWindow {
  id: root

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
  // stage 2 only works for what is listed here.
  mask: Region {
    Region { item: workspaces.hitArea }
    Region { item: clock.hitArea }
    Region { item: system.hitArea }
  }

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "qs-frame"

  DesktopFrame {
    anchors.fill: parent
  }

  Notch {
    id: workspaces

    x: Theme.borderWidth
    y: Theme.borderWidth
    placement: "left"

    WorkspaceDots {}
  }

  Notch {
    id: clock

    x: Math.round((root.width - width) / 2)
    y: Theme.borderWidth
    placement: "center"

    ClockLabel {}
  }

  Notch {
    id: system

    x: root.width - width - Theme.borderWidth
    y: Theme.borderWidth
    placement: "right"

    SystemStatus {}
  }
}
