import QtQuick
import qs.components
import qs.services
import qs.theme

// one bluetooth device in the row's lists. what it is drawn as comes from bluez's
// own idea of the thing; what it carries besides is a charge, for the few devices
// that report one, and the pairing card it opens under itself while bluez has a
// question about it.
Rectangle {
  id: root

  required property var device

  readonly property bool active: root.device.connected && root.device.paired
  readonly property bool refused: Bluez.failed === root.device.address

  // the card is out for this device, and the one it is still showing while it
  // folds away.
  readonly property bool asked: Bluez.request?.address === root.device.address
  readonly property bool shownHere: Bluez.lastRequest?.address === root.device.address

  // another device's question is up. the design dims every other row and makes
  // it deaf, because bluez only pairs one thing at a time.
  readonly property bool locked: Bluez.request !== null && !root.asked

  readonly property bool busy: Bluez.busy(root.device) || (root.asked && !Bluez.request.cancelled)

  // the charge is what a device usually has to say for itself. while it is
  // changing its mind, or has just failed to, it says that instead -- a click that
  // does nothing visible is worse than a line that admits it.
  readonly property string detail: {
    if (root.refused) return Bluez.failedPairing ? "Could not pair" : "Could not connect"
    if (root.asked && !Bluez.request.cancelled && Bluez.request.kind === "incoming") return "Wants to pair"
    if (root.busy) {
      if (root.active) return "Disconnecting…"
      return root.device.paired ? "Connecting…" : "Pairing…"
    }

    const charge = Bluez.charge(root.device)
    if (charge !== "") return charge

    // the design's own line for a device that is known but not on.
    return root.device.paired && !root.active ? "Paired" : ""
  }

  readonly property bool lit: root.active || root.busy || root.asked

  height: row.height + card.height

  radius: Theme.sysNetRadius
  color: {
    if (root.asked || root.active) return Theme.sysNetActive
    return "transparent"
  }

  opacity: root.locked ? Theme.btLockedOpacity : 1

  Behavior on color {
    ColorAnimation { duration: Theme.notchFadeDuration }
  }

  Behavior on opacity {
    NumberAnimation { duration: Theme.notchFadeDuration }
  }

  ListEntry {
    id: row

    width: parent.width

    icon: Bluez.glyph(root.device)
    name: root.device.name
    detail: root.detail
    detailColor: {
      if (root.refused) return Theme.sysError
      return root.busy && !root.active ? Theme.accent : Theme.sysNetDetail
    }
    lit: root.lit

    // a device mid-question, mid-attempt, or waiting behind another's question
    // has nothing a click could mean.
    clickable: !root.locked && !root.asked && !Bluez.busy(root.device)

    onClicked: Bluez.toggle(root.device)
  }

  // the design grows the card out of the row, and folds it back the same way.
  Item {
    id: card

    anchors.top: row.bottom
    width: parent.width
    height: root.asked ? pairing.implicitHeight : 0
    clip: true

    Behavior on height {
      NumberAnimation {
        duration: Theme.btFold
        easing.type: Easing.Bezier
        easing.bezierCurve: Theme.easeStandard
      }
    }

    PairingCard {
      id: pairing

      width: parent.width
      visible: root.shownHere
      request: root.shownHere ? Bluez.lastRequest : null
    }
  }
}
