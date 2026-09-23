import QtQuick
import qs.theme

// the line under a password field: a glyph and a sentence in one shade, saying
// what is happening or what pam said about the last try. the glyph can spin, for
// the time pam spends thinking.
Item {
  id: root

  property string icon: ""
  property string text: ""
  property color shade: Theme.pkNoteIdle
  property bool spinning: false

  // a note that may run to two lines wraps; one that must stay on one elides.
  property bool wraps: false

  // the height of a line of the text, which the glyph is centred on.
  property real line: Theme.pkNoteHeight

  implicitHeight: Math.max(Theme.pkNoteHeight, root.line, caption.implicitHeight)

  Glyph {
    id: glyph

    y: (root.line - glyph.height) / 2

    size: Theme.pkNoteIcon
    filled: true
    icon: root.icon
    iconColor: root.shade

    RotationAnimation on rotation {
      running: root.spinning
      loops: Animation.Infinite
      from: 0
      to: 360
      duration: Theme.noteSpin
      onStopped: glyph.rotation = 0
    }
  }

  Text {
    id: caption

    anchors.left: glyph.right
    anchors.leftMargin: Theme.pkNoteGap
    anchors.right: parent.right

    text: root.text
    color: root.shade
    wrapMode: root.wraps ? Text.Wrap : Text.NoWrap
    elide: root.wraps ? Text.ElideNone : Text.ElideRight
    font.family: Theme.uiFont
    font.pixelSize: Theme.pkNoteSize
    font.variableAxes: Theme.uiAxesMedium
    lineHeightMode: Text.FixedHeight
    lineHeight: root.line
  }
}
