import QtQuick
import qs.components
import qs.services
import qs.theme

// one ethernet interface in the network row: what it is called, whether a cable is
// in it, and a switch at the far end. the wire has no list of networks to choose
// from, so unlike a wifi entry the row itself does nothing when clicked.
Rectangle {
  id: root

  required property var device

  readonly property bool active: root.device.connected

  height: Math.max(Theme.sysNetIcon, text.implicitHeight) + Theme.sysNetPaddingV * 2

  radius: Theme.sysNetRadius
  color: root.active ? Theme.sysNetActive : "transparent"

  Behavior on color {
    ColorAnimation { duration: Theme.notchFadeDuration }
  }

  Glyph {
    id: entryIcon

    x: Theme.sysNetPaddingH
    anchors.verticalCenter: parent.verticalCenter

    size: Theme.sysNetIcon
    icon: "lan"
    iconColor: root.active ? Theme.accent : Theme.sysNetGlyph
  }

  Switch {
    id: control

    x: root.width - Theme.sysNetPaddingH - width
    anchors.verticalCenter: parent.verticalCenter

    // on while connected or on its way there, so the knob does not bounce back
    // across while dhcp is still answering the click that moved it.
    checked: root.active || Network.wiredConnecting(root.device)
    enabled: root.device.hasLink

    onToggled: Network.setWired(root.device, !control.checked)
  }

  Column {
    id: text

    anchors.left: entryIcon.right
    anchors.leftMargin: Theme.sysNetGap
    anchors.right: control.left
    anchors.rightMargin: Theme.sysNetGap
    anchors.verticalCenter: parent.verticalCenter

    spacing: Theme.sysNetTextSpacing

    Text {
      width: parent.width

      text: `Wired · ${root.device.name}`
      color: root.active ? Theme.text : Theme.sysNetName
      font.family: Theme.monoFont
      font.pixelSize: Theme.sysNetNameSize
      font.weight: Font.Medium
      elide: Text.ElideRight
    }

    Text {
      width: parent.width

      text: Network.wiredDetail(root.device)
      color: Theme.sysNetDetail
      font.family: Theme.monoFont
      font.pixelSize: Theme.sysNetDetailSize
      elide: Text.ElideRight
    }
  }
}
