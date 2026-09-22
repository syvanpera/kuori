import QtQuick
import qs.components
import qs.services
import qs.theme

// what the clock tab becomes while open: the time large, the date under it, a
// month you can page through with a dot on every day that has something on, and
// what is on the day you picked -- today, until you pick one.
Column {
  id: root

  readonly property date now: Time.date

  readonly property bool offMonth: root.monthOffset !== 0
  readonly property color dateColor: root.offMonth ? Theme.accent : Theme.clockDateText

  // which month the grid is showing, as a count from this one. reset when the tab
  // closes, so it always opens on the current month rather than wherever it was
  // left the last time.
  property int monthOffset: 0

  // the day whose events are listed, as a number in the month being shown, or 0.
  // only a day with events can be picked, which is the design's rule: a click on
  // an empty day would only ever say "no events" about a day you can already see
  // is empty.
  property int selectedDay: 0

  // the design's resolution: a picked day that still has events, else today while
  // this is the current month, else nothing -- an off-month opens on its name.
  readonly property int shownDay: {
    if (root.selectedDay > 0 && root.eventsOn(root.selectedDay).length > 0) return root.selectedDay
    if (!root.offMonth) return root.now.getDate()

    return 0
  }

  readonly property var shownEvents: root.shownDay > 0 ? root.eventsOn(root.shownDay) : []

  readonly property string shownTitle: {
    if (root.shownDay === 0) return Qt.formatDateTime(root.view, "MMMM yyyy")
    if (root.isToday(root.shownDay)) return "Today"

    return Qt.formatDateTime(root.dateOf(root.shownDay), "dddd d MMM")
  }

  // what stands where the rows would be when there are none. the first two are
  // not in the design, which has a calendar by construction; here "no events" is
  // only true once a file has been read and reaches the month on screen.
  readonly property string emptyText: {
    if (!Calendar.ready) return "Not synced yet"
    if (!Calendar.inWindow(root.view)) return "Not synced this far"

    return "No events"
  }

  // the design fixes the panel's width, and the grid divides what is left of it.
  readonly property real contentWidth: Theme.clockPanelWidth - Theme.clockPanelPaddingH * 2

  // the day cells share out whatever the week column and the gutters leave. real,
  // not int: seven of them have to add back up to the same total.
  readonly property real dayWidth: (root.contentWidth - Theme.calWeekColumn - Theme.calGap * 7) / 7

  // the month being shown, as a date on its first day.
  readonly property date view: new Date(root.now.getFullYear(), root.now.getMonth() + root.monthOffset, 1)

  // one entry per week: its iso number, and seven day numbers with nulls for the
  // days that belong to the neighbouring months.
  readonly property var weeks: {
    const year = root.view.getFullYear()
    const month = root.view.getMonth()

    // getDay() counts from sunday and the design's grid starts on monday.
    const lead = (new Date(year, month, 1).getDay() + 6) % 7

    // day zero of the next month is the last day of this one.
    const length = new Date(year, month + 1, 0).getDate()

    const days = []
    for (let i = 0; i < lead; i++) days.push(null)
    for (let day = 1; day <= length; day++) days.push(day)
    while (days.length % 7) days.push(null)

    const out = []
    for (let w = 0; w * 7 < days.length; w++) {
      const row = days.slice(w * 7, w * 7 + 7)
      const first = row.find(day => day !== null)

      out.push({ week: first ? root.isoWeek(new Date(year, month, first)) : 0, days: row })
    }

    return out
  }

  leftPadding: Theme.clockPanelPaddingH
  rightPadding: Theme.clockPanelPaddingH
  topPadding: Theme.clockPanelPaddingV
  bottomPadding: Theme.clockPanelPaddingV

  // the loader keeps this alive while the tab is shut, so closing is the only
  // moment there is to put the month back.
  onEnabledChanged: {
    if (root.enabled) return

    root.monthOffset = 0
    root.selectedDay = 0
  }

  // paging the month drops the pick, the way the design does: a "23" carried
  // into another month would be a different day.
  onMonthOffsetChanged: root.selectedDay = 0

  function dateOf(day: int): date {
    return new Date(root.view.getFullYear(), root.view.getMonth(), day)
  }

  function eventsOn(day: int): var {
    return Calendar.eventsOn(root.dateOf(day))
  }

  // iso weeks belong to the year holding their thursday, which is the whole reason
  // this is not just "days since january the first over seven".
  function isoWeek(day: date): int {
    const d = new Date(day.getFullYear(), day.getMonth(), day.getDate())

    d.setDate(d.getDate() + 4 - ((d.getDay() + 6) % 7 + 1))

    const start = new Date(d.getFullYear(), 0, 1)

    return Math.ceil(((d - start) / 86400000 + 1) / 7)
  }

  function isToday(day: int): bool {
    return root.monthOffset === 0 && day === root.now.getDate()
  }

  // the fetcher runs when the tab opens on a stale file, and never while shut.
  Binding {
    target: Calendar
    property: "watching"
    value: root.enabled
  }

  Text {
    width: root.contentWidth

    text: Qt.formatDateTime(root.now, "hh:mm")
    horizontalAlignment: Text.AlignHCenter
    color: Theme.tintBright
    font.family: Theme.monoFont
    font.pixelSize: Theme.clockBigSize
    font.weight: Font.DemiBold
    font.letterSpacing: Theme.clockBigSpacing
  }

  Item {
    width: root.contentWidth
    height: Theme.clockDateGap
  }

  // the date is always today's, never the month being looked at. once the grid has
  // been paged away from now it says so, by going accent and growing an undo arrow,
  // and clicking it comes back.
  Item {
    width: root.contentWidth
    height: dateRow.implicitHeight

    Row {
      id: dateRow

      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Theme.dateUndoGap

      Glyph {
        anchors.verticalCenter: parent.verticalCenter

        icon: "undo"
        iconColor: root.dateColor
        size: Theme.dateUndoSize

        // clipped to nothing rather than hidden, so it slides out of the date's
        // way instead of the line jumping when it appears.
        width: root.offMonth ? Theme.dateUndoSize : 0
        opacity: root.offMonth ? 1 : 0
        clip: true

        Behavior on width {
          NumberAnimation {
            duration: Theme.notchExpandDuration
            easing.type: Easing.Bezier
            easing.bezierCurve: Theme.easeStandard
          }
        }

        Behavior on opacity {
          NumberAnimation { duration: Theme.notchFadeDuration }
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter

        text: Qt.formatDateTime(root.now, "ddd d MMM yyyy")
        color: root.dateColor
        font.family: Theme.uiFont
        font.pixelSize: Theme.clockDateSize
        font.weight: Font.Medium
        font.variableAxes: Theme.uiAxesMedium

        Behavior on color {
          ColorAnimation { duration: Theme.notchFadeDuration }
        }
      }
    }

    MouseArea {
      anchors.fill: dateRow
      enabled: root.offMonth

      onClicked: root.monthOffset = 0
    }
  }

  Item {
    width: root.contentWidth
    height: 12
  }

  Rectangle {
    width: root.contentWidth
    height: 1
    color: Theme.notchPanelLine
  }

  Item {
    width: root.contentWidth
    height: 10
  }

  // the month, and the two arrows that page it.
  Item {
    width: root.contentWidth
    height: Theme.calNavSize

    CalendarNav {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      icon: "chevron_left"
      onClicked: root.monthOffset -= 1
    }

    Text {
      anchors.centerIn: parent

      text: Qt.formatDateTime(root.view, "MMMM yyyy").toUpperCase()
      color: Theme.text
      font.family: Theme.uiFont
      font.pixelSize: Theme.calMonthSize
      font.weight: Font.DemiBold
      font.variableAxes: Theme.uiAxesSemiBold
      font.letterSpacing: Theme.calMonthSpacing
    }

    CalendarNav {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      icon: "chevron_right"
      onClicked: root.monthOffset += 1
    }
  }

  Item {
    width: root.contentWidth
    height: 8
  }

  // the grid. a column of rows rather than a Grid, because the week column is a
  // different width from the seven day columns and laying that out by hand is
  // shorter than teaching a Grid about it.
  Column {
    width: root.contentWidth
    spacing: Theme.calGap

    Row {
      spacing: Theme.calGap

      Text {
        width: Theme.calWeekColumn
        height: Theme.calHeadHeight

        text: "WK"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: Theme.calWeekHeadText
        font.family: Theme.monoFont
        font.pixelSize: Theme.calHeadSize
        font.weight: Font.Medium
      }

      Repeater {
        model: ["M", "T", "W", "T", "F", "S", "S"]

        Text {
          required property var modelData

          width: root.dayWidth
          height: Theme.calHeadHeight

          text: modelData
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          color: Theme.calHeadText
          font.family: Theme.monoFont
          font.pixelSize: Theme.calHeadSize
          font.weight: Font.Medium
        }
      }
    }

    Repeater {
      model: root.weeks

      Row {
        required property var modelData

        spacing: Theme.calGap

        Text {
          width: Theme.calWeekColumn
          height: Theme.calCellHeight

          text: parent.modelData.week
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          color: Theme.calWeekText
          font.family: Theme.monoFont
          font.pixelSize: Theme.calHeadSize
          font.weight: Font.Medium
        }

        Repeater {
          model: parent.modelData.days

          Rectangle {
            id: cell

            required property var modelData

            readonly property bool today: cell.modelData !== null && root.isToday(cell.modelData)
            readonly property var events: cell.modelData !== null ? root.eventsOn(cell.modelData) : []
            readonly property var calendars: cell.modelData !== null ? Calendar.calendarsOn(root.dateOf(cell.modelData)) : []
            readonly property bool busy: cell.events.length > 0

            // today is already lit, so the pick only shows on any other day.
            readonly property bool selected: cell.busy && !cell.today && cell.modelData === root.shownDay

            width: root.dayWidth
            height: Theme.calCellHeight
            radius: Theme.calCellRadius
            color: cell.today ? Theme.accent : cell.selected ? Theme.calSelectedBg : "transparent"

            Behavior on color {
              ColorAnimation { duration: Theme.notchFadeDuration }
            }

            Column {
              anchors.centerIn: parent
              spacing: Theme.calDotGap

              Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: cell.modelData ?? ""
                color: cell.today ? Theme.litText : cell.selected ? Theme.text : Theme.calDayText
                font.family: Theme.monoFont
                font.pixelSize: Theme.calDaySize
                font.weight: Font.Medium
              }

              // a dot per calendar with something on, in its colour; on today's lit
              // cell they all go dark like the number. the row keeps its height
              // with nothing in it, so an empty day's number sits where a busy
              // day's does.
              Row {
                anchors.horizontalCenter: parent.horizontalCenter

                height: Theme.calDotSize
                spacing: Theme.calDotSpacing

                Repeater {
                  model: cell.calendars

                  Rectangle {
                    required property var modelData

                    width: Theme.calDotSize
                    height: Theme.calDotSize
                    radius: width / 2
                    color: cell.today ? Theme.litText : modelData.color
                  }
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              enabled: cell.busy

              onClicked: root.selectedDay = cell.modelData
            }
          }
        }
      }
    }
  }

  Item {
    width: root.contentWidth
    height: 13
  }

  Rectangle {
    width: root.contentWidth
    height: 1
    color: Theme.notchPanelLine
  }

  Item {
    width: root.contentWidth
    height: 11
  }

  // what is on the shown day: the design's header row, then a row per event with
  // its time in its calendar's colour, flush with the header's icon rather than
  // indented under its text -- the design widened them to give titles room.
  Column {
    width: root.contentWidth
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

        text: root.shownTitle
        color: Theme.text
        font.family: Theme.uiFont
        font.pixelSize: Theme.eventTitleSize
        font.weight: Font.DemiBold
        font.variableAxes: Theme.uiAxesSemiBold
      }
    }

    Text {
      visible: root.shownEvents.length === 0

      text: root.emptyText
      color: Theme.eventEmptyText
      font.family: Theme.uiFont
      font.pixelSize: Theme.eventDetailSize
    }

    Repeater {
      model: root.shownEvents.slice(0, Theme.eventMax)

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

          text: eventRow.modelData.allDay ? "—" : Qt.formatTime(new Date(eventRow.modelData.start), "hh:mm")
          verticalAlignment: Text.AlignVCenter
          color: Calendar.colorOf(eventRow.modelData.calendar)
          font.family: Theme.monoFont
          font.pixelSize: Theme.eventTimeSize
          font.weight: Font.Medium
        }

        Text {
          width: root.contentWidth - Theme.eventBarWidth - Theme.eventTimeWidth - eventRow.spacing * 2
          height: Theme.eventLineHeight

          text: eventRow.modelData.title
          elide: Text.ElideRight
          verticalAlignment: Text.AlignVCenter
          color: Theme.eventText
          font.family: Theme.uiFont
          font.pixelSize: Theme.eventDetailSize
        }
      }
    }

    Text {
      visible: root.shownEvents.length > Theme.eventMax

      text: `+${root.shownEvents.length - Theme.eventMax} more`
      color: Theme.eventEmptyText
      font.family: Theme.uiFont
      font.pixelSize: Theme.eventDetailSize
    }

    // which colour is which: every calendar the file knows, wrapping as it must.
    // a Flow has one spacing for both axes and the design wants 11 across and 4
    // down, so each item carries the row gap under it and this wrapper takes the
    // last one back off, plus the 3 the design puts above the whole legend.
    Item {
      width: root.contentWidth
      height: legend.implicitHeight + Theme.legendTop - Theme.legendRowGap
      visible: Calendar.list.length > 0

      Flow {
        id: legend

        y: Theme.legendTop
        width: root.contentWidth
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
              font.weight: Font.Medium
              font.variableAxes: Theme.uiAxesMedium
              font.letterSpacing: Theme.legendSpacing
            }
          }
        }
      }
    }
  }
}
