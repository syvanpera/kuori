import QtQuick
import qs.components
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
    root.submitted(field.text)
    field.text = ""
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
          font.variableAxes: Theme.uiAxesRegular
          font.pixelSize: Theme.pkMessageSize
          lineHeight: Theme.pkMessageLine
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

      SecretField {
        id: field

        x: Theme.pkGutter
        y: Theme.pkFieldTop
        width: parent.width - Theme.pkGutter * 2

        inputFocus: true
        revealed: root.echo
        busy: root.busy
        errored: root.errored
        ok: root.ok

        // pam says what it wants. the design hardcodes "Root password".
        placeholder: root.flow?.inputPrompt || "Password"

        Component.onCompleted: field.take()

        onAccepted: root.send()
        onEscaped: root.cancelled()
        onRevealToggled: root.revealed = !root.revealed
      }

      StatusNote {
        id: note

        x: Theme.pkGutter
        y: field.y + field.height + Theme.pkFieldGap
        width: parent.width - Theme.pkGutter * 2

        text: {
          if (root.ok) return "Authenticated"
          if (root.busy) return "Verifying…"
          return root.flow?.supplementaryMessage ?? ""
        }
        shade: {
          if (root.ok) return Theme.success
          if (root.errored) return Theme.sysError
          return Theme.pkNoteIdle
        }
        icon: {
          if (root.ok) return "check_circle"
          if (root.errored) return "error"
          return "hourglass_top"
        }

        opacity: note.text === "" ? 0 : 1

        Behavior on opacity {
          NumberAnimation { duration: Theme.pkFade }
        }
      }
    }

    // what is actually being authorised. the design also lists COMMAND, PROGRAM,
    // VENDOR and PID; polkit hands those to the agent in a details map that
    // AuthFlow does not expose, so the block shows what is actually known rather
    // than inventing the rest.
    PolkitDetails {
      width: parent.width

      rows: [
        { key: "ACTION", value: root.flow?.actionId ?? "" },
        { key: "COOKIE", value: root.flow?.cookie ?? "" }
      ]
    }

    // cancel, and go
    Item {
      width: parent.width
      height: Theme.pkButtonsTop + cancel.height + Theme.pkButtonsBottom

      readonly property real cell: (parent.width - Theme.pkGutter * 2 - Theme.pkButtonsGap) / 2

      PillButton {
        id: cancel

        x: Theme.pkGutter
        y: Theme.pkButtonsTop
        width: parent.cell

        label: "Cancel"
        fill: Theme.pkCancelFill
        hoverFill: Theme.pkCancelHover
        textColor: Theme.pkCancelText
        textSize: Theme.pkButtonSize
        paddingV: Theme.pkButtonPaddingV
        radius: Theme.pkButtonRadius
        fade: Theme.pkFade

        onClicked: root.cancelled()
      }

      PillButton {
        x: cancel.x + cancel.width + Theme.pkButtonsGap
        y: Theme.pkButtonsTop
        width: parent.cell
        height: cancel.height

        label: root.ok ? "Authenticated" : "Authenticate"
        fill: root.ok ? Theme.pkDoneFill : Theme.accent
        textColor: root.ok ? Theme.success : Theme.litText
        textSize: Theme.pkButtonSize
        radius: Theme.pkButtonRadius
        fade: Theme.pkFade

        onClicked: root.send()
      }
    }
  }
}
