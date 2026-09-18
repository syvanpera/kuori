import QtQuick
import qs.theme

// one of the launcher's category pills.
Rectangle {
  id: root

  property string label: ""
  property bool selected: false

  signal clicked()

  implicitWidth: text.implicitWidth + Theme.launcherChipPaddingH * 2
  implicitHeight: Theme.lineBox(Theme.launcherChipSize) + Theme.launcherChipPaddingV * 2

  radius: Theme.launcherChipRadius
  color: root.selected ? Theme.launcherChipActive : Theme.launcherSunken

  Behavior on color {
    ColorAnimation { duration: 150 }
  }

  Text {
    id: text

    anchors.centerIn: parent

    text: root.label
    color: root.selected ? Theme.tintBright : Theme.launcherChipText
    font.family: Theme.monoFont
    font.pixelSize: Theme.launcherChipSize
    font.weight: Font.Medium
    font.letterSpacing: Theme.launcherChipLetterSpacing

    Behavior on color {
      ColorAnimation { duration: 150 }
    }
  }

  MouseArea {
    anchors.fill: parent

    onClicked: root.clicked()
  }
}
