import QtQuick
import qs.theme

// the strip that marks the focused window: a bar the width of the window, sitting
// in the gap above it. pill ended, because the window under it is rounded and
// square ends against a rounded corner read as a mistake.
Rectangle {
  id: root

  height: Theme.focusStripThickness
  radius: height / 2
  color: Theme.focusColor
  antialiasing: true
}
