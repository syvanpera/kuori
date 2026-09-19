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

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool enabled: root.adapter?.enabled ?? false

  readonly property var devices: root.enabled ? Bluetooth.devices.values : []

  readonly property var connected: root.devices.filter(d => d.connected)

  // everything the adapter knows about that is not currently on: devices paired
  // before, and whatever discovery turns up while the row is open.
  readonly property var available: root.devices.filter(d => !d.connected)

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
    if (device.connected) device.disconnect()
    else device.connect()
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

  // discovery is what fills the available list with things that were never paired.
  Binding {
    target: root.adapter
    property: "discovering"
    value: root.detailed && root.enabled
    when: root.adapter !== null
  }
}
