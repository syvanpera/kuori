import QtQuick
import qs.components
import qs.services
import qs.theme

// one ethernet interface in the network row: what it is called, whether a cable is
// in it, and a switch at the far end. the wire has no list of networks to choose
// from, so unlike a wifi entry the row itself does nothing when clicked.
ListEntry {
  id: root

  required property var device

  readonly property bool active: root.device.connected

  icon: "lan"
  name: `Wired · ${root.device.name}`
  detail: Network.wiredDetail(root.device)
  lit: root.active
  fill: root.active ? Theme.sysNetActive : "transparent"
  clickable: false

  Switch {
    id: control

    // on while connected or on its way there, so the knob does not bounce back
    // across while dhcp is still answering the click that moved it.
    checked: root.active || Network.wiredConnecting(root.device)
    enabled: root.device.hasLink

    onToggled: Network.setWired(root.device, !control.checked)
  }
}
