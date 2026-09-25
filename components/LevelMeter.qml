import QtQuick
import qs.theme

// a row of segments lit up to a level, with the loudest recent moment held a
// beat above it. the microphone's level under the INPUT slider.
Item {
  id: root

  // 0 to 1, already on a scale that reads right to the eye.
  property real level: 0

  // whether the bar moves. a FrameAnimation keeps qt's animation driver awake,
  // so it only runs while there is something to watch.
  property bool running: visible

  // what is drawn: the level eased toward the reading, and the held peak.
  property real shown: 0
  property real peak: 0
  property real peakUntil: 0
  property real clock: 0

  readonly property int lit: Math.round(Math.min(1, root.shown) * Theme.micMeterSegments)
  readonly property int peakAt: Math.min(Theme.micMeterSegments - 1, Math.round(root.peak * Theme.micMeterSegments) - 1)

  implicitHeight: Theme.micMeterHeight

  onRunningChanged: if (!root.running) root.shown = root.peak = 0

  // the design's own per-frame easing and hold, measured in 60ths of a second
  // so a faster or slower display moves the bar at the same pace.
  FrameAnimation {
    running: root.running

    onTriggered: {
      const frames = Math.min(4, frameTime * 60)
      const target = Math.max(0, root.level)
      const k = target > root.shown ? Theme.micMeterAttack : Theme.micMeterRelease

      root.clock += frameTime * 1000
      root.shown += (target - root.shown) * (1 - Math.pow(1 - k, frames))

      const level = Math.min(1, root.shown)
      if (level >= root.peak || root.clock > root.peakUntil) {
        root.peak = level
        root.peakUntil = root.clock + Theme.micMeterHold
      } else if (root.clock > root.peakUntil - Theme.micMeterFall) {
        root.peak = Math.max(level, root.peak - Theme.micMeterFallStep * frames)
      }
    }
  }

  Row {
    anchors.fill: parent
    spacing: Theme.micMeterGap

    Repeater {
      model: Theme.micMeterSegments

      Rectangle {
        required property int index

        readonly property color tone: index >= Theme.micMeterSegments - Theme.micMeterHot ? Theme.sysError
          : index >= Theme.micMeterSegments - Theme.micMeterWarm ? Theme.elevated
          : Theme.accent

        width: (root.width - Theme.micMeterGap * (Theme.micMeterSegments - 1)) / Theme.micMeterSegments
        height: root.height
        radius: Theme.micMeterRadius
        color: index < root.lit || (index === root.peakAt && root.peakAt > 0) ? tone : Theme.micMeterOff
      }
    }
  }
}
