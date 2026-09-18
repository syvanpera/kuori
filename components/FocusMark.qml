import QtQuick
import QtQuick.Shapes
import qs.theme

// the triangle that marks the focused window: a right angle tucked into the
// window's top-right corner, with its two legs running back along the top edge
// and down the right edge.
//
// the item's own top-right corner is the window's top-right corner, and the
// triangle sits inset from it, so whatever places this only has to know where the
// window's corner is.
Shape {
  id: root

  // the geometry renderer flattens at build time and cannot re-tessellate for a
  // fractional device pixel ratio; the curve renderer evaluates in the fragment
  // shader, so the hypotenuse stays clean at eDP-1's 1.6x. same choice, and the
  // same reason, as DesktopFrame.
  preferredRendererType: Shape.CurveRenderer

  // width and height, not implicitWidth and implicitHeight: Shape derives its own
  // implicit size from the path bounding box, which is the triangle alone and
  // leaves out the inset on the top and right. that would put the right angle back
  // on the window edge, which is the one place it must not be.
  width: Theme.focusMarkSize + Theme.focusMarkInset
  height: Theme.focusMarkSize + Theme.focusMarkInset

  // no glow behind it. RectangularShadow only does rectangles, and MultiEffect
  // would allocate a framebuffer for a fourteen pixel triangle -- the trade
  // WorkspaceDots already makes for its dots.
  ShapePath {
    fillColor: Theme.focusMarkColor
    strokeWidth: -1

    // the far end of the top leg. the right angle is one PathLine along from here,
    // pulled in from both edges of the item by the inset.
    startX: 0
    startY: Theme.focusMarkInset

    PathLine {
      x: Theme.focusMarkSize
      y: Theme.focusMarkInset
    }

    PathLine {
      x: Theme.focusMarkSize
      y: Theme.focusMarkSize + Theme.focusMarkInset
    }

    PathLine {
      x: 0
      y: Theme.focusMarkInset
    }
  }
}
