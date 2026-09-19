import QtQuick
import qs.theme

// one of the network row's two lists: a rule, a heading and the entries. the
// whole thing goes away when it has nothing in it, rather than leaving a heading
// standing over a gap -- which is what happens with the radio off, or in the
// first second after it comes back on and the scan has not returned.
Column {
  id: root

  property string heading: ""
  property var networks: []
  property bool stranger: false

  visible: root.networks.length > 0
  spacing: Theme.sysBodyGap

  Rectangle {
    width: root.width
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
      model: root.networks

      NetworkEntry {
        required property var modelData

        width: root.width
        network: modelData
        stranger: root.stranger
      }
    }
  }
}
