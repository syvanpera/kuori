import QtQuick
import qs.theme

// one Material Symbols glyph in a fixed square box. the box is fixed rather than
// sized to the text because changing FILL shifts a glyph's advance width, which
// would make a row of icons twitch whenever one of them toggles.
Item {
  id: root

  property string icon: ""
  property color iconColor: Theme.glyph
  property bool filled: false
  property int size: Theme.iconSize

  // the symbol font hangs its glyphs slightly below the middle of the line box,
  // so centre the box and then lift the text by hand rather than trusting
  // verticalAlignment.
  property real nudge: -0.5

  implicitWidth: root.size
  implicitHeight: root.size

  Text {
    anchors.centerIn: parent
    anchors.verticalCenterOffset: root.nudge

    text: root.icon
    color: root.iconColor
    font.family: Theme.iconFont
    font.pixelSize: root.size
    // FILL is a real axis on this font, not a second family, so a filled glyph
    // costs nothing but a different axis map.
    font.variableAxes: root.filled ? Theme.iconAxesFilled : Theme.iconAxes

    Behavior on color {
      ColorAnimation { duration: 150 }
    }
  }
}
