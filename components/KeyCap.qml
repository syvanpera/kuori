import QtQuick
import qs.theme

// one keycap: the little ESC, arrow and ENTER chips that label a shortcut. sized
// by its label, the way a notch is sized by its contents.
Rectangle {
  id: root

  property string label: ""

  implicitWidth: text.implicitWidth + Theme.keyCapPaddingH * 2

  // the css line box, not the font's. Text.implicitHeight follows the font's own
  // line spacing, which would leave every cap a couple of pixels too tall.
  implicitHeight: Theme.lineBox(Theme.keyCapSize) + Theme.keyCapPaddingV * 2

  radius: Theme.keyCapRadius
  color: Theme.launcherLine

  Text {
    id: text

    anchors.centerIn: parent

    text: root.label
    color: Theme.launcherKeyText
    font.family: Theme.monoFont
    font.pixelSize: Theme.keyCapSize
    font.weight: Font.Medium
  }
}
