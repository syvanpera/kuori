import QtQuick
import qs.theme

// a bar that fills to a fraction and answers to nothing. the battery's charge is
// drawn this way; a Slider is this plus a knob and somewhere to drag it.
Rectangle {
  id: root

  // 0 to 1.
  property real value: 0

  readonly property real fraction: Math.max(0, Math.min(1, root.value))

  // what the fill is painted with. the accent everywhere except the colour
  // temperature, which the design paints in the warm it is about to apply.
  property color tint: Theme.accent

  implicitHeight: Theme.sysSliderTrack
  radius: Theme.sysSliderRadius
  color: Theme.sysSliderRail

  Rectangle {
    width: parent.width * root.fraction
    height: parent.height
    radius: parent.radius
    color: root.tint
  }
}
