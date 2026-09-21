import QtQuick
import qs.components
import qs.theme

// the card the design puts in front of a power action: what is about to happen,
// the command that will do it, and two ways out. it is handed a launcher row and
// reads the same three fields every row has, so anything the shell ever wants to
// ask about can be confirmed the same way.
Rectangle {
  id: root

  required property var action

  signal accepted()
  signal rejected()

  width: Theme.pkWidth
  implicitHeight: layout.implicitHeight + Theme.cfPaddingTop + Theme.cfPaddingBottom

  radius: Theme.notchRadius
  color: Theme.notch

  // the same hairline the polkit card carries, for the same reason: at this size
  // the shadow alone leaves the card's edge indistinct against a dimmed desktop.
  border.width: 1
  border.color: Theme.pkOutline

  Column {
    id: layout

    y: Theme.cfPaddingTop
    width: parent.width - Theme.cfPaddingH * 2
    x: Theme.cfPaddingH

    spacing: Theme.cfGap

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter

      width: Theme.cfChipSize
      height: Theme.cfChipSize
      radius: Theme.cfChipRadius
      color: Theme.cfChipFill

      Glyph {
        anchors.centerIn: parent

        // the row's own glyph rather than one picked here: the question is about
        // that row, and it should look like it.
        icon: root.action?.glyph ?? "power_settings_new"
        iconColor: Theme.accent
        size: Theme.cfChipIcon
      }
    }

    Column {
      width: parent.width
      spacing: Theme.cfTitleGap

      Text {
        width: parent.width

        // "Power off?" -- the design builds the question out of the row's name,
        // so a row added later asks about itself without a string written here.
        text: `${root.action?.name ?? ""}?`
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        color: Theme.tintBright
        font.family: Theme.uiFont
        font.pixelSize: Theme.cfTitleSize
        font.weight: Font.Bold
        font.variableAxes: Theme.uiAxesBold
      }

      Text {
        width: parent.width

        text: root.action?.detail ?? ""
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        color: Theme.cfExecText
        font.family: Theme.monoFont
        font.pixelSize: Theme.cfExecSize
      }
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      topPadding: Theme.cfButtonsTop
      spacing: Theme.cfButtonsGap

      Rectangle {
        id: cancel

        width: cancelLabel.implicitWidth + Theme.cfButtonPaddingH * 2
        height: cancelLabel.implicitHeight + Theme.cfButtonPaddingV * 2

        // a pill is its own height, not a number: the design writes 999 for the
        // radius, which is css for "as round as it goes".
        radius: height / 2
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
          font.pixelSize: Theme.cfButtonSize
          font.variableAxes: Theme.uiAxesSemiBold
        }

        MouseArea {
          id: cancelHover

          anchors.fill: parent
          hoverEnabled: true

          onClicked: root.rejected()
        }
      }

      Rectangle {
        width: confirmLabel.implicitWidth + Theme.cfButtonPaddingH * 2
        height: confirmLabel.implicitHeight + Theme.cfButtonPaddingV * 2
        radius: height / 2
        color: confirmHover.containsMouse ? Theme.accentLift : Theme.accent

        Behavior on color {
          ColorAnimation { duration: Theme.pkFade }
        }

        Text {
          id: confirmLabel

          anchors.centerIn: parent

          // the action's own name, so the button says what it will do rather than
          // "OK". the last thing read before a machine turns off should be the
          // words "Power off".
          text: root.action?.name ?? ""
          color: Theme.litText
          font.family: Theme.uiFont
          font.pixelSize: Theme.cfButtonSize
          font.variableAxes: Theme.uiAxesSemiBold
        }

        MouseArea {
          id: confirmHover

          anchors.fill: parent
          hoverEnabled: true

          onClicked: root.accepted()
        }
      }
    }

    Text {
      width: parent.width

      text: "ESC to cancel · ENTER to confirm"
      horizontalAlignment: Text.AlignHCenter
      color: Theme.cfHintText
      font.family: Theme.monoFont
      font.pixelSize: Theme.cfHintSize
      font.letterSpacing: Theme.cfHintSpacing
    }
  }
}
