import QtQuick
import qs.theme

// a keycap and what it does, the way the launcher's footer and the clipboard
// preview both teach their shortcuts: `ENTER launch`.
Row {
  id: root

  property string key: ""
  property string label: ""

  property color textColor: Theme.launcherDimText
  property real textSize: Theme.launcherFooterSize

  spacing: Theme.launcherFooterSpacing

  KeyCap {
    anchors.verticalCenter: parent.verticalCenter

    label: root.key
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter

    text: root.label
    color: root.textColor
    font.family: Theme.monoFont
    font.pixelSize: root.textSize
  }
}
