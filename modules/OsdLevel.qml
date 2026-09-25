import QtQuick
import qs.components
import qs.services
import qs.theme

// the lower half of either display: the level as a bar, or while voice typing the
// microphone's meter in its place, at the bar's height so the display is the same
// size whichever it is showing. the meter goes dark while transcribing: the
// microphone has stopped, and says so.
Item {
  id: root

  // whether the display this is in can be seen, so a hidden meter does no work.
  property bool running: true

  implicitHeight: Theme.osdTrack

  Meter {
    visible: !Osd.voice

    width: parent.width
    height: parent.height
    radius: Theme.osdTrackRadius
    color: Theme.osdRail

    value: Osd.value / 100
    tint: Osd.fill
    fillDuration: Theme.osdFillDuration
  }

  LevelMeter {
    visible: Osd.voice

    width: parent.width
    height: parent.height

    level: Audio.inputLevel
    running: Osd.listening && root.running
  }
}
