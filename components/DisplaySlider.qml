import QtQuick
import qs.theme

// a glyph, a slider and a reading: the row the design uses for both brightness and
// colour temperature. the old brightness row was this shape before the design
// folded it into the display section.
Item {
  id: root

  property string icon: ""
  property real value: 0
  property string reading: ""
  property color tint: Theme.accent
  property int labelWidth: Theme.sysSliderLabelWidth

  signal moved(real value)

  implicitHeight: Math.max(Theme.dispToggleIcon, bar.implicitHeight, label.implicitHeight)

  Glyph {
    id: glyph

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter

    icon: root.icon
    size: Theme.dispToggleIcon
    iconColor: Theme.sysBrightGlyph
  }

  Slider {
    id: bar

    anchors.left: glyph.right
    anchors.leftMargin: Theme.sysSliderGap
    anchors.right: label.left
    anchors.rightMargin: Theme.sysSliderGap
    anchors.verticalCenter: parent.verticalCenter

    value: root.value
    tint: root.tint

    onMoved: level => root.moved(level)
  }

  Text {
    id: label

    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: root.labelWidth

    text: root.reading
    color: Theme.sysSliderText
    font.family: Theme.monoFont
    font.pixelSize: Theme.sysSliderLabelSize
    font.weight: Font.Medium
    horizontalAlignment: Text.AlignRight
  }
}
