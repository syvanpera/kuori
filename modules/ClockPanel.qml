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

  // the month being shown, counted in months since year zero. an int on purpose:
  // the clock ticks every minute, and a binding that took the month straight off
  // a new Date would hand the grid a new month -- and a rebuilt grid -- on every
  // tick. an int that comes out the same does not notify.
  readonly property int viewMonth: root.now.getFullYear() * 12 + root.now.getMonth() + root.monthOffset

  // and as a date on its first day.
  readonly property date view: new Date(Math.floor(root.viewMonth / 12), root.viewMonth % 12, 1)

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
    height: Theme.clockRuleTop
  }

  Rule {
    width: root.contentWidth
    color: Theme.notchPanelLine
  }

  Item {
    width: root.contentWidth
    height: Theme.calTop
  }

  CalendarGrid {
    width: root.contentWidth

    view: root.view
    today: root.offMonth ? 0 : root.now.getDate()
    shownDay: root.shownDay

    onPaged: delta => root.monthOffset += delta
    onPicked: day => root.selectedDay = day
  }

  Item {
    width: root.contentWidth
    height: Theme.calBottom
  }

  Rule {
    width: root.contentWidth
    color: Theme.notchPanelLine
  }

  Item {
    width: root.contentWidth
    height: Theme.eventTop
  }

  EventList {
    width: root.contentWidth

    title: root.shownTitle
    events: root.shownEvents
    emptyText: root.emptyText
  }
}
