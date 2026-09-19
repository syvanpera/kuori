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

  visible: root.model.length > 0
  spacing: Theme.sysBodyGap

  Rectangle {
    width: root.width
    visible: root.ruled
    height: 1
    color: Theme.sysLine
  }

  Text {
    text: root.heading
    color: Theme.sysCap
    font.family: Theme.monoFont
    font.pixelSize: Theme.sysCapSize
    font.weight: Font.Medium
    font.letterSpacing: Theme.sysCapSpacing
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
