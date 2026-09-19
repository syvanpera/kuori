import QtQuick
import qs.components
import qs.services
import qs.theme

// the bluetooth row of the system panel: what is on at a glance, and underneath
// it the radio switch, what is connected, and what else is around.
PanelRow {
  id: root

  icon: Bluez.enabled ? "bluetooth" : "bluetooth_disabled"
  label: "Bluetooth"
  lit: Bluez.enabled
  value: Bluez.summary

  // discovery only runs while the row is open.
  Binding {
    target: Bluez
    property: "detailed"
    value: root.expanded
  }

  Item {
    width: root.bodyWidth
    height: Math.max(enabledLabel.implicitHeight, radio.height)

    Text {
      id: enabledLabel

      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      text: "ENABLED"
      color: Theme.sysCap
      font.family: Theme.monoFont
      font.pixelSize: Theme.sysCapSize
      font.weight: Font.Medium
      font.letterSpacing: Theme.sysCapSpacing
    }

    Switch {
      id: radio

      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      checked: Bluez.enabled

      onToggled: Bluez.setEnabled(!Bluez.enabled)
    }
  }

  // no rule above this one: it sits directly under the switch, which the design
  // leaves unruled. the wifi row's first list needs one because a grid of
  // readings comes before it.
  DeviceSection {
    width: root.bodyWidth
    heading: "CONNECTED"
    ruled: false
    model: Bluez.connected

    delegate: BluetoothEntry {
      required property var modelData

      device: modelData
    }
  }

  DeviceSection {
    width: root.bodyWidth
    heading: "AVAILABLE"

    // ruled off from the list above only when there is one. with nothing
    // connected this becomes the first section, and the design leaves the first
    // one sitting straight under the switch.
    ruled: Bluez.connected.length > 0
    model: Bluez.available

    delegate: BluetoothEntry {
      required property var modelData

      device: modelData
    }
  }
}
