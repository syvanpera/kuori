import QtQuick
import qs.components
import qs.services
import qs.theme

// the brightness row. not an accordion row: it has nothing to fold out, so it is
// a glyph, a slider and a reading, sitting under the rows that do.
Item {
  id: root

  // a machine with no backlight has no row.
  visible: Backlight.known

  implicitHeight: Math.max(Theme.sysBrightIcon, slider.implicitHeight, reading.implicitHeight)
    + Theme.sysBrightPadding * 2

  // the level is only polled while the panel is up. enabled comes down from the
  // loader that holds the panel, so this follows the tab being open.
  Binding {
    target: Backlight
    property: "watching"
    value: root.enabled
  }

  Glyph {
    id: light

    x: Theme.sysBrightPadding
    anchors.verticalCenter: parent.verticalCenter

    size: Theme.sysBrightIcon
    icon: "light_mode"
    iconColor: Theme.sysBrightGlyph
  }

  Slider {
    id: slider

    anchors.left: light.right
    anchors.leftMargin: Theme.sysBrightGap
    anchors.right: reading.left
    anchors.rightMargin: Theme.sysBrightGap
    anchors.verticalCenter: parent.verticalCenter

    value: Backlight.level

    onMoved: level => Backlight.set(level)
  }

  Text {
    id: reading

    anchors.right: parent.right
    anchors.rightMargin: Theme.sysBrightPadding
    anchors.verticalCenter: parent.verticalCenter
    width: Theme.sysSliderLabelWidth

    text: `${Backlight.percent}%`
    color: Theme.sysSliderText
    font.family: Theme.monoFont
    font.pixelSize: Theme.sysSliderLabelSize
    font.weight: Font.Medium
    horizontalAlignment: Text.AlignRight
  }
}
