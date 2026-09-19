import QtQuick
import QtQuick.Shapes
import qs.theme

// the strip that marks the focused window: a bar the width of the window sitting
// on one of its horizontal edges, with a horn at each end that fills the wedge
// hyprland's corner rounding leaves behind. without them the bar floats over the
// corners instead of reading as part of the window.
//
// one path rather than a bar plus two corner pieces, because the colour is
// translucent: anywhere two separate items overlapped would blend twice and draw
// a seam brighter than the rest of the shape.
Shape {
  id: root

  property real thickness: Theme.focusStripThickness

  // against the window's bottom edge instead of its top.
  property bool atBottom: false

  // the radius hyprland rounds the window by, clamped so two horns can never meet
  // in the middle of a narrow window and fold the outline back over itself.
  readonly property real corner: Math.min(Theme.windowRadius, root.width / 2)

  // the bar's outer corners, matched to the window's own radius rather than to the
  // bar. half the thickness is round in the arithmetic and square to the eye: the
  // horn makes the outer edge four times taller than the bar, so a radius scaled to
  // the bar disappears against it. at the window's radius the curve runs out of the
  // strip and into the window's corner as one line.
  readonly property real endRadius: root.corner

  // width and height, not their implicit versions: Shape derives its own implicit
  // size from the path's bounding box and would overwrite them. whatever places
  // this sets the width from the window.
  height: root.thickness + root.corner

  // the geometry renderer flattens arcs at build time and cannot re-tessellate for
  // a fractional device pixel ratio; the curve renderer evaluates them in the
  // fragment shader, so the corners stay smooth at eDP-1's 1.6x.
  preferredRendererType: Shape.CurveRenderer

  // the bottom variant is the top one flipped. mirroring beats writing the path
  // twice: the two can never drift apart, and the horns go on hugging whichever
  // pair of the window's corners they are put against.
  //
  // both origins are set even though only the vertical one is used: a Scale with
  // origin.x left at its default renders this shape as nothing at all, identity
  // scale or not.
  transform: Scale {
    origin.x: root.width / 2
    origin.y: root.height / 2
    yScale: root.atBottom ? -1 : 1
  }

  ShapePath {
    fillColor: Theme.focusColor
    strokeWidth: -1

    // just past the bar's rounded outer corner.
    startX: root.endRadius
    startY: 0

    PathLine { x: root.width - root.endRadius; y: 0 }

    // the bar's far outer corner.
    PathArc {
      x: root.width
      y: root.endRadius
      radiusX: root.endRadius
      radiusY: root.endRadius
      direction: PathArc.Clockwise
    }

    // down the far side of that horn.
    PathLine { x: root.width; y: root.thickness + root.corner }

    // back up around the window's corner, riding the same curve the window does so
    // the two outlines coincide.
    PathArc {
      x: root.width - root.corner
      y: root.thickness
      radiusX: root.corner
      radiusY: root.corner
      direction: PathArc.Counterclockwise
    }

    // across the window's flat edge, under the bar.
    PathLine { x: root.corner; y: root.thickness }

    // around the other corner the same way,
    PathArc {
      x: 0
      y: root.thickness + root.corner
      radiusX: root.corner
      radiusY: root.corner
      direction: PathArc.Counterclockwise
    }

    // and back up to close on the bar's near outer corner.
    PathLine { x: 0; y: root.endRadius }

    PathArc {
      x: root.endRadius
      y: 0
      radiusX: root.endRadius
      radiusY: root.endRadius
      direction: PathArc.Clockwise
    }
  }
}
