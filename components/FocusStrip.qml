import QtQuick
import QtQuick.Shapes
import qs.theme

// the strip that marks the focused window: a bar the width of the window sitting
// on its top edge, with a horn at each end that fills the wedge hyprland's corner
// rounding leaves behind. without them the bar floats over the corners instead of
// reading as part of the window.
//
// one path rather than a bar plus two corner pieces, because the colour is
// translucent: anywhere two separate items overlapped would blend twice and draw
// a seam brighter than the rest of the shape.
Shape {
  id: root

  property real thickness: Theme.focusStripThickness

  // the radius hyprland rounds the window by, clamped so two horns can never meet
  // in the middle of a narrow window and fold the outline back over itself.
  readonly property real corner: Math.min(Theme.windowRadius, root.width / 2)

  // width and height, not their implicit versions: Shape derives its own implicit
  // size from the path's bounding box and would overwrite them. whatever places
  // this sets the width from the window.
  height: root.thickness + root.corner

  // the geometry renderer flattens arcs at build time and cannot re-tessellate for
  // a fractional device pixel ratio; the curve renderer evaluates them in the
  // fragment shader, so the horns stay smooth at eDP-1's 1.6x.
  preferredRendererType: Shape.CurveRenderer

  ShapePath {
    fillColor: Theme.focusColor
    strokeWidth: -1

    // the top-left of the bar.
    startX: 0
    startY: 0

    // along the top of the bar and down the far side of the right horn.
    PathLine { x: root.width; y: 0 }
    PathLine { x: root.width; y: root.thickness + root.corner }

    // back up around the window's top-right corner, riding the same curve the
    // window does so the two outlines coincide.
    PathArc {
      x: root.width - root.corner
      y: root.thickness
      radiusX: root.corner
      radiusY: root.corner
      direction: PathArc.Counterclockwise
    }

    // across the window's flat top edge, under the bar.
    PathLine { x: root.corner; y: root.thickness }

    // and around the top-left corner the same way.
    PathArc {
      x: 0
      y: root.thickness + root.corner
      radiusX: root.corner
      radiusY: root.corner
      direction: PathArc.Counterclockwise
    }

    PathLine { x: 0; y: 0 }
  }
}
