import QtQuick
import qs.components
import qs.services
import qs.theme

// one line of the history: a dot of colour for how urgent it was, who sent it,
// how long ago, and what it said.
Rectangle {
  id: root

  required property var entry

  readonly property color accent: Notifications.urgencyColour(root.entry?.urgency ?? -1)

  implicitHeight: body.implicitHeight + Theme.notifEntryPaddingV * 2

  radius: Theme.notifEntryRadius
  color: hover.containsMouse ? Theme.notifEntryHover : "transparent"

  Behavior on color {
    ColorAnimation { duration: Theme.notchFadeDuration }
  }

  Row {
    id: body

    x: Theme.notifEntryPaddingH
    y: Theme.notifEntryPaddingV
    width: parent.width - Theme.notifEntryPaddingH * 2

    spacing: Theme.sysBodyGap

    // the design's glyph rather than the sender's own icon, which the toast does
    // show. at fourteen pixels an application icon is mush, and the colour is
    // carrying the only thing worth knowing at this size.
    Glyph {
      icon: "notifications"
      iconColor: root.accent
      size: Theme.notifEntryGlyph
    }

    Column {
      width: parent.width - Theme.notifEntryGlyph - Theme.sysBodyGap
      spacing: Theme.notifEntryTextGap

      Item {
        width: parent.width
        height: Math.max(app.implicitHeight, when.implicitHeight)

        Text {
          id: app

          anchors.left: parent.left
          anchors.right: when.left
          anchors.rightMargin: Theme.sysBodyGap
          anchors.baseline: when.baseline

          text: root.entry?.app ?? ""
          elide: Text.ElideRight
          color: Theme.tintBright
          font.family: Theme.monoFont
          font.pixelSize: Theme.notifAppSize
          font.weight: Font.Medium
        }

        Text {
          id: when

          anchors.right: parent.right

          text: Time.ago(root.entry?.at ?? 0, Time.date)
          color: Theme.toastTime
          font.family: Theme.monoFont
          font.pixelSize: Theme.notifTimeSize
        }
      }

      Text {
        width: parent.width

        text: root.entry?.text ?? ""
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        color: Theme.notifBody
        font.family: Theme.uiFont
        font.pixelSize: Theme.notifBodySize
        lineHeight: Theme.notifBodyLine
        lineHeightMode: Text.FixedHeight
      }
    }
  }

  MouseArea {
    id: hover

    anchors.fill: parent
    hoverEnabled: true

    onClicked: Notifications.forget(root.entry?.key ?? -1)
  }
}
