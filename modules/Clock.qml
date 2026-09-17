import QtQuick
import Quickshell
import qs.theme
import qs.components

Pill {
  icon: "schedule"
  iconColor: Theme.magenta
  text: Qt.formatDateTime(clock.date, "hh:mm")

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
