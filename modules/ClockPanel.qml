import QtQuick
import qs.components
import qs.services
import qs.theme

// what the clock tab becomes while hovered: the time large, the date under it, a
// month you can page through, and what is on today.
Column {
  id: root

  readonly property date now: Time.date

  readonly property bool offMonth: root.monthOffset !== 0
  readonly property color dateColor: root.offMonth ? Theme.accent : Theme.clockDateText

  // which month the grid is showing, as a count from this one. reset when the tab
  // closes, so it always opens on the current month rather than wherever it was
  // left the last time.
  property int monthOffset: 0

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
  onEnabledChanged: if (!root.enabled) root.monthOffset = 0

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

            width: root.dayWidth
            height: Theme.calCellHeight
            radius: Theme.calCellRadius
            color: cell.today ? Theme.accent : "transparent"

            Text {
              anchors.centerIn: parent

              text: cell.modelData ?? ""
              color: cell.today ? Theme.litText : Theme.calDayText
              font.family: Theme.monoFont
              font.pixelSize: Theme.calDaySize
              font.weight: Font.Medium
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

  // what is on today. static until something on this machine keeps a calendar:
  // there is no khal, no vdirsyncer, no evolution store, so "no events" is not a
  // placeholder here, it is the answer.
  Row {
    spacing: Theme.eventGap

    Glyph {
      anchors.verticalCenter: parent.verticalCenter

      icon: "calendar_month"
      iconColor: Theme.accent
      size: Theme.eventIcon
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Text {
        text: "Today"
        color: Theme.text
        font.family: Theme.uiFont
        font.pixelSize: Theme.eventTitleSize
        font.weight: Font.DemiBold
        font.variableAxes: Theme.uiAxesSemiBold
      }

      Text {
        text: "No events"
        color: Theme.eventEmptyText
        font.family: Theme.uiFont
        font.pixelSize: Theme.eventDetailSize
      }
    }
  }
}
