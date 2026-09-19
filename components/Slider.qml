import QtQuick
import qs.theme

// a Meter with a knob on the end of the fill and somewhere to drag it. it reports
// where it was dragged to rather than moving itself, so what it shows is always
// what the thing behind it settled on.
Item {
  id: root

  // 0 to 1.
  property real value: 0

  signal moved(real value)

  implicitHeight: Theme.sysSliderKnob

  Meter {
    id: track

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter

    value: root.value
  }

  // centred on the end of the fill, so at full it sits half outside the track --
  // which is what the design draws.
  Rectangle {
    x: root.width * track.fraction - width / 2
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
