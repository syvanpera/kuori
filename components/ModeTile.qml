import QtQuick
import qs.theme

// a glyph in a circle over a label, the whole thing selectable: the design's two
// capture modes. nothing else in the shell stacks an icon over a label, so this
// is its own component rather than a variation on the launcher's chips.
Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property bool selected: false

  signal picked()

  implicitHeight: Theme.capTileTop + circle.height + Theme.capTileInnerGap + caption.implicitHeight + Theme.capTileBottom

  radius: Theme.capTileRadius
  color: root.selected ? Theme.capTileOn : Theme.capTileOff

  Behavior on color {
    ColorAnimation { duration: Theme.notchFadeDuration }
  }

  Rectangle {
    id: circle

    y: Theme.capTileTop
    anchors.horizontalCenter: parent.horizontalCenter

    width: Theme.capTileCircle
    height: Theme.capTileCircle
    radius: width / 2
    color: root.selected ? Theme.accent : Theme.capChipOff

    Behavior on color {
      ColorAnimation { duration: Theme.notchFadeDuration }
    }

    Glyph {
      anchors.centerIn: parent

      icon: root.icon
      size: Theme.capTileIcon

      // dark on the accent when chosen, which is the same reading the launcher's
      // selected row gives its icon.
      iconColor: root.selected ? Theme.litText : Theme.capTileText
    }
  }

  Text {
    id: caption

    y: circle.y + circle.height + Theme.capTileInnerGap
    anchors.horizontalCenter: parent.horizontalCenter

    text: root.label
    color: root.selected ? Theme.text : Theme.capTileText
    font.family: Theme.uiFont
    font.variableAxes: Theme.uiAxesMedium
    font.pixelSize: Theme.capTileLabelSize
  }

  MouseArea {
    anchors.fill: parent

    onClicked: root.picked()
  }
}
