import QtQuick
import qs.components
import qs.services
import qs.theme

// the centre tab's strip: the time, and the date peeking out underneath it while
// the tab is hovered. the peek is the whole reason this tab's panel opens on a
// click instead: glancing at the date should not put a calendar on the screen.
Column {
  id: root

  // driven by the tab, which is the thing that knows about the pointer.
  property bool peeking: false

  // as wide as the date whether or not it is showing. a positioner skips a child of
  // zero height, so a column left to measure itself was only as wide as the time
  // until the date peeked, and the tab grew sideways as well as down.
  width: Math.max(time.implicitWidth, date.implicitWidth)

  Text {
    id: time

    anchors.horizontalCenter: parent.horizontalCenter

    text: Qt.formatDateTime(Time.date, "hh:mm")
    color: Theme.text
    font.family: Theme.monoFont
    font.pixelSize: Theme.clockSize
    font.weight: Font.Medium
    font.letterSpacing: Theme.clockLetterSpacing
  }

  Item {
    width: 1
    height: root.peeking ? Theme.clockPeekGap : 0

    Behavior on height {
      Glide { duration: Theme.notchExpandDuration }
    }
  }

  Text {
    id: date

    anchors.horizontalCenter: parent.horizontalCenter

    // clipped to nothing rather than hidden, so the strip's height follows it out
    // and the tab grows to make room instead of the date overflowing the band.
    height: root.peeking ? Theme.clockPeekHeight : 0
    clip: true
    opacity: root.peeking ? 1 : 0

    text: Qt.formatDateTime(Time.date, "ddd d MMM")
    verticalAlignment: Text.AlignVCenter
    color: Theme.textDim
    font.family: Theme.uiFont
    font.pixelSize: Theme.clockPeekSize
    font.variableAxes: Theme.uiAxesMedium
    font.letterSpacing: Theme.clockPeekSpacing

    Behavior on height {
      Glide { duration: Theme.notchExpandDuration }
    }

    Behavior on opacity {
      NumberAnimation { duration: Theme.notchFadeDuration }
    }
  }
}
