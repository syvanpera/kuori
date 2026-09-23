import QtQuick
import qs.components
import qs.services
import qs.theme

// a bluetooth question asked while nobody is looking at the bluetooth section:
// what it wants, and a click that goes there. it answers nothing itself -- the
// card in the panel is the only place a code can be read and a pairing allowed.
//
// not a notification. bluez waits on the answer, and a notification is a thing
// that can be dismissed, missed under do-not-disturb, or left in a history long
// after the question it asked has expired.
ToastFrame {
  id: root

  readonly property var request: Bluez.request
  readonly property string name: Bluez.requestName

  readonly property string spaced: Bluez.spacedCode(root.request?.code ?? "")

  readonly property string body: {
    switch (root.request?.kind) {
      case "incoming": return `${root.name} wants to pair with this laptop.`
      case "type": return `Type ${root.spaced} on ${root.name}, then press Enter.`
      case "compare": return `Confirm the pairing code for ${root.name}.`
      case "pin": return `Enter the PIN for ${root.name}.`
      default: return `Confirm pairing with ${root.name}.`
    }
  }

  app: "Bluetooth"

  // always now: a question bluez stops waiting on after a minute or so has no age
  // worth counting.
  when: "now"

  // the focused screen, which is where the toast itself went up.
  onClicked: Notches.showRow("bluetooth", "")

  tile: Glyph {
    anchors.centerIn: parent

    icon: "bluetooth"
    iconColor: Theme.accent
    size: Theme.toastChipIcon
  }

  ToastFrame.BodyText {
    text: root.body
  }

  Text {
    topPadding: Theme.toastLinkTop

    text: "OPEN BLUETOOTH"
    color: Theme.accent
    font.family: Theme.monoFont
    font.pixelSize: Theme.toastLinkSize
    font.weight: Font.Medium
    font.letterSpacing: Theme.toastLinkSpacing
  }
}
