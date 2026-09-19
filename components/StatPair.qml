import QtQuick
import qs.theme

// one reading in a folded-open row's grid: its name on the left, its value hard
// against the right. the caller sets the width, because the grid divides the
// panel rather than the readings deciding how wide it is.
Item {
  id: root

  property string key: ""
  property string value: ""

  implicitHeight: Theme.lineBox(Theme.sysStatSize)

  Text {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter

    text: root.key
    color: Theme.sysStatKey
    font.family: Theme.monoFont
    font.pixelSize: Theme.sysStatSize
  }

  Text {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter

    text: root.value
    color: Theme.sysStatValue
    font.family: Theme.monoFont
    font.pixelSize: Theme.sysStatSize
    font.weight: Font.Medium
  }
}
