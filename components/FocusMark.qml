import QtQuick
import QtQuick.Shapes
import qs.theme

// the wedge that marks the focused window: it fills the window's top-right corner
// out to both edges, with its own corner rounded by the same radius hyprland
// rounds the window by, so the two outlines coincide and no strip of window shows
// between the mark and the edges it sits against.
//
// the item is exactly the corner it fills, so whatever places this only has to
// line its top-right up with the window's.
Shape {
  id: root

  // the geometry renderer flattens arcs at build time and cannot re-tessellate for
  // a fractional device pixel ratio; the curve renderer evaluates them in the
  // fragment shader, so the corner stays smooth at whatever scale a monitor runs
  // at. same choice, and the same reason, as DesktopFrame.
  preferredRendererType: Shape.CurveRenderer

  // width and height, not implicitWidth and implicitHeight: Shape derives its own
  // implicit size from the path bounding box and would overwrite these.
  width: Theme.focusMarkSize
  height: Theme.focusMarkSize

  // no glow behind it. RectangularShadow only does rectangles, and MultiEffect
  // would allocate a framebuffer for a mark this size -- the trade WorkspaceDots
  // already makes for its dots.
  ShapePath {
    fillColor: Theme.focusColor
    strokeWidth: -1

    // the inner end of the top edge, where the hypotenuse meets it.
    startX: 0
    startY: 0

    // out along the top edge, stopping where the window's corner starts to turn.
    PathLine {
      x: Theme.focusMarkSize - Theme.windowRadius
      y: 0
    }

    // the corner itself, riding the window's own curve round onto the right edge.
    PathArc {
      x: Theme.focusMarkSize
      y: Theme.windowRadius
      radiusX: Theme.windowRadius
      radiusY: Theme.windowRadius
      direction: PathArc.Clockwise
    }

    // back down the right edge to the bottom of the wedge,
    PathLine {
      x: Theme.focusMarkSize
      y: Theme.focusMarkSize
    }

    // and the hypotenuse home.
    PathLine {
      x: 0
      y: 0
    }
  }
}
