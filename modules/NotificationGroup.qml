import QtQuick
import qs.components
import qs.services
import qs.theme

// one sender's share of the history: a dot of colour for how urgent it was, who
// sent it, how many and how long ago, and the newest thing it said. a group of
// more than one folds open on a click to show the rest, each with its own age,
// and the cross throws the whole group away.
Rectangle {
  id: root

  required property var group

  readonly property var items: root.group?.items ?? []
  readonly property bool multi: root.items.length > 1
  readonly property bool open: root.multi && (Notifications.expanded[root.group?.id ?? ""] ?? false)

  // the first message is under the header's own age, so only the ones after it
  // carry theirs.
  readonly property var shown: root.open ? root.items : root.items.slice(0, 1)

  readonly property int textX: Theme.notifEntryPaddingH + Theme.notifEntryGlyph + Theme.sysBodyGap

  implicitHeight: rows.y + rows.implicitHeight + Theme.notifRowsBottom

  radius: Theme.notifEntryRadius
  color: root.open ? Theme.notifGroupOpen : "transparent"

  Behavior on color {
    ColorAnimation { duration: Theme.notchFadeDuration }
  }

  // the header's click, under everything else in it so the cross can take its
  // own. a single message has nothing to fold, and the design gives it no click.
  MouseArea {
    width: parent.width
    height: rows.y

    enabled: root.multi

    onClicked: Notifications.toggleGroup(root.group.id)
  }

  // the design's glyph rather than the sender's own icon, which the toast does
  // show. at fourteen pixels an application icon is mush, and the colour is
  // carrying the only thing worth knowing at this size.
  Glyph {
    x: Theme.notifEntryPaddingH
    y: Theme.notifEntryPaddingV + Theme.notifHeadGlyphDrop

    icon: "notifications"
    iconColor: Notifications.groupColour(root.items)
    size: Theme.notifEntryGlyph
  }

  Item {
    id: header

    x: root.textX
    y: Theme.notifEntryPaddingV
    width: parent.width - root.textX - Theme.notifEntryPaddingH
    height: Theme.notifHeadHeight

    Row {
      id: trailing

      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      spacing: Theme.notifHeadGap

      Text {
        anchors.verticalCenter: parent.verticalCenter

        text: Time.ago(root.items[0]?.at ?? 0, Time.date)
        color: Theme.toastTime
        font.family: Theme.monoFont
        font.pixelSize: Theme.notifTimeSize
      }

      Glyph {
        anchors.verticalCenter: parent.verticalCenter

        visible: root.multi
        icon: "keyboard_arrow_down"
        iconColor: Theme.notifChevron
        size: Theme.notifChevronSize
        rotation: root.open ? 180 : 0

        Behavior on rotation {
          NumberAnimation { duration: Theme.controlMoveDuration }
        }
      }

      Glyph {
        anchors.verticalCenter: parent.verticalCenter

        icon: "close"
        iconColor: closeHover.containsMouse ? Theme.notifCloseHover : Theme.notifClose
        size: Theme.notifCloseSize

        MouseArea {
          id: closeHover

          anchors.fill: parent
          hoverEnabled: true

          onClicked: Notifications.forgetGroup(root.group.id)
        }
      }
    }

    // the name and its count are one run from the left, and the name is what
    // gives way when they meet the time.
    Row {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      width: trailing.x - Theme.notifHeadGap
      spacing: Theme.notifHeadGap

      Text {
        id: app

        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(app.implicitWidth, parent.width - (count.visible ? count.width + parent.spacing : 0))

        text: root.group?.app ?? ""
        elide: Text.ElideRight
        color: Theme.tintBright
        font.family: Theme.monoFont
        font.pixelSize: Theme.notifAppSize
        font.weight: Font.Medium
      }

      Rectangle {
        id: count

        anchors.verticalCenter: parent.verticalCenter

        visible: root.multi
        width: countText.implicitWidth + Theme.notifCountPaddingH * 2
        height: countText.implicitHeight + Theme.notifCountPaddingV * 2
        radius: height / 2
        color: Theme.notifCountFill

        Text {
          id: countText

          anchors.centerIn: parent

          text: root.items.length
          color: Theme.notifCountText
          font.family: Theme.monoFont
          font.pixelSize: Theme.notifCountSize
          font.weight: Font.Medium
        }
      }
    }
  }

  Column {
    id: rows

    x: root.textX
    y: header.y + Math.max(header.height, Theme.notifEntryGlyph + Theme.notifHeadGlyphDrop) + Theme.notifRowsTop
    width: header.width

    spacing: Theme.notifRowGap

    Repeater {
      model: root.shown

      Item {
        id: line

        required property var modelData
        required property int index

        readonly property bool timed: root.open && line.index > 0

        width: rows.width
        height: body.implicitHeight

        Text {
          id: body

          width: parent.width - (line.timed ? age.implicitWidth + Theme.notifRowTimeGap : 0)

          text: line.modelData.text
          textFormat: Text.StyledText
          wrapMode: Text.Wrap
          color: Theme.notifBody
          font.family: Theme.uiFont
          font.variableAxes: Theme.uiAxesRegular
          font.pixelSize: Theme.notifBodySize
          lineHeight: Theme.notifBodyLine
          lineHeightMode: Text.FixedHeight
        }

        Text {
          id: age

          anchors.right: parent.right
          anchors.baseline: body.baseline

          visible: line.timed
          text: Time.ago(line.modelData.at, Time.date)
          color: Theme.notifRowTime
          font.family: Theme.monoFont
          font.pixelSize: Theme.notifTimeSize
        }
      }
    }

    Text {
      visible: root.multi && !root.open

      text: `+${root.items.length - 1} more`
      color: Theme.notifMore
      font.family: Theme.monoFont
      font.pixelSize: Theme.notifMoreSize
      font.weight: Font.Medium
      font.letterSpacing: Theme.notifMoreSpacing

      MouseArea {
        anchors.fill: parent

        onClicked: Notifications.toggleGroup(root.group.id)
      }
    }
  }
}
