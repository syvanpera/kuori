import QtQuick
import qs.theme

// a glyph, a slider and a reading: the row the design uses for brightness and
// colour temperature. the audio levels are the same row with no glyph, which is
// what an empty icon asks for.
Item {
  id: root

  property string icon: ""
  property real value: 0
  property string reading: ""
  property color tint: Theme.accent
  property int labelWidth: Theme.sysSliderLabelWidth

  signal moved(real value)

  // without a glyph the design sizes the row by the reading's own line box.
  implicitHeight: root.icon !== ""
    ? Math.max(Theme.dispToggleIcon, bar.implicitHeight, label.implicitHeight)
    : Math.max(bar.implicitHeight, Theme.lineBox(Theme.sysSliderLabelSize))

  Glyph {
    id: glyph

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter

    visible: root.icon !== ""
    icon: root.icon
    size: Theme.dispToggleIcon
    iconColor: Theme.sysBrightGlyph
  }

  Slider {
    id: bar

    anchors.left: glyph.visible ? glyph.right : parent.left
    anchors.leftMargin: glyph.visible ? Theme.sysSliderGap : 0
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
