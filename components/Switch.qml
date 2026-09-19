import QtQuick
import qs.theme

// the pill switch the design uses wherever something is simply on or off. it
// reports a request rather than flipping itself: what it shows is whatever the
// thing behind it actually settled on, which for a radio is a round trip through
// NetworkManager and not instant.
Rectangle {
  id: root

  property bool checked: false

  signal toggled()

  implicitWidth: Theme.switchWidth
  implicitHeight: Theme.switchHeight

  radius: height / 2
  color: root.checked ? Theme.accent : Theme.switchTrack

  Behavior on color {
    ColorAnimation { duration: Theme.notchFadeDuration }
  }

  Rectangle {
    // the knob's travel is its own width, because the track is padded by the same
    // amount on both sides.
    x: root.checked ? root.width - width - Theme.switchPadding : Theme.switchPadding
    anchors.verticalCenter: parent.verticalCenter

    width: Theme.switchKnob
    height: Theme.switchKnob
    radius: width / 2
    // the knob on a lit track is a hole punched in it, so it takes the colour of
    // the panel behind rather than a grey of its own.
    color: root.checked ? Theme.notch : Theme.switchKnobOff

    Behavior on x {
      NumberAnimation {
        duration: 200
        easing.type: Easing.Bezier
        easing.bezierCurve: Theme.easeStandard
      }
    }

    Behavior on color {
      ColorAnimation { duration: Theme.notchFadeDuration }
    }
  }

  MouseArea {
    anchors.fill: parent

    onClicked: root.toggled()
  }
}
