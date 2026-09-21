import QtQuick
import qs.theme

// a label and a switch, with nothing else on the line: the shape the design gives
// the two recording options. DisplayToggle is the same idea with an icon and a
// second line, which these do not have.
Item {
  id: root

  property string label: ""
  property bool checked: false

  signal toggled()

  implicitHeight: Math.max(caption.implicitHeight, control.height)

  Text {
    id: caption

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter

    text: root.label
    color: Theme.capSwitchLabel
    font.family: Theme.uiFont
    font.pixelSize: Theme.capSwitchLabelSize
    font.weight: Font.Medium
  }

  Switch {
    id: control

    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter

    checked: root.checked

    onToggled: root.toggled()
  }
}
