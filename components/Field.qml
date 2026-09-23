import QtQuick
import qs.theme

// a TextInput with the design's accent caret and a placeholder, which is every
// text field the shell has: the launcher's query, a wifi passphrase, a bluetooth
// pin and the password under the lock and the polkit card.
TextInput {
  id: root

  property string placeholder: ""
  property color placeholderColor: Theme.launcherDimText

  // whether the caret is drawn at all while the field has focus. the lock hides it
  // while pam is thinking, so a field that cannot be typed into does not blink as
  // though it could.
  property bool caretShown: true

  // TextInput paints its caret in the text colour, and a delegate is the only way
  // to get the design's accent caret.
  cursorDelegate: Rectangle {
    width: 1
    color: Theme.accent
    visible: root.cursorVisible && root.caretShown
  }

  Text {
    anchors.fill: parent
    visible: root.text.length === 0

    text: root.placeholder
    color: root.placeholderColor
    font: root.font
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }
}
