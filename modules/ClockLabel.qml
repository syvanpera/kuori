import QtQuick
import Quickshell
import qs.theme

// the centre tab: the only text on the frame.
Text {
  id: root

  text: Qt.formatDateTime(clock.date, "hh:mm")
  color: Theme.text
  font.family: Theme.monoFont
  font.pixelSize: Theme.clockSize
  font.weight: Font.Medium
  font.letterSpacing: Theme.clockLetterSpacing

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
