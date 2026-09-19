import QtQuick
import qs.theme

// one of the tabs hanging off the top border. the tab is inset by the border
// width on every side it touches, so the border band runs unbroken behind it and
// the tab reads as hanging below the band rather than cutting through it.
//
// hovering a tab that has a panel collapses its strip and grows the same box into
// the panel's place. the design draws those as two stacked boxes, one of them
// zero height at any moment; one box that changes size is the same picture, and
// it keeps the fillets and the drop shadow following the silhouette for free.
Item {
  id: root

  // "left", "center" or "right". the outer two sit flush against the inner edge of
  // the side border; the centre one floats between them.
  property string placement: "center"

  // the strip's contents. one child, which lays itself out and gets measured.
  default property alias content: contentItem.data

  // what the tab becomes while hovered. a tab without one never opens.
  property Component panel: null

  readonly property bool open: hover.hovered && root.panel !== null

  // the item the window mask points at. it tracks the body, so the input region
  // grows with the panel and the pointer never falls out of the region that is
  // keeping the panel open.
  readonly property alias hitArea: hit

  // the silhouette the drop shadow has to match.
  readonly property alias bodyHeight: body.height

  readonly property bool flushLeft: root.placement === "left"
  readonly property bool flushRight: root.placement === "right"

  // the centre tab gets the wide padding variant in the design.
  readonly property int padding: root.placement === "center" ? Theme.notchPaddingWide : Theme.notchPadding

  // the collapsed width, rounded up to an even number: the centre tab is
  // positioned by its own half width, and an odd width would park both its edges
  // on a half pixel and soften the fillet seams.
  readonly property real stripWidth: Math.ceil((contentItem.implicitWidth + root.padding * 2) / 2) * 2

  // the item tracks the body rather than the strip, for two reasons. qt prunes
  // input delivery by the parent's bounds, so a hover handler on a body wider than
  // its item would go dead over the panel; and whatever places a tab anchors it by
  // an edge, so growing the item is what keeps a right hand tab's right edge and a
  // centre tab's centre where they were.
  implicitWidth: body.width
  implicitHeight: body.height

  Rectangle {
    id: body

    width: root.open ? Math.max(root.stripWidth, panelLoader.implicitWidth) : root.stripWidth
    height: root.open ? Math.max(Theme.notchHeight, panelLoader.implicitHeight) : Theme.notchHeight
    color: Theme.notch

    // a flush tab's outer top corner sits exactly on the corner of the desktop
    // opening, so it takes the same radius and follows it round.
    topLeftRadius: root.flushLeft ? Theme.screenInnerRadius : 0
    topRightRadius: root.flushRight ? Theme.screenInnerRadius : 0
    bottomLeftRadius: root.flushLeft ? 0 : Theme.notchRadius
    bottomRightRadius: root.flushRight ? 0 : Theme.notchRadius

    Behavior on width {
      NumberAnimation {
        duration: Theme.notchExpandDuration
        easing.type: Easing.Bezier
        easing.bezierCurve: Theme.easeStandard
      }
    }

    Behavior on height {
      NumberAnimation {
        duration: Theme.notchExpandDuration
        easing.type: Easing.Bezier
        easing.bezierCurve: Theme.easeStandard
      }
    }

    HoverHandler {
      id: hover
    }
  }

  Item {
    id: contentItem

    anchors.horizontalCenter: body.horizontalCenter
    anchors.top: body.top

    // pinned inside the strip, so the body growing under it does not drag it down.
    anchors.topMargin: (Theme.notchHeight - height) / 2

    // the child sits at 0,0 and never anchors back here, so measuring it this way
    // cannot loop.
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    width: implicitWidth
    height: implicitHeight

    opacity: root.open ? 0 : 1

    // an invisible strip must not keep answering clicks meant for the panel.
    enabled: !root.open

    Behavior on opacity {
      NumberAnimation { duration: Theme.notchFadeDuration }
    }
  }

  Loader {
    id: panelLoader

    // loaded even while closed: its implicit size is what the body grows to, and
    // measuring it on the first hover would mean animating from a size nobody knew
    // one frame earlier.
    active: root.panel !== null
    sourceComponent: root.panel

    anchors.horizontalCenter: body.horizontalCenter
    anchors.top: body.top

    opacity: root.open ? 1 : 0
    enabled: root.open

    Behavior on opacity {
      NumberAnimation { duration: Theme.notchFadeDuration }
    }
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
  // resumes its normal width. anchored to the body's bottom so it rides down with
  // an open panel.
  InvertedCorner {
    visible: root.flushLeft || root.flushRight
    corner: root.flushLeft ? "bottomRight" : "bottomLeft"
    x: root.flushLeft ? -Theme.seamBleed : body.width - Theme.notchRadius
    y: body.height - Theme.seamBleed
  }

  Item {
    id: hit

    width: body.width
    height: body.height
  }
}
