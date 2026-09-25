import QtQuick
import qs.theme

// a glyph on a square that lightens under the pointer: PillButton's shape for a
// button with no words. each caller hands it its own tokens, as with PillButton.
Rectangle {
  id: root

  property string icon: ""
  property color iconColor: Theme.glyph
  property int iconSize: Theme.iconSize

  property color fill: "transparent"
  property color hoverFill: root.fill

  readonly property bool hovered: mouse.containsMouse

  signal clicked()

  color: root.hovered ? root.hoverFill : root.fill

  Behavior on color {
    ColorAnimation { duration: Theme.notchFadeDuration }
  }

  Glyph {
    anchors.centerIn: parent

    icon: root.icon
    iconColor: root.iconColor
    size: root.iconSize
  }

  // a MouseArea, as everywhere clickable here: a TapHandler's exclusive grab
  // cancels the hover an open tab may be holding itself open with.
  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true

    onClicked: root.clicked()
  }
}
