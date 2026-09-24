import QtQuick
import qs.theme

// whichever indicator the theme asks for, placed against one window's rect in this
// item's coordinates. it knows nothing about focus: the focused window and every
// other one are drawn by this same item in two colours, so the two can never come
// to disagree about where a mark sits.
Item {
  id: root

  property real windowX: 0
  property real windowY: 0
  property real windowWidth: 0
  property real windowHeight: 0

  property color color: Theme.focusColor

  anchors.fill: parent

  // the corner wedge, tucked into the window's top-right.
  FocusMark {
    visible: Theme.focusStyle === "mark"
    color: root.color

    x: root.windowX + root.windowWidth - width
    y: root.windowY
  }

  // or the strip, sitting on the window's top edge. placed against that edge
  // rather than inside the gap above it, so changing hyprland's gaps moves the
  // window and the strip together and nothing here needs to know what they are.
  // it is taller than the bar, by the horns that reach down into the window's
  // rounded corners, so it is the bar that is positioned here and not the item.
  FocusStrip {
    id: strip

    visible: Theme.focusStyle === "strip"
    atBottom: Theme.focusStripEdge === "bottom"
    color: root.color

    width: root.windowWidth
    x: root.windowX

    // the item is taller than the bar by the horns, and mirroring puts the bar at
    // whichever end is against the window, so each edge anchors from its own side.
    y: strip.atBottom
      ? root.windowY + root.windowHeight - strip.corner
      : root.windowY - strip.thickness
  }
}
