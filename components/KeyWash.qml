import QtQuick
import qs.theme

// the wash behind whatever the keyboard is on in a panel. it is the hover look of
// a list entry, because in this shell hover and keyboard selection mean the same
// thing -- "this is the one you are about to press" -- and say it the same way.
// it reaches a little past its item, so a switch sitting flush in its row gets a
// pad of its own rather than a highlight cut off at the label's edge.
Rectangle {
  id: root

  property bool shown: false
  property real inset: Theme.keyWashInset

  anchors.fill: parent
  anchors.margins: -root.inset
  z: -1

  radius: Theme.sysNetRadius
  color: root.shown ? Theme.sysNetHover : "transparent"

  Behavior on color {
    ColorAnimation { duration: Theme.notchFadeDuration }
  }
}
