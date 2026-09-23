import QtQuick
import qs.components
import qs.services
import qs.theme

// what is on the day the clock panel is showing: the design's header row, then a
// row per event with its time in its calendar's colour, flush with the header's
// icon rather than indented under its text -- the design widened them to give
// titles room -- and the legend of calendars under the lot.
Column {
  id: root

  property string title: ""
  property var events: []
  property string emptyText: ""

  spacing: Theme.eventRowGap

  Row {
    spacing: Theme.eventGap

    Glyph {
      anchors.verticalCenter: parent.verticalCenter

      icon: "calendar_month"
      iconColor: Theme.accent
      size: Theme.eventIcon
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter

      text: root.title
      color: Theme.text
      font.family: Theme.uiFont
      font.pixelSize: Theme.eventTitleSize
      font.variableAxes: Theme.uiAxesSemiBold
    }
  }

  Text {
    visible: root.events.length === 0

    text: root.emptyText
    color: Theme.eventEmptyText
    font.family: Theme.uiFont
    font.variableAxes: Theme.uiAxesRegular
    font.pixelSize: Theme.eventDetailSize
  }

  Repeater {
    model: root.events.slice(0, Theme.eventMax)

    Row {
      id: eventRow

      required property var modelData

      spacing: Theme.eventBarGap

      // the calendar's colour, as a bar the height of the row.
      Rectangle {
        width: Theme.eventBarWidth
        height: Theme.eventLineHeight
        radius: width / 2
        color: Calendar.colorOf(eventRow.modelData.calendar)
      }

      // the design's 32px column fits "09:30"; an all-day event has no time
      // and gets a dash in the same colour rather than a word that would not.
      Text {
        width: Theme.eventTimeWidth
        height: Theme.eventLineHeight

        // a dash for no start time today: an all-day event, or one that began
        // on an earlier day and is still running.
        text: eventRow.modelData.allDay || eventRow.modelData.continued ? "—" : Qt.formatTime(new Date(eventRow.modelData.start), "hh:mm")
        verticalAlignment: Text.AlignVCenter
        color: Calendar.colorOf(eventRow.modelData.calendar)
        font.family: Theme.monoFont
        font.pixelSize: Theme.eventTimeSize
        font.weight: Font.Medium
      }

      Text {
        width: root.width - Theme.eventBarWidth - Theme.eventTimeWidth - eventRow.spacing * 2
        height: Theme.eventLineHeight

        text: eventRow.modelData.title
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        color: Theme.eventText
        font.family: Theme.uiFont
        font.variableAxes: Theme.uiAxesRegular
        font.pixelSize: Theme.eventDetailSize
      }
    }
  }

  Text {
    visible: root.events.length > Theme.eventMax

    text: `+${root.events.length - Theme.eventMax} more`
    color: Theme.eventEmptyText
    font.family: Theme.uiFont
    font.variableAxes: Theme.uiAxesRegular
    font.pixelSize: Theme.eventDetailSize
  }

  // which colour is which: every calendar the file knows, wrapping as it must.
  // a Flow has one spacing for both axes and the design wants 11 across and 4
  // down, so each item carries the row gap under it and this wrapper takes the
  // last one back off, plus the 3 the design puts above the whole legend.
  Item {
    width: root.width
    height: legend.implicitHeight + Theme.legendTop - Theme.legendRowGap
    visible: Calendar.list.length > 0

    Flow {
      id: legend

      y: Theme.legendTop
      width: root.width
      spacing: Theme.legendItemGap

      Repeater {
        model: Calendar.list

        Row {
          id: legendItem

          required property var modelData

          bottomPadding: Theme.legendRowGap
          spacing: Theme.legendDotGap

          Rectangle {
            anchors.verticalCenter: name.verticalCenter

            width: Theme.legendDot
            height: Theme.legendDot
            radius: width / 2
            color: legendItem.modelData.color
          }

          Text {
            id: name

            text: legendItem.modelData.name
            color: Theme.legendText
            font.family: Theme.uiFont
            font.pixelSize: Theme.legendSize
            font.variableAxes: Theme.uiAxesMedium
            font.letterSpacing: Theme.legendSpacing
          }
        }
      }
    }
  }
}
