import QtQuick
import qs.components
import qs.services
import qs.theme

// one bluetooth device in the row's lists. what it is drawn as comes from bluez's
// own idea of the thing, and the only extra it carries is a charge, for the few
// devices that report one.
Rectangle {
  id: root

  required property var device

  readonly property bool active: root.device.connected
  readonly property bool refused: Bluez.failed === root.device.address

  // the charge is what a device usually has to say for itself. while it is
  // changing its mind, or has just failed to, it says that instead -- the design
  // has no state for either, and a click that does nothing visible is worse than
  // a line that admits it.
  readonly property string detail: {
    if (root.refused) return Bluez.failedPairing ? "Could not pair" : "Could not connect"
    if (Bluez.busy(root.device)) {
      if (root.active && root.device.paired) return "Disconnecting…"
      return root.device.paired ? "Connecting…" : "Pairing…"
    }
    return Bluez.charge(root.device)
  }

  width: parent.width
  height: Math.max(Theme.sysNetIcon, text.implicitHeight) + Theme.sysNetPaddingV * 2

  radius: Theme.sysNetRadius
  color: {
    if (hover.containsMouse) return Theme.sysNetHover
    return root.active ? Theme.sysNetActive : "transparent"
  }

  Behavior on color {
    ColorAnimation { duration: Theme.notchFadeDuration }
  }

  Glyph {
    id: deviceIcon

    x: Theme.sysNetPaddingH
    anchors.verticalCenter: parent.verticalCenter

    size: Theme.sysNetIcon
    icon: Bluez.glyph(root.device)
    iconColor: root.active ? Theme.accent : Theme.sysNetGlyph
  }

  Column {
    id: text

    anchors.left: deviceIcon.right
    anchors.leftMargin: Theme.sysNetGap
    anchors.right: parent.right
    anchors.rightMargin: Theme.sysNetPaddingH
    anchors.verticalCenter: parent.verticalCenter

    spacing: Theme.sysNetTextSpacing

    Text {
      width: parent.width

      text: root.device.name
      color: root.active ? Theme.text : Theme.sysNetName
      font.family: Theme.monoFont
      font.pixelSize: Theme.sysNetNameSize
      font.weight: Font.Medium
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      visible: root.detail !== ""

      text: root.detail
      color: root.refused ? Theme.sysError : Theme.sysNetDetail
      font.family: Theme.monoFont
      font.pixelSize: Theme.sysNetDetailSize
    }
  }

  MouseArea {
    id: hover

    anchors.fill: parent
    hoverEnabled: true

    onClicked: Bluez.toggle(root.device)
  }
}
