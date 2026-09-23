import QtQuick
import qs.components
import qs.theme

// the polkit card's DETAILS: a disclosure that folds open onto a table of what
// is actually being authorised.
Item {
  id: root

  // [{ key, value }], one line of the table each.
  property var rows: []

  // folded shut when the card appears. the card is rebuilt for every request, so
  // this never carries over from the last one.
  property bool open: false

  height: Theme.pkDetailsTop + disclosure.height + (root.open ? Theme.pkDetailsBoxTop + table.height : 0)

  Behavior on height {
    Glide { duration: Theme.pkRise }
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
      rotation: root.open ? 180 : 0

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

      onClicked: root.open = !root.open
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

      width: table.width - Theme.pkDetailsBoxPaddingH * 2
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
