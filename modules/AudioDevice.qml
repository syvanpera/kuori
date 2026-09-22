import QtQuick
import qs.components
import qs.services
import qs.theme

// one output or input you could pick. no second line: a device is a name and
// what kind of thing it is, and the design gives it nothing else to say.
Rectangle {
  id: root

  required property var node

  // whether this is the one sound is going to or coming from.
  property bool current: false

  signal picked()

  width: parent.width
  height: Theme.sysNetIcon + Theme.sysNetPaddingV * 2

  radius: Theme.sysNetRadius
  color: {
    if (hover.containsMouse) return Theme.sysNetHover
    return root.current ? Theme.sysNetActive : "transparent"
  }

  Behavior on color {
    ColorAnimation { duration: Theme.notchFadeDuration }
  }

  Glyph {
    id: deviceIcon

    x: Theme.sysNetPaddingH
    anchors.verticalCenter: parent.verticalCenter

    size: Theme.sysNetIcon
    icon: Audio.glyph(root.node)
    iconColor: root.current ? Theme.accent : Theme.sysNetGlyph
  }

  Text {
    anchors.left: deviceIcon.right
    anchors.leftMargin: Theme.sysNetGap
    anchors.right: parent.right
    anchors.rightMargin: Theme.sysNetPaddingH
    anchors.verticalCenter: parent.verticalCenter

    text: Audio.label(root.node)
    color: root.current ? Theme.text : Theme.sysDeviceName
    font.family: Theme.monoFont
    font.pixelSize: Theme.sysNetNameSize
    font.weight: Font.Medium
    elide: Text.ElideRight
  }

  MouseArea {
    id: hover

    anchors.fill: parent
    hoverEnabled: true

    onClicked: root.picked()
  }
}
