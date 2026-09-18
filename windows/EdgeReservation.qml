import Quickshell
import Quickshell.Wayland

// exclusiveZone is a single int for the whole window, so reserving a different
// amount on the top edge than on the other three needs one window per edge.
// these never paint and never take input; they exist only to shrink hyprland's
// usable area.
PanelWindow {
  id: root

  required property string edge
  required property int zone

  // anchor triplets on purpose: hyprland only resolves an exclusive edge for a
  // surface anchored to exactly one edge, or to that edge plus its neighbours.
  anchors {
    top: root.edge !== "bottom"
    bottom: root.edge !== "top"
    left: root.edge !== "right"
    right: root.edge !== "left"
  }

  // the reserved amount comes from exclusiveZone, not from the surface size, so
  // 1px keeps the buffer at nothing.
  implicitWidth: 1
  implicitHeight: 1

  exclusiveZone: root.zone

  // explicit: Auto would derive the zone from the anchors and the 1px size.
  exclusionMode: ExclusionMode.Normal
  color: "transparent"

  // an empty region is an empty wayland input region: fully click-through.
  mask: Region {}

  WlrLayershell.layer: WlrLayer.Background
  WlrLayershell.namespace: `qs-reserve-${root.edge}`
}
