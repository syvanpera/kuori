import QtQuick
import qs.services
import qs.theme

// the centre tab: the only text on the frame.
Text {
  id: root

  text: Qt.formatDateTime(Time.date, "hh:mm")
  color: Theme.text
  font.family: Theme.monoFont
  font.pixelSize: Theme.clockSize
  font.weight: Font.Medium
  font.letterSpacing: Theme.clockLetterSpacing
}
