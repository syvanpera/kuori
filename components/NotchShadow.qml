import QtQuick
import QtQuick.Effects
import qs.theme

// the drop shadow under one notch, in the two layers the design writes it as: a
// soft ambient spread and a tight contact line right under the edge.
//
// it lives beside the notch rather than inside it, and whatever places it draws
// it before the frame, so the border band covers everything above the notch and
// only the part falling on the desktop is ever seen. that is the whole reason the
// band stays one flat colour.
//
// RectangularShadow is an Item with one ShaderEffect child: one quad, drawn
// straight into the scene graph with no framebuffer and no layer, which is what
// makes two of these per notch cost nothing worth measuring. MultiEffect would
// have texturised the notch and built a downsample pyramid per instance -- the
// same trade FocusMark and WorkspaceDots already refuse.
Item {
  id: root

  required property Item notch

  // the silhouette to match. a tab works these out from which border it is flush
  // with; anything else that hangs off the band -- the osd -- says what it is.
  property real topLeftRadius: root.notch.flushLeft ? Theme.screenInnerRadius : 0
  property real topRightRadius: root.notch.flushRight ? Theme.screenInnerRadius : 0
  // and square along the bottom while something hangs below it, as the body is.
  readonly property bool hanging: (root.notch.hangHeight ?? 0) > 0

  property real bottomLeftRadius: root.notch.flushLeft || root.hanging ? 0 : Theme.notchRadius
  property real bottomRightRadius: root.notch.flushRight || root.hanging ? 0 : Theme.notchRadius

  // the shadow is cast by the notch's body, so it tracks the body's box rather
  // than the notch item, which is taller than the body once a panel opens.
  x: root.notch.x
  y: root.notch.y
  width: root.notch.width
  height: root.notch.bodyHeight

  // each layer paints up to blur plus spread past these bounds on every side,
  // which is fine: nothing here clips, and the band is drawn over the top
  // afterwards, so the extra reach is only ever seen below and beside the tab.
  RectangularShadow {
    anchors.fill: parent

    blur: Theme.notchShadowAmbientBlur
    spread: Theme.notchShadowAmbientSpread
    offset.y: Theme.notchShadowAmbientOffset
    color: Theme.notchShadowAmbient

    // mirrors the body's corners exactly. naming all four picks qt's per-corner
    // shader over its single-radius one, which is a slightly heavier fragment
    // shader on a quad this small and buys a silhouette that matches at the
    // bottom corners, where a flush tab is square against the side border.
    topLeftRadius: root.topLeftRadius
    topRightRadius: root.topRightRadius
    bottomLeftRadius: root.bottomLeftRadius
    bottomRightRadius: root.bottomRightRadius
  }

  RectangularShadow {
    anchors.fill: parent

    blur: Theme.notchShadowContactBlur
    spread: Theme.notchShadowContactSpread
    offset.y: Theme.notchShadowContactOffset
    color: Theme.notchShadowContact

    topLeftRadius: root.topLeftRadius
    topRightRadius: root.topRightRadius
    bottomLeftRadius: root.bottomLeftRadius
    bottomRightRadius: root.bottomRightRadius
  }
}
