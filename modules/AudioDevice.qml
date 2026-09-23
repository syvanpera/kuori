import QtQuick
import qs.components
import qs.services
import qs.theme

// one output or input you could pick. no second line: a device is a name and
// what kind of thing it is, and the design gives it nothing else to say.
ListEntry {
  id: root

  required property var node

  // whether this is the one sound is going to or coming from.
  property bool current: false

  signal picked()

  icon: Audio.glyph(root.node)
  name: Audio.label(root.node)
  lit: root.current
  nameColor: Theme.sysDeviceName
  fill: root.current ? Theme.sysNetActive : "transparent"
  compact: true

  onClicked: root.picked()
}
