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

  Column {
    width: root.width
    spacing: Theme.sysNetSpacing

    Repeater {
      model: root.model
      delegate: root.delegate
    }
  }
}
