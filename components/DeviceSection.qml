import QtQuick
import qs.theme

// a captioned list inside a folded-open row: an optional rule, a heading, and
// whatever the caller stacks under it. the whole thing goes away when it has
// nothing in it, rather than leaving a heading standing over a gap.
Column {
  id: root

  property string heading: ""
  property var model: []
  property Component delegate: null

  // whether the section is ruled off from what is above it. the first section in a
  // row sits directly under the switch and needs no line.
  property bool ruled: true

  // a section whose heading still means something with nothing listed under it --
  // audio's OUTPUT, which carries the level slider -- stays when it is empty.
  property bool hideEmpty: true

  // anything that belongs between the heading and the list, such as that slider.
  default property alias lead: lead.data

  visible: !root.hideEmpty || root.model.length > 0
  spacing: Theme.sysBodyGap

  Rule {
    width: root.width
    visible: root.ruled
  }

  Caption {
    text: root.heading
  }

  Column {
    id: lead

    width: root.width
    visible: lead.children.length > 0
  }

  // a Flickable round a Column rather than a ListView: the panel's keyboard walks
  // children in order, and a ListView builds only the entries on show, in whatever
  // order it built them. the lists are tens of entries, which a Column can afford.
  Flickable {
    id: scroller

    // down to the half of the entry after the last one on show, or the whole list.
    readonly property real cap: {
      const shown = Array.from(list.children).filter(child => child.visible && child.height > 0)
      const rows = Theme.sysListRows
      if (rows <= 0 || shown.length <= rows) return list.implicitHeight

      const peek = shown[rows]
      return peek.y + peek.height / 2
    }

    width: root.width
    height: Math.min(list.implicitHeight, scroller.cap)
    contentWidth: scroller.width
    contentHeight: list.implicitHeight

    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // a list that fits is not a scroller, and leaves the wheel to what is under it.
    interactive: scroller.contentHeight > scroller.height

    Column {
      id: list

      width: scroller.width
      spacing: Theme.sysNetSpacing

      Repeater {
        model: root.model
        delegate: root.delegate
      }
    }
  }
}
