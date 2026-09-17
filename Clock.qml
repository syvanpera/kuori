import Quickshell
import QtQuick

Text {
  text: Qt.formatDateTime(clock.date, "hh:mm")
  color: "#a9b1d6"

  font {
    family: "SFProDisplay Nerd Font"
    pixelSize: 13
    weight: 600
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
