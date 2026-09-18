import QtQuick
import qs.theme

// one of the three tabs hanging off the top border. the tab is inset by the
// border width on every side it touches, so the border band runs unbroken behind
// it and the tab reads as hanging below the band rather than cutting through it.
Item {
  id: root

  // "left", "center" or "right". the outer two sit flush against the inner edge
  // of the side border; the centre one floats between them.
  property string placement: "center"

  // the tab's contents. one child, which lays itself out and gets measured.
  default property alias content: contentItem.data

  // stage 2 grows the tab downwards into a panel. keeping the extra height in its
  // own animatable property means the fillets, which anchor to the body's bottom,
  // ride down with the panel for free.
  property real expansion: 0

  // and sideways, for a panel wider than its tab. these only move the input
  // region: the panel itself is stage 2's to draw.
  property real panelX: 0
  property real panelWidth: 0

  // the item the window mask points at. it is the tab itself today and the tab
  // plus its open panel in stage 2, so the window never has to restructure its
  // region tree.
  readonly property alias hitArea: hit

  readonly property bool flushLeft: root.placement === "left"
  readonly property bool flushRight: root.placement === "right"

  // the centre tab gets the wide padding variant in the design.
  readonly property int padding: root.placement === "center" ? Theme.notchPaddingWide : Theme.notchPadding

  // rounded up to an even number: the centre tab is positioned by its own half
  // width, and an odd width would park both its edges on a half pixel and soften
  // the fillet seams.
  implicitWidth: Math.ceil((contentItem.implicitWidth + root.padding * 2) / 2) * 2
  implicitHeight: Theme.notchHeight

  Rectangle {
    id: body

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: Theme.notchHeight + root.expansion
    color: Theme.notch

    // a flush tab's outer top corner sits exactly on the corner of the desktop
    // opening, so it takes the same radius and follows it round.
    topLeftRadius: root.flushLeft ? Theme.screenInnerRadius : 0
    topRightRadius: root.flushRight ? Theme.screenInnerRadius : 0
    bottomLeftRadius: root.flushLeft ? 0 : Theme.notchRadius
    bottomRightRadius: root.flushRight ? 0 : Theme.notchRadius

    Behavior on height {
      NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
  }

  Item {
    id: contentItem

    anchors.horizontalCenter: body.horizontalCenter
    anchors.top: body.top
    // pinned inside the notch strip, so expanding the body does not drag the
    // content down with it.
    anchors.topMargin: (Theme.notchHeight - height) / 2

    // the child sits at 0,0 and never anchors back here, so measuring it this way
    // cannot loop.
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    width: implicitWidth
    height: implicitHeight
  }

  // where the tab meets the top band on its left. the flush-left tab has no band
  // to its left, its top-left corner is the opening's corner instead.
  InvertedCorner {
    visible: !root.flushLeft
    corner: "bottomLeft"
    x: -Theme.notchRadius
    y: -Theme.seamBleed
  }

  // and on its right.
  InvertedCorner {
    visible: !root.flushRight
    corner: "bottomRight"
    x: body.width - Theme.seamBleed
    y: -Theme.seamBleed
  }

  // a flush tab also meets the side border underneath itself, where the border
  // resumes its normal width. anchored to the body's bottom so it follows a
  // stage 2 panel down.
  InvertedCorner {
    visible: root.flushLeft || root.flushRight
    corner: root.flushLeft ? "bottomRight" : "bottomLeft"
    x: root.flushLeft ? -Theme.seamBleed : body.width - Theme.notchRadius
    y: body.height - Theme.seamBleed
  }

  Item {
    id: hit

    x: Math.min(0, root.panelX)
    y: 0
    width: Math.max(root.width, root.panelX + root.panelWidth) - x
    height: body.height
  }
}
