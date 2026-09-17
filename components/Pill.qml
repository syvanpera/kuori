import QtQuick
import qs.theme

Rectangle {
  id: root

  property string icon: ""
  property color iconColor: Theme.text
  property string text: ""

  // Space either side of the text, so the text sits centered.
  property int padding: 10

  implicitWidth: row.width
  implicitHeight: Theme.moduleHeight
  radius: Theme.radius
  color: Theme.pill

  // Shadow {}

  Row {
    id: row
    height: parent.height

    PillIcon {
      icon: root.icon
      iconColor: root.iconColor
    }

    Text {
      width: implicitWidth + root.padding * 2
      height: parent.height
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      text: root.text
      color: Theme.text
      font.family: Theme.font
      font.pixelSize: Theme.textSize
      font.weight: 600
      font.letterSpacing: Theme.letterSpacing
    }
  }
}
