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
Rectangle {
  id: root

  readonly property var request: Bluez.request
  readonly property string name: Bluez.requestName

  readonly property string spaced: {
    const code = root.request?.code ?? ""
    return code.length === 6 ? `${code.slice(0, 3)} ${code.slice(3)}` : code
  }

  readonly property string body: {
    switch (root.request?.kind) {
      case "incoming": return `${root.name} wants to pair with this laptop.`
      case "type": return `Type ${root.spaced} on ${root.name}, then press Enter.`
      case "compare": return `Confirm the pairing code for ${root.name}.`
      case "pin": return `Enter the PIN for ${root.name}.`
      default: return `Confirm pairing with ${root.name}.`
    }
  }

  width: Theme.toastWidth
  implicitHeight: row.implicitHeight + Theme.toastPaddingV * 2

  radius: Theme.toastRadius
  color: Theme.toastFill
  border.width: 1
  border.color: Theme.pkOutline

  Row {
    id: row

    x: Theme.toastPaddingH
    y: Theme.toastPaddingV
    width: parent.width - Theme.toastPaddingH * 2

    spacing: Theme.toastRowGap

    Rectangle {
      width: Theme.toastChipSize
      height: Theme.toastChipSize
      radius: Theme.toastChipRadius
      color: Theme.toastChipFill

      Glyph {
        anchors.centerIn: parent

        icon: "bluetooth"
        iconColor: Theme.accent
        size: Theme.toastChipIcon
      }
    }

    Column {
      width: parent.width - Theme.toastChipSize - Theme.toastRowGap
      spacing: Theme.toastTextGap

      Item {
        width: parent.width
        height: Math.max(app.implicitHeight, when.implicitHeight)

        Text {
          id: app

          anchors.left: parent.left
          anchors.right: when.left
          anchors.rightMargin: Theme.toastRowGap
          anchors.baseline: when.baseline

          text: "Bluetooth"
          elide: Text.ElideRight
          color: Theme.tintBright
          font.family: Theme.monoFont
          font.pixelSize: Theme.toastAppSize
          font.weight: Font.Medium
        }

        // always now: a question bluez stops waiting on after a minute or so has no
        // age worth counting.
        Text {
          id: when

          anchors.right: parent.right

          text: "now"
          color: Theme.toastTime
          font.family: Theme.monoFont
          font.pixelSize: Theme.toastTimeSize
        }
      }

      Text {
        width: parent.width

        text: root.body
        wrapMode: Text.Wrap
        color: Theme.toastBody
        font.family: Theme.uiFont
        font.pixelSize: Theme.toastBodySize
        lineHeight: Theme.toastBodyLine
        lineHeightMode: Text.FixedHeight
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
  }

  MouseArea {
    anchors.fill: parent

    // the focused screen, which is where the toast itself went up.
    onClicked: Notches.showRow("bluetooth", "")
  }
}
