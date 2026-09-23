import QtQuick
import qs.components
import qs.services
import qs.theme

// what a bluetooth device opens under its own row while bluez has a question:
// one of the design's five cards, or the line saying it was called off.
//
// it draws the request it is handed rather than Bluez.request, because it is
// handed the last one while it folds away and must not empty itself on screen.
Item {
  id: root

  required property var request

  readonly property string kind: root.request?.kind ?? ""
  readonly property bool cancelled: root.request?.cancelled ?? false
  readonly property string code: root.request?.code ?? ""
  readonly property int entered: root.request?.entered ?? -1

  readonly property string spaced: Bluez.spacedCode(root.code)

  implicitHeight: body.implicitHeight + Theme.btCardTop + Theme.btCardBottom

  component CardText: Text {
    width: parent.width

    color: Theme.btCardText
    font.family: Theme.uiFont
    font.variableAxes: Theme.uiAxesRegular
    font.pixelSize: Theme.btCardTextSize
    lineHeight: Theme.btCardTextLine
    lineHeightMode: Text.FixedHeight
    wrapMode: Text.Wrap
  }

  // the toast's own buttons, sized for the card. the keyboard's choice wears a
  // ring, as the design draws it: the card says enter does something, so it has
  // to say which.
  component CardButton: PillButton {
    id: button

    property bool primary: false
    property bool ringed: false

    fill: button.primary ? Theme.toastPrimaryFill : Theme.toastActionFill
    hoverFill: button.primary ? Theme.toastPrimaryHover : Theme.toastActionHover
    textColor: button.primary ? Theme.accent : Theme.btSecondaryText
    textSize: Theme.btButtonSize
    paddingH: Theme.btButtonPaddingH
    paddingV: Theme.btButtonPaddingV
    radius: Theme.btButtonRadius

    ring: button.ringed ? Theme.btButtonRing : 0
    ringColor: button.primary ? Theme.accent : Theme.btSecondaryRing
  }

  Column {
    id: body

    x: Theme.btCardInset
    y: Theme.btCardTop
    width: root.width - Theme.btCardInset - Theme.sysNetPaddingH

    spacing: Theme.btCardGap

    CardText {
      visible: !root.cancelled && root.kind === "confirm"
      text: `Pair with ${Bluez.requestName}?`
    }

    Column {
      width: parent.width
      visible: !root.cancelled && root.kind === "compare"
      spacing: Theme.btCardTextGap

      Text {
        text: root.spaced
        color: Theme.btCode
        font.family: Theme.monoFont
        font.pixelSize: Theme.btCodeSize
        font.weight: Font.Medium
        font.letterSpacing: Theme.btCodeSpacing
      }

      CardText {
        text: `Does ${Bluez.requestName} show the same code?`
      }
    }

    Column {
      width: parent.width
      visible: !root.cancelled && root.kind === "type"
      spacing: Theme.btCardTextGap

      // a digit per cell, so each one can light up as it is typed on the device.
      Row {
        Repeater {
          model: root.code.split("")

          Text {
            required property int index
            required property string modelData

            // the gap in the middle is padding on the fourth cell, which the text
            // centres itself clear of.
            leftPadding: index === 3 && root.code.length === 6 ? Theme.btDigitSplit : 0
            width: Theme.btDigitWidth + leftPadding

            text: modelData
            horizontalAlignment: Text.AlignHCenter
            color: {
              // a legacy pin reports nothing as it is typed, so it is shown as a
              // code to read rather than as progress.
              if (root.entered < 0) return Theme.btCode
              return index < root.entered ? Theme.accent : Theme.btDigitDim
            }
            font.family: Theme.monoFont
            font.pixelSize: Theme.btCodeSize
            font.weight: Font.Medium

            Behavior on color {
              ColorAnimation { duration: Theme.notchFadeDuration }
            }
          }
        }
      }

      CardText {
        text: `Type this on ${Bluez.requestName}, then press Enter`
      }
    }

    Column {
      width: parent.width
      visible: !root.cancelled && root.kind === "pin"
      spacing: Theme.btCardTextGap

      CardText {
        text: `Enter the PIN or passkey for ${Bluez.requestName}`
      }

      Loader {
        width: parent.width

        // built only for the pin card, because the field takes the keyboard the
        // moment it exists.
        active: !root.cancelled && root.kind === "pin" && Bluez.asking

        sourceComponent: Rectangle {
          height: field.implicitHeight + Theme.btFieldPaddingV * 2

          radius: Theme.btButtonRadius
          color: Theme.sysFieldFill
          border.width: 1
          border.color: Theme.sysFieldBorder

          Field {
            id: field

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.btFieldPaddingH
            anchors.rightMargin: Theme.btFieldPaddingH
            anchors.verticalCenter: parent.verticalCenter

            focus: true
            color: Theme.text
            font.family: Theme.monoFont
            font.pixelSize: Theme.btFieldSize
            font.weight: Font.Medium
            selectByMouse: true

            Component.onCompleted: field.forceActiveFocus()

            // the frame's key sink is what hears escape once this is gone, and it
            // will not take the keyboard back on its own.
            Component.onDestruction: Notches.refocus()

            onTextChanged: Bluez.pin = field.text

            Keys.onReturnPressed: Bluez.selected === 0 ? Bluez.accept() : Bluez.reject()
            Keys.onEnterPressed: Bluez.selected === 0 ? Bluez.accept() : Bluez.reject()
            Keys.onEscapePressed: Bluez.reject()
            Keys.onTabPressed: Bluez.selected = 1 - Bluez.selected

            placeholder: "PIN or passkey"
          }
        }
      }
    }

    CardText {
      visible: !root.cancelled && root.kind === "incoming"
      text: `${Bluez.requestName} wants to pair`
    }

    Row {
      visible: root.cancelled
      spacing: Theme.sysErrorGap

      Glyph {
        anchors.verticalCenter: parent.verticalCenter

        icon: "block"
        size: Theme.btCancelledIcon
        iconColor: Theme.btCancelledIconColor
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter

        text: "Pairing cancelled"
        color: Theme.btCancelledText
        font.family: Theme.uiFont
        font.pixelSize: Theme.btCancelledSize
        font.variableAxes: Theme.uiAxesMedium
      }
    }

    Item {
      width: parent.width
      height: buttons.height
      visible: !root.cancelled

      Text {
        anchors.left: parent.left
        anchors.right: buttons.left
        anchors.rightMargin: Theme.btButtonGap
        anchors.verticalCenter: parent.verticalCenter

        visible: root.kind === "type" && root.entered >= 0
        text: `${root.entered} of ${root.code.length} entered`
        elide: Text.ElideRight
        color: Theme.btCounter
        font.family: Theme.monoFont
        font.pixelSize: Theme.btCounterSize
      }

      Row {
        id: buttons

        anchors.right: parent.right

        spacing: Theme.btButtonGap

        CardButton {
          label: root.kind === "incoming" ? "Deny" : "Cancel"
          ringed: Bluez.selected === 1 && root.kind !== "type"

          onClicked: {
            Bluez.selected = 1
            Bluez.reject()
          }
        }

        // a keyboard's pairing is finished by typing on the keyboard, so its card
        // has nothing to accept.
        CardButton {
          visible: root.kind !== "type"
          label: root.kind === "incoming" ? "Allow" : "Pair"
          primary: true
          ringed: Bluez.selected === 0
          opacity: root.kind === "pin" && Bluez.pin === "" ? Theme.btPrimaryDisabledOpacity : 1

          onClicked: {
            Bluez.selected = 0
            Bluez.accept()
          }
        }
      }
    }
  }
}
