import QtQuick
import qs.components
import qs.services
import qs.theme

// the card polkit puts in front of everything: what is being asked, who is being
// asked, and somewhere to type. it reads a flow-shaped object and calls two
// methods on it; it does not know whether the flow is real.
Rectangle {
  id: root

  required property var flow

  // pam stops asking while it is thinking. that is the only signal a real flow
  // gives that something is in flight, so it is what "verifying" means here.
  readonly property bool busy: root.flow && !root.flow.isResponseRequired && !root.flow.isCompleted
  readonly property bool ok: root.flow?.isSuccessful ?? false
  readonly property bool errored: root.flow?.supplementaryIsError ?? false

  readonly property var identity: root.flow?.selectedIdentity ?? null
  readonly property string who: root.identity?.displayName || root.identity?.string || ""

  // the user's own preference, layered over what pam asked for. responseVisible
  // is pam saying whether to echo at all -- a username prompt does, a password
  // does not -- and the eye is the user overriding that for their own eyes.
  property bool revealed: false
  readonly property bool echo: (root.flow?.responseVisible ?? false) || root.revealed

  property bool detailed: false

  signal submitted(string value)
  signal cancelled()

  width: Theme.pkWidth
  implicitHeight: layout.implicitHeight

  radius: Theme.notchRadius
  color: Theme.notch

  // the design hangs a hairline outline on the card as well as the shadow.
  border.width: 1
  border.color: Theme.pkOutline

  function send(): void {
    if (root.busy || root.ok) return
    root.submitted(input.text)
    input.text = ""
  }

  Column {
    id: layout

    width: parent.width

    // header: what is being asked
    Item {
      width: parent.width
      height: Math.max(chip.height, headText.implicitHeight) + Theme.pkHeadTop + Theme.pkHeadBottom

      Rectangle {
        id: chip

        x: Theme.pkGutter
        y: Theme.pkHeadTop

        width: Theme.pkChipSize
        height: Theme.pkChipSize
        radius: Theme.pkChipRadius
        color: Theme.pkChipFill

        Glyph {
          anchors.centerIn: parent

          size: Theme.pkChipIcon
          icon: "admin_panel_settings"
          iconColor: Theme.elevated
          filled: true
        }
      }

      Column {
        id: headText

        anchors.left: chip.right
        anchors.leftMargin: Theme.pkHeadGap
        anchors.right: parent.right
        anchors.rightMargin: Theme.pkGutter
        y: Theme.pkHeadTop

        spacing: Theme.pkTitleGap

        Text {
          width: parent.width

          text: "Authentication required"
          color: Theme.tintBright
          font.family: Theme.uiFont
          font.pixelSize: Theme.pkTitleSize
          font.variableAxes: Theme.uiAxesSemiBold
          wrapMode: Text.WordWrap
        }

        Text {
          width: parent.width

          text: root.flow?.message ?? ""
          color: Theme.pkMessageText
          font.family: Theme.uiFont
          font.pixelSize: Theme.pkMessageSize
          // css line-height:1.5. qmls lineHeight multiplies the fonts own line
          // spacing, which is already taller than the pixel size, so the ratio has
          // to be turned into a fixed box or the paragraph comes out airy.
          lineHeight: Math.round(Theme.pkMessageSize * 1.5)
          lineHeightMode: Text.FixedHeight
          wrapMode: Text.WordWrap
        }
      }
    }

    // who is answering
    Item {
      width: parent.width
      height: identityRow.height

      Rectangle {
        id: identityRow

        x: Theme.pkGutter
        width: parent.width - Theme.pkGutter * 2
        height: Math.max(circle.height, whoText.implicitHeight) + Theme.pkIdentityPaddingV * 2

        radius: Theme.pkIdentityRadius
        color: Theme.pkIdentityFill

        Rectangle {
          id: circle

          x: Theme.pkIdentityPaddingH
          anchors.verticalCenter: parent.verticalCenter

          width: Theme.pkIdentityCircle
          height: Theme.pkIdentityCircle
          radius: width / 2
          color: Theme.pkIdentityCircleFill

          Glyph {
            anchors.centerIn: parent

            size: Theme.pkIdentityIcon
            icon: "person"
            iconColor: Theme.accent
            filled: true
          }
        }

        Column {
          id: whoText

          anchors.left: circle.right
          anchors.leftMargin: Theme.pkIdentityGap
          anchors.right: parent.right
          anchors.rightMargin: Theme.pkIdentityPaddingH
          anchors.verticalCenter: parent.verticalCenter

          spacing: Theme.pkIdentityTextGap

          Text {
            width: parent.width

            text: root.who
            color: Theme.text
            font.family: Theme.monoFont
            font.pixelSize: Theme.pkIdentityNameSize
            font.weight: Font.Medium
            elide: Text.ElideRight
          }

          Text {
            width: parent.width

            // the design writes "Superuser · authenticating as root" against its
            // own mock. this says the same thing about whoever polkit offered.
            text: root.identity ? `${root.identity.isGroup ? "Group" : "User"} · authenticating as ${root.who}` : ""
            color: Theme.pkIdentitySub
            font.family: Theme.monoFont
            font.pixelSize: Theme.pkIdentitySubSize
            elide: Text.ElideRight
          }
        }
      }
    }

    // the field, and what pam last said about it
    Item {
      width: parent.width
      height: Theme.pkFieldTop + field.height + Theme.pkFieldGap + Theme.pkNoteHeight

      Rectangle {
        id: field

        x: Theme.pkGutter
        y: Theme.pkFieldTop

        width: parent.width - Theme.pkGutter * 2
        height: Theme.pkFieldHeight
        radius: Theme.pkFieldRadius
        color: Theme.pkFieldFill

        border.width: 1
        border.color: {
          if (root.errored) return Theme.pkFieldBorderError
          if (root.ok) return Theme.pkFieldBorderOk
          return Theme.pkFieldBorder
        }

        Behavior on border.color {
          ColorAnimation { duration: Theme.pkFade }
        }

        Glyph {
          id: keyGlyph

          x: Theme.pkFieldPaddingH
          anchors.verticalCenter: parent.verticalCenter

          size: Theme.pkFieldGlyph
          icon: "key"
          iconColor: Theme.pkFieldGlyphColor
        }

        TextInput {
          id: input

          anchors.left: keyGlyph.right
          anchors.leftMargin: Theme.pkFieldIconGap
          anchors.right: eye.left
          anchors.rightMargin: Theme.pkFieldIconGap
          anchors.verticalCenter: parent.verticalCenter

          focus: true
          enabled: !root.busy && !root.ok
          echoMode: root.echo ? TextInput.Normal : TextInput.Password
          color: Theme.tintBright
          font.family: Theme.monoFont
          font.pixelSize: Theme.pkFieldSize
          font.weight: Font.Medium
          selectByMouse: true

          Component.onCompleted: input.forceActiveFocus()

          Keys.onReturnPressed: root.send()

          // the numpad's enter is a different key.
          Keys.onEnterPressed: root.send()

          Keys.onEscapePressed: root.cancelled()

          cursorDelegate: Rectangle {
            width: 1
            color: Theme.accent
          }

          Text {
            anchors.fill: parent
            visible: input.text.length === 0

            // pam says what it wants. the design hardcodes "Root password".
            text: root.flow?.inputPrompt || "Password"
            color: Theme.pkFieldGlyphColor
            font: input.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }
        }

        Glyph {
          id: eye

          x: field.width - Theme.pkFieldPaddingH - width
          anchors.verticalCenter: parent.verticalCenter

          size: Theme.pkEyeSize
          icon: root.echo ? "visibility_off" : "visibility"
          iconColor: eyeHover.containsMouse ? Theme.pkEyeHover : Theme.pkEye

          MouseArea {
            id: eyeHover

            anchors.fill: parent
            hoverEnabled: true

            onClicked: root.revealed = !root.revealed
          }
        }
      }

      Item {
        id: note

        x: Theme.pkGutter
        y: field.y + field.height + Theme.pkFieldGap

        width: parent.width - Theme.pkGutter * 2
        height: Theme.pkNoteHeight

        readonly property string text: {
          if (root.ok) return "Authenticated"
          if (root.busy) return "Verifying…"
          return root.flow?.supplementaryMessage ?? ""
        }

        readonly property color shade: {
          if (root.ok) return Theme.success
          if (root.errored) return Theme.sysError
          return Theme.pkNoteIdle
        }

        opacity: note.text === "" ? 0 : 1

        Behavior on opacity {
          NumberAnimation { duration: Theme.pkFade }
        }

        Glyph {
          id: noteGlyph

          anchors.verticalCenter: parent.verticalCenter

          size: Theme.pkNoteIcon
          filled: true
          iconColor: note.shade
          icon: {
            if (root.ok) return "check_circle"
            if (root.errored) return "error"
            return "hourglass_top"
          }
        }

        Text {
          anchors.left: noteGlyph.right
          anchors.leftMargin: Theme.pkNoteGap
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter

          text: note.text
          color: note.shade
          font.family: Theme.uiFont
          font.pixelSize: Theme.pkNoteSize
          font.weight: Font.Medium
          elide: Text.ElideRight
        }
      }
    }

    // what is actually being authorised
    Item {
      width: parent.width
      height: Theme.pkDetailsTop + disclosure.height + (root.detailed ? Theme.pkDetailsBoxTop + rows.height : 0)

      Behavior on height {
        NumberAnimation {
          duration: Theme.pkRise
          easing.type: Easing.Bezier
          easing.bezierCurve: Theme.easeStandard
        }
      }

      clip: true

      Item {
        id: disclosure

        x: Theme.pkGutter
        y: Theme.pkDetailsTop

        width: chevron.width + Theme.pkDetailsGap + caption.implicitWidth
        height: Math.max(chevron.height, caption.implicitHeight)

        Glyph {
          id: chevron

          anchors.verticalCenter: parent.verticalCenter

          size: Theme.pkDetailsChevron
          icon: "keyboard_arrow_down"
          iconColor: Theme.pkDetailsCap
          rotation: root.detailed ? 180 : 0

          Behavior on rotation {
            NumberAnimation { duration: Theme.pkRise }
          }
        }

        Caption {
          id: caption

          anchors.left: chevron.right
          anchors.leftMargin: Theme.pkDetailsGap
          anchors.verticalCenter: parent.verticalCenter

          text: "DETAILS"
          color: Theme.pkDetailsCap
          font.pixelSize: Theme.pkDetailsCapSize
        }

        MouseArea {
          anchors.fill: parent

          onClicked: root.detailed = !root.detailed
        }
      }

      Rectangle {
        id: rows

        x: Theme.pkGutter
        y: disclosure.y + disclosure.height + Theme.pkDetailsBoxTop

        width: parent.width - Theme.pkGutter * 2
        height: rowsColumn.implicitHeight + Theme.pkDetailsBoxPaddingV * 2

        radius: Theme.pkDetailsBoxRadius
        color: Theme.pkDetailsFill

        Column {
          id: rowsColumn

          x: Theme.pkDetailsBoxPaddingH
          y: Theme.pkDetailsBoxPaddingV

          width: rows.width - Theme.pkDetailsBoxPaddingH * 2
          spacing: Theme.pkDetailsRowGap

          // the design also lists COMMAND, PROGRAM, VENDOR and PID. polkit hands
          // those to the agent in a details map that AuthFlow does not expose, so
          // the block shows what is actually known rather than inventing the rest.
          Repeater {
            model: [
              { key: "ACTION", value: root.flow?.actionId ?? "" },
              { key: "COOKIE", value: root.flow?.cookie ?? "" }
            ]

            Item {
              required property var modelData

              width: rowsColumn.width
              height: Math.max(rowKey.implicitHeight, rowValue.implicitHeight)

              Text {
                id: rowKey

                width: Theme.pkDetailsKeyWidth

                text: modelData.key
                color: Theme.pkDetailsKey
                font.family: Theme.monoFont
                font.pixelSize: Theme.pkDetailsKeySize
                font.weight: Font.Medium
                font.letterSpacing: Theme.pkDetailsKeySpacing
                lineHeight: Theme.pkDetailsLine
                lineHeightMode: Text.FixedHeight
              }

              Text {
                id: rowValue

                anchors.left: rowKey.right
                anchors.leftMargin: Theme.pkDetailsColGap
                anchors.right: parent.right

                text: modelData.value
                color: Theme.pkDetailsValue
                font.family: Theme.monoFont
                font.pixelSize: Theme.pkDetailsValueSize
                lineHeight: Theme.pkDetailsLine
                lineHeightMode: Text.FixedHeight
                wrapMode: Text.WrapAnywhere
              }
            }
          }
        }
      }
    }

    // cancel, and go
    Item {
      width: parent.width
      height: Theme.pkButtonsTop + cancel.height + Theme.pkButtonsBottom

      readonly property real cell: (parent.width - Theme.pkGutter * 2 - Theme.pkButtonsGap) / 2

      Rectangle {
        id: cancel

        x: Theme.pkGutter
        y: Theme.pkButtonsTop

        width: parent.cell
        height: cancelLabel.implicitHeight + Theme.pkButtonPaddingV * 2
        radius: Theme.pkButtonRadius
        color: cancelHover.containsMouse ? Theme.pkCancelHover : Theme.pkCancelFill

        Behavior on color {
          ColorAnimation { duration: Theme.pkFade }
        }

        Text {
          id: cancelLabel

          anchors.centerIn: parent

          text: "Cancel"
          color: Theme.pkCancelText
          font.family: Theme.uiFont
          font.pixelSize: Theme.pkButtonSize
          font.variableAxes: Theme.uiAxesSemiBold
        }

        MouseArea {
          id: cancelHover

          anchors.fill: parent
          hoverEnabled: true

          onClicked: root.cancelled()
        }
      }

      Rectangle {
        id: confirm

        x: cancel.x + cancel.width + Theme.pkButtonsGap
        y: Theme.pkButtonsTop

        width: parent.cell
        height: cancel.height
        radius: Theme.pkButtonRadius
        color: root.ok ? Theme.pkDoneFill : Theme.accent

        Behavior on color {
          ColorAnimation { duration: Theme.pkFade }
        }

        Text {
          anchors.centerIn: parent

          text: root.ok ? "Authenticated" : "Authenticate"
          color: root.ok ? Theme.success : Theme.litText
          font.family: Theme.uiFont
          font.pixelSize: Theme.pkButtonSize
          font.variableAxes: Theme.uiAxesSemiBold
        }

        MouseArea {
          anchors.fill: parent

          onClicked: root.send()
        }
      }
    }
  }
}
