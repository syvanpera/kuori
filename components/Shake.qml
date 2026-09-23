import QtQuick
import qs.theme

// the design's qs-lk-shake: seven pixels left, six right, four, two, and still,
// over Theme.lockShake. it drives a Translate rather than the item's x, so
// whatever lays the item out never sees it move.
SequentialAnimation {
  id: root

  required property Translate shift

  readonly property int step: Math.round(Theme.lockShake / 5)

  NumberAnimation { target: root.shift; property: "x"; to: -7; duration: root.step }
  NumberAnimation { target: root.shift; property: "x"; to: 6; duration: root.step }
  NumberAnimation { target: root.shift; property: "x"; to: -4; duration: root.step }
  NumberAnimation { target: root.shift; property: "x"; to: 2; duration: root.step }
  NumberAnimation { target: root.shift; property: "x"; to: 0; duration: root.step }
}
