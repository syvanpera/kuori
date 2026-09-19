import QtQuick
import qs.components
import qs.theme

// a slider with its reading beside it, which is how the design writes both the
// output level and the input one.
Item {
  id: root

  property real value: 0

  signal moved(real value)

  implicitHeight: Math.max(slider.implicitHeight, Theme.lineBox(Theme.sysSliderLabelSize))

  Slider {
    id: slider

    anchors.left: parent.left
    anchors.right: reading.left
    anchors.rightMargin: Theme.sysSliderGap
    anchors.verticalCenter: parent.verticalCenter

    value: root.value

    onMoved: level => root.moved(level)
  }

  Text {
    id: reading

    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: Theme.sysSliderLabelWidth

    text: `${Math.round(root.value * 100)}%`
    color: Theme.sysSliderText
    font.family: Theme.monoFont
    font.pixelSize: Theme.sysSliderLabelSize
    font.weight: Font.Medium
    horizontalAlignment: Text.AlignRight
  }
}
