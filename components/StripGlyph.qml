import QtQuick
import qs.theme

// a glyph on the system tab's strip that is not there at all until it has
// something to say, and grows out of nothing when it does.
//
// the width is what animates, and `visible` follows it, because a Row still puts
// its spacing either side of a child that has shrunk to nothing -- so one that
// merely went transparent would leave a gap where it used to be.
Item {
  id: root

  property bool shown: false
  property string icon: ""
  property color iconColor: Theme.accent

  // whether a click on it does anything. the toggles here are things the strip can
  // switch off -- night light, stay awake, do not disturb -- but the recording
  // light is only a light, and it must let a click through to the tab underneath
  // rather than swallow it.
  property bool interactive: false

  signal clicked()

  width: root.shown ? Theme.iconSize : 0
  height: Theme.iconSize

  visible: root.width > 0.5
  opacity: root.shown ? 1 : 0
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

  MouseArea {
    anchors.fill: parent

    enabled: root.shown && root.interactive
    visible: enabled

    onClicked: root.clicked()
  }

  Glyph {
    // right-aligned so the glyph slides out of the edge it grew from rather than
    // sliding sideways across the strip.
    anchors.right: parent.right

    icon: root.icon
    iconColor: root.iconColor
  }
}
