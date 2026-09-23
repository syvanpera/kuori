import QtQuick
import qs.theme

// a label on a rounded fill that lightens under the pointer: every button the
// shell draws, from a toast's actions to the polkit card's Authenticate. each
// caller hands it its own tokens, because the design sizes and colours each of
// them separately.
Rectangle {
  id: root

  property string label: ""

  property color fill: Theme.accent
  property color hoverFill: root.fill
  property color textColor: Theme.litText
  property real textSize: Theme.cfButtonSize

  property real paddingH: 0
  property real paddingV: 0

  // the keyboard's choice. it wears the hover look, because that is already the
  // shell's way of saying "this is the one you are about to press" and a second
  // vocabulary for the same statement would be one too many.
  property bool selected: false

  // some cards draw a ring round the keyboard's choice as well.
  property real ring: 0
  property color ringColor: "transparent"

  property int fade: Theme.notchFadeDuration

  readonly property bool hovered: mouse.containsMouse

  signal clicked()

  implicitWidth: caption.implicitWidth + root.paddingH * 2
  implicitHeight: caption.implicitHeight + root.paddingV * 2

  // a pill is its own height, not a number: the design writes 999 for the radius,
  // which is css for "as round as it goes". callers with a real radius set one.
  radius: root.height / 2
  color: root.hovered || root.selected ? root.hoverFill : root.fill

  border.width: root.ring
  border.color: root.ringColor

  Behavior on color {
    ColorAnimation { duration: root.fade }
  }

  Text {
    id: caption

    anchors.centerIn: parent

    text: root.label
    color: root.textColor
    font.family: Theme.uiFont
    font.pixelSize: root.textSize
    font.variableAxes: Theme.uiAxesSemiBold
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true

    onClicked: root.clicked()
  }
}
