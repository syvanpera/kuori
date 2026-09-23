import QtQuick
import QtQuick.Shapes
import qs.theme

// a square of frame colour with a quarter circle bitten out of one corner, so a
// notch looks moulded out of the border instead of glued against it. this is the
// mockup's `radial-gradient(circle at <corner>, transparent r, frame r)`.
//
// a Rectangle cannot do this: the bite has to be genuinely transparent so the
// desktop shows through, and a Rectangle can only add colour, never subtract it.
Shape {
  id: root

  // "bottomRight", "bottomLeft", "topRight" or "topLeft" - which corner the bite
  // is taken out of. authored once for bottomRight and mirrored into the rest,
  // so the orientations cannot drift apart when the radius changes.
  property string corner: "bottomRight"
  property real radius: Theme.notchRadius
  property color fill: Theme.frame

  // the two straight sides butt into the border and the notch body, which are
  // rasterised separately. bleeding them half a pixel past the seam hides the
  // hairline of transparent panel their antialiased edges would otherwise leave.
  property real bleed: Theme.seamBleed

  // set explicitly: QQuickShape derives its own implicit size from its contents,
  // which competes with an implicitWidth binding and leaves the path drawing
  // into a box that is not the size it thinks it is.
  width: root.radius + root.bleed
  height: root.radius + root.bleed

  // the geometry renderer flattens arcs at build time and cannot re-tessellate for
  // a fractional device pixel ratio; the curve renderer evaluates the curve in the
  // fragment shader, so the bite stays smooth at whatever scale a monitor runs at.
  preferredRendererType: Shape.CurveRenderer

  transform: Scale {
    origin.x: root.width / 2
    origin.y: root.height / 2
    xScale: root.corner.endsWith("Left") ? -1 : 1
    yScale: root.corner.startsWith("top") ? -1 : 1
  }

  ShapePath {
    fillColor: root.fill
    strokeWidth: -1

    startX: 0
    startY: 0

    PathLine { x: root.width; y: 0 }
    PathLine { x: root.width; y: root.bleed }

    // centred on the bitten corner, swept from 12 o'clock round to 9. moveToStart
    // defaults to true, which would break the outline into two subpaths and fill
    // the square solid.
    PathAngleArc {
      moveToStart: false
      centerX: root.width
      centerY: root.height
      radiusX: root.radius
      radiusY: root.radius
      startAngle: -90
      sweepAngle: -90
    }

    PathLine { x: 0; y: root.height }
    PathLine { x: 0; y: 0 }
  }
}
