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
  color: mouse.containsMouse ? Theme.launcherRaise : "transparent"

  Behavior on color {
    ColorAnimation { duration: 150 }
  }

  Glyph {
    anchors.centerIn: parent

    icon: root.icon
    iconColor: Theme.calNavText
    size: Theme.calNavIcon
  }

  // a MouseArea rather than Tap and Hover handlers: a TapHandler takes an
  // exclusive grab when it fires, which cancels the hover the tab is holding
  // itself open with, so paging the month folded the whole panel away instead.
  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true

    onClicked: root.clicked()
  }
}
