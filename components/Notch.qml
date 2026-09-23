import QtQuick
import qs.services
import qs.theme

// one of the tabs hanging off the top border. the tab is inset by the border
// width on every side it touches, so the border band runs unbroken behind it and
// the tab reads as hanging below the band rather than cutting through it.
//
// a tab with a panel grows the same box into the panel's place. the design draws
// those as two stacked boxes, one of them zero height at any moment; one box that
// changes size is the same picture, and it keeps the fillets and the drop shadow
// following the silhouette for free.
Item {
  id: root

  // "left", "center" or "right". the outer two sit flush against the inner edge of
  // the side border; the centre one floats between them.
  property string placement: "center"

  // how this tab's panel opens. hovering is right for a panel you only read; a
  // panel with something to click has to latch, because a press that lands over a
  // window hands focus to that window and the pointer leave that follows would
  // fold a hover-held panel away before the click finished.
  property string trigger: "hover"

  // identifies this tab in the shared open state.
  property string notchId: ""

  // the screen this tab is on, by name. every screen has a copy of every tab, and
  // only one of them is the one that was opened.
  property string screenName: ""

  // the strip's contents. one child, which lays itself out and gets measured.
  default property alias content: contentItem.data

  // what the tab becomes while open. a tab without one never opens.
  property Component panel: null

  // how much of something else is hanging below this tab -- the osd, under the
  // system tab. the tab does not draw it, but it is part of the same silhouette:
  // the corner between them squares off and the fillet where the tab meets the side
  // border moves to the bottom of whatever hangs.
  property real hangHeight: 0

  // whether the strip stays put when the panel opens. the workspaces and clock
  // tabs fold into their panels; the system tab keeps its row of glyphs and hangs
  // the panel underneath, so the things it is reporting never leave the screen.
  property bool keepStrip: false

  readonly property bool hovered: hover.hovered

  readonly property bool open: {
    if (!root.panel) return false
    if (root.trigger === "click") return Notches.openOn(root.screenName) === root.notchId

    // a hovering tab stays shut while another tab is being read, so brushing past
    // it cannot yank a panel out from under the pointer.
    return root.hovered && Notches.openOn(root.screenName) === ""
  }

  // the item the window mask points at. it tracks the body, so the input region
  // grows with the panel and the pointer never falls out of the region that is
  // keeping the panel open.
  readonly property alias hitArea: hit

  // the silhouette the drop shadow has to match.
  readonly property alias bodyHeight: body.height

  readonly property bool flushLeft: root.placement === "left"
  readonly property bool flushRight: root.placement === "right"

  // the clock gets the wide padding variant in the design. it is a property rather
  // than a rule because the toggles tab is centre-placed and padded like the others.
  property int padding: root.placement === "center" ? Theme.notchPaddingWide : Theme.notchPadding

  // a tab that steps aside. the toggles tab gets out of the way while the system
  // panel is open or the osd is out: both of those grow over the space it occupies,
  // and a tab hidden under one would still be answering clicks through it, which is
  // why the hit area goes with the picture.
  property bool aside: false

  // the collapsed width, rounded up to an even number: the centre tab is
  // positioned by its own half width, and an odd width would park both its edges
  // on a half pixel and soften the fillet seams.
  readonly property real stripWidth: Math.ceil((contentItem.implicitWidth + root.padding * 2) / 2) * 2

  // the collapsed height follows the strip's contents, so a tab whose content
  // grows -- the clock peeking its date -- grows with it.
  readonly property real stripHeight: Math.max(Theme.notchHeight, contentItem.implicitHeight + Theme.notchStripPadding * 2)

  // the item tracks the body rather than the strip, for two reasons. qt prunes
  // input delivery by the parent's bounds, so a hover handler on a body wider than
  // its item would go dead over the panel; and whatever places a tab anchors it by
  // an edge, so growing the item is what keeps a right hand tab's right edge and a
  // centre tab's centre where they were.
  implicitWidth: body.width
  implicitHeight: body.height

  opacity: root.aside ? 0 : 1
  visible: root.opacity > 0

  Behavior on opacity {
    NumberAnimation { duration: Theme.notchFadeDuration }
  }

  Rectangle {
    id: body

    width: root.open ? Math.max(root.stripWidth, panelLoader.implicitWidth) : root.stripWidth
    height: {
      if (!root.open) return root.stripHeight
      // a kept strip is above the panel rather than behind it, so the two stack.
      if (root.keepStrip) return root.stripHeight + panelLoader.implicitHeight
      return Math.max(root.stripHeight, panelLoader.implicitHeight)
    }
    color: Theme.notch

    // a flush tab's outer top corner sits exactly on the corner of the desktop
    // opening, so it takes the same radius and follows it round.
    topLeftRadius: root.flushLeft ? Theme.screenInnerRadius : 0
    topRightRadius: root.flushRight ? Theme.screenInnerRadius : 0
    // square against whatever hangs below, the way it is square against the side
    // border it is flush with.
    bottomLeftRadius: root.flushLeft || root.hangHeight > 0 ? 0 : Theme.notchRadius
    bottomRightRadius: root.flushRight || root.hangHeight > 0 ? 0 : Theme.notchRadius

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

    // above the strip's own toggle below, which is declared after this and would
    // otherwise take every click first -- among siblings at the same z, qt delivers
    // to the later one. the strip's glyphs answer clicks of their own, and only the
    // gaps between them should reach the toggle.
    z: 1

    // a flush tab keeps its contents against its own outer edge, so a body that
    // grows inward leaves them where they were. while the body is only as wide as
    // the strip this is exactly where centring put them.
    x: {
      if (root.flushRight) return body.width - contentItem.width - root.padding
      if (root.flushLeft) return root.padding
      return (body.width - contentItem.width) / 2
    }

    // centred in the strip, so the body growing under it does not drag it down.
    y: (root.stripHeight - contentItem.height) / 2

    // the child sits at 0,0 and never anchors back here, so measuring it this way
    // cannot loop.
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    width: implicitWidth
    height: implicitHeight

    opacity: root.open && !root.keepStrip ? 0 : 1

    // an invisible strip must not keep answering clicks meant for the panel.
    enabled: !root.open || root.keepStrip

    Behavior on opacity {
      NumberAnimation { duration: Theme.notchFadeDuration }
    }
  }

  Loader {
    id: panelLoader

    // loaded even while closed: its implicit size is what the body grows to, and
    // measuring it on the first click would mean animating from a size nothing
    // knew a frame earlier.
    active: root.panel !== null
    sourceComponent: root.panel

    anchors.horizontalCenter: body.horizontalCenter
    y: root.keepStrip ? root.stripHeight : 0

    opacity: root.open ? 1 : 0
    enabled: root.open

    Behavior on opacity {
      NumberAnimation { duration: Theme.notchFadeDuration }
    }
  }

  // the strip is what toggles a click-opened panel, open or shut. while the panel
  // is out this sits over its first row, which for the clock is the big time: a
  // second click on the time closes what a click on the time opened.
  MouseArea {
    anchors.left: body.left
    anchors.right: body.right
    anchors.top: body.top
    height: root.stripHeight

    enabled: root.trigger === "click" && root.panel !== null
    visible: enabled

    onClicked: Notches.toggle(root.notchId, root.screenName)
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
  // an open panel, and past whatever hangs below it.
  InvertedCorner {
    visible: root.flushLeft || root.flushRight
    corner: root.flushLeft ? "bottomRight" : "bottomLeft"
    x: root.flushLeft ? -Theme.seamBleed : body.width - Theme.notchRadius
    y: body.height + root.hangHeight - Theme.seamBleed
  }

  // and where the tab meets something wider hanging below it: an inside corner in
  // the tab's own colour, so the osd looks moulded onto the strip rather than
  // stepped out from under it. it is on the open side -- a right hand tab grows its
  // osd leftwards.
  InvertedCorner {
    visible: root.hangHeight > 0
    corner: root.flushRight ? "topLeft" : "topRight"
    fill: Theme.notch
    x: root.flushRight ? -Theme.notchRadius : body.width - Theme.seamBleed
    y: body.height - Theme.notchRadius
  }

  Item {
    id: hit

    // nothing while the tab is aside: the window's input region is a wayland
    // property and knows nothing about opacity, so a faded tab left in the region
    // would go on swallowing clicks meant for the desktop under it.
    width: root.aside ? 0 : body.width
    height: root.aside ? 0 : body.height
  }
}
