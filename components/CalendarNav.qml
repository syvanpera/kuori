import QtQuick
import qs.theme

// one of the two arrows that page the calendar's month.
Rectangle {
  id: root

  property string icon: ""

  signal clicked()

  width: Theme.calNavSize
  height: Theme.calNavSize
  radius: Theme.calNavRadius
  color: hover.hovered ? Theme.launcherRaise : "transparent"

  Behavior on color {
    ColorAnimation { duration: 150 }
  }

  Glyph {
    anchors.centerIn: parent

    icon: root.icon
    iconColor: Theme.calNavText
    size: Theme.calNavIcon
  }

  HoverHandler {
    id: hover
  }

  TapHandler {
    onTapped: root.clicked()
  }
}
