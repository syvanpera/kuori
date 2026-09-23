import QtQuick
import QtQuick.Shapes
import qs.theme

// the border around the entire desktop: one filled path with the desktop punched
// out of it by the odd-even rule, because the hole has to be genuinely
// transparent and a Rectangle can only paint over what is behind it.
//
// the outer rectangle is square. the mockup rounds it, but that only makes sense
// for a screen floating on a web page: a physical panel's corners are already
// square and rounding them here would just reveal wallpaper in each corner.
Shape {
  id: root

  // the geometry renderer flattens arcs at build time and cannot re-tessellate for
  // a fractional device pixel ratio; the curve renderer evaluates them in the
  // fragment shader, so the opening stays smooth at whatever scale a monitor runs
  // at.
  preferredRendererType: Shape.CurveRenderer

  ShapePath {
    fillColor: Theme.frame
    strokeWidth: -1
    fillRule: ShapePath.OddEvenFill

    PathRectangle {
      width: root.width
      height: root.height
    }

    PathRectangle {
      x: Theme.borderWidth
      y: Theme.borderWidth
      width: root.width - Theme.borderWidth * 2
      height: root.height - Theme.borderWidth * 2
      radius: Theme.screenInnerRadius
    }
  }
}
