import QtQuick
import qs.theme

// the design's slider: a thin track with an accent fill and a round knob centred
// on the end of it. it reports where it was dragged to rather than moving itself,
// so what it shows is always what the thing behind it settled on.
Item {
  id: root

  // 0 to 1.
  property real value: 0

  signal moved(real value)

  readonly property real fraction: Math.max(0, Math.min(1, root.value))

  implicitHeight: Theme.sysSliderKnob

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter

    height: Theme.sysSliderTrack
    radius: Theme.sysSliderRadius
    color: Theme.sysSliderRail

    Rectangle {
      width: parent.width * root.fraction
      height: parent.height
      radius: parent.radius
      color: Theme.accent
    }
  }

  // centred on the end of the fill, so at full it sits half outside the track --
  // which is what the design draws.
  Rectangle {
    x: root.width * root.fraction - width / 2
    anchors.verticalCenter: parent.verticalCenter

    width: Theme.sysSliderKnob
    height: Theme.sysSliderKnob
    radius: width / 2
    color: Theme.accent
  }

  MouseArea {
    anchors.fill: parent

    onPressed: event => root.moved(event.x / root.width)
    onPositionChanged: event => root.moved(event.x / root.width)
  }
}
