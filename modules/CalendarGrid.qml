import QtQuick
import qs.components
import qs.services
import qs.theme

// the clock panel's month: its name between two arrows that page it, and the grid
// of weeks under that with a dot per calendar on every day that has something on.
// it reports what was clicked and leaves deciding what that means to the panel.
Column {
  id: root

  // the month being shown, as a date on its first day.
  property date view: new Date()

  // today's number when today is in this month, else 0.
  property int today: 0

  // the day whose events the panel is listing, or 0.
  property int shownDay: 0

  // the day cells share out whatever the week column and the gutters leave. real,
  // not int: seven of them have to add back up to the same total.
  readonly property real dayWidth: (root.width - Theme.calWeekColumn - Theme.calGap * 7) / 7

  readonly property var weeks: Time.monthWeeks(root.view.getFullYear(), root.view.getMonth())

  signal paged(int delta)
  signal picked(int day)

  function dateOf(day: int): date {
    return new Date(root.view.getFullYear(), root.view.getMonth(), day)
  }

  function eventsOn(day: int): var {
    return Calendar.eventsOn(root.dateOf(day))
  }

  // the month, and the two arrows that page it.
  Item {
    width: root.width
    height: Theme.calNavSize

    CalendarNav {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      icon: "chevron_left"
      onClicked: root.paged(-1)
    }

    Text {
      anchors.centerIn: parent

      text: Qt.formatDateTime(root.view, "MMMM yyyy").toUpperCase()
      color: Theme.text
      font.family: Theme.uiFont
      font.pixelSize: Theme.calMonthSize
      font.variableAxes: Theme.uiAxesSemiBold
      font.letterSpacing: Theme.calMonthSpacing
    }

    CalendarNav {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      icon: "chevron_right"
      onClicked: root.paged(1)
    }
  }

  Item {
    width: root.width
    height: Theme.calNavBottom
  }

  // the grid. a column of rows rather than a Grid, because the week column is a
  // different width from the seven day columns and laying that out by hand is
  // shorter than teaching a Grid about it.
  Column {
    width: root.width
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

            readonly property bool today: cell.modelData !== null && cell.modelData === root.today
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

              onClicked: root.picked(cell.modelData)
            }
          }
        }
      }
    }
  }
}
