pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

// the bluetooth adapter and what it can see.
//
// named for the daemon rather than the radio because Quickshell.Bluetooth already
// exports a singleton called Bluetooth, and a file in qs.services with that name
// could not say which one it meant. this is the only place that imports it.
Singleton {
  id: root

  // the panel raises this while the bluetooth row is folded open. discovery wakes
  // the radio and keeps it scanning, so it stops the moment the row folds away --
  // the same bargain the wifi scan makes.
  property bool detailed: false

  // the address of a device we have asked to connect and not heard back about,
  // and the one whose last attempt came to nothing. a bluetooth device that has
  // stopped advertising cannot be connected to by the host, and bluez reports
  // that by simply never arriving -- so without these a refused click and a dead
  // click look exactly the same.
  property string pending: ""
  property string failed: ""

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool enabled: root.adapter?.enabled ?? false

  readonly property var devices: root.enabled ? Bluetooth.devices.values : []

  // the device `pending` names, for whatever is drawing the attempt.
  readonly property var pendingDevice: root.devices.find(d => d.address === root.pending) ?? null

  readonly property var connected: root.devices.filter(d => d.connected)

  // everything the adapter knows about that is not currently on: devices paired
  // before, and whatever discovery turns up while the row is open.
  //
  // sorted, and paired first. bluez hands them over in whatever order it learned
  // them, so an unsorted list rearranges itself under the pointer every time
  // discovery finds something -- and the row you meant to click is a device you
  // own, not a stranger's fridge.
  readonly property var available: root.devices
    .filter(d => !d.connected)
    .sort((a, b) => (b.paired - a.paired) || a.name.localeCompare(b.name))

  // what the collapsed row says on the right. the first connected device, because
  // the row has space for one name and that is the one worth having.
  readonly property string summary: {
    if (!root.enabled) return "Off"
    if (root.connected.length === 0) return "Not connected"
    if (root.connected.length === 1) return root.connected[0].name
    return `${root.connected[0].name} +${root.connected.length - 1}`
  }

  function setEnabled(on: bool): void {
    if (root.adapter) root.adapter.enabled = on
  }

  // a click on a device is a request to change its mind about being connected.
  // pairing is not offered: it needs somewhere to show a code, which the design
  // has no room for.
  function toggle(device: var): void {
    if (!device) return

    root.failed = ""

    if (device.connected) {
      device.disconnect()
      return
    }

    root.pending = device.address
    device.connect()
  }

  // whether this device is in the middle of changing its mind.
  function busy(device: var): bool {
    if (!device) return false
    return device.address === root.pending
      || device.state === BluetoothDeviceState.Connecting
      || device.state === BluetoothDeviceState.Disconnecting
  }

  // bluez reports a freedesktop icon name, which the design draws as material
  // symbols. anything unrecognised keeps the bluetooth mark rather than guessing.
  function glyph(device: var): string {
    switch (device?.icon) {
      case "audio-headset":
      case "audio-headphones": return "headphones"
      case "audio-card":
      case "audio-speakers": return "speaker"
      case "input-mouse": return "mouse"
      case "input-keyboard": return "keyboard"
      case "input-gaming": return "sports_esports"
      case "input-tablet": return "stylus"
      case "phone": return "mobile"
      case "computer": return "computer"
      case "multimedia-player": return "music_note"
      case "printer": return "print"
      case "camera-photo": return "photo_camera"
      case "camera-video": return "videocam"
      case "video-display": return "tv"
      case "watch": return "watch"
      default: return "bluetooth"
    }
  }

  // the design writes a device's charge under its name. most bluetooth devices
  // never report one, so the line is simply absent rather than showing a zero.
  function charge(device: var): string {
    if (!device?.batteryAvailable) return ""
    return `${Math.round(device.battery * 100)}%`
  }

  function giveUp(): void {
    if (root.pending === "") return

    root.failed = root.pending
    root.pending = ""
    linger.restart()
  }

  Connections {
    target: root.pendingDevice

    function onStateChanged(): void {
      const device = root.pendingDevice
      if (!device) return

      if (device.state === BluetoothDeviceState.Connected) {
        root.pending = ""
        return
      }

      // back to where it started without ever arriving. bluez refuses a device
      // that is not advertising, which is most of them a moment after the host
      // dropped them -- hence the mouse you have to switch off and on again.
      if (device.state === BluetoothDeviceState.Disconnected) root.giveUp()
    }
  }

  // and in case it never moves at all.
  Timer {
    interval: 20000
    running: root.pending !== ""

    onTriggered: root.giveUp()
  }

  Timer {
    id: linger

    interval: 1800

    onTriggered: root.failed = ""
  }

  // discovery is what fills the available list with things that were never paired.
  Binding {
    target: root.adapter
    property: "discovering"
    value: root.detailed && root.enabled
    when: root.adapter !== null
  }
}
