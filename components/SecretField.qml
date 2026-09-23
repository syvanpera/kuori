import QtQuick
import qs.theme

// the password field the lock and the polkit card both draw: a key, the input,
// and an eye that shows what was typed. its border says how the last try went.
//
// it is never disabled, only made read-only. a disabled item gives its focus away
// and nothing takes it back, so the next attempt would need a click on the field
// before anything could be typed into it.
Rectangle {
  id: root

  property alias text: input.text
  property alias inputFocus: input.focus

  // echo what is typed. the eye asks for this through revealToggled rather than
  // setting it, because whose preference it is differs: the lock keeps it across
  // attempts, the polkit card per request.
  property bool revealed: false

  property bool busy: false
  property bool errored: false
  property bool ok: false

  // read-only for a reason of the caller's own, beside being busy or done.
  property bool locked: false

  // whether the eye answers the pointer. the lock's prompt can be on screen and
  // hidden at once, and a hidden eye must not be clickable.
  property bool eyeEnabled: true

  property string placeholder: "Password"

  property color fill: Theme.pkFieldFill
  property color busyBorder: Theme.pkFieldBorder
  property real busyOpacity: 1
  property int fade: Theme.pkFade

  signal accepted()
  signal escaped()
  signal revealToggled()

  // every key, before it is typed. the lock asks about caps lock on each one,
  // because that is the only way to find out.
  signal keyPressed()

  function take(): void {
    input.forceActiveFocus()
  }

  // replace what is in the field and put the caret at its end.
  function setText(text: string): void {
    input.text = text
    input.cursorPosition = text.length
  }

  function shake(): void {
    shaker.restart()
  }

  height: Theme.pkFieldHeight
  radius: Theme.pkFieldRadius
  color: root.fill

  border.width: 1
  border.color: {
    if (root.errored) return Theme.pkFieldBorderError
    if (root.ok) return Theme.pkFieldBorderOk
    if (root.busy) return root.busyBorder
    return Theme.pkFieldBorder
  }

  Behavior on border.color {
    ColorAnimation { duration: root.fade }
  }

  transform: Translate { id: offset }

  Shake {
    id: shaker

    shift: offset
  }

  Glyph {
    id: keyGlyph

    x: Theme.pkFieldPaddingH
    anchors.verticalCenter: parent.verticalCenter

    size: Theme.pkFieldGlyph
    icon: "key"
    iconColor: Theme.pkFieldGlyphColor
  }

  Field {
    id: input

    anchors.left: keyGlyph.right
    anchors.leftMargin: Theme.pkFieldIconGap
    anchors.right: eye.left
    anchors.rightMargin: Theme.pkFieldIconGap
    anchors.verticalCenter: parent.verticalCenter

    readOnly: root.busy || root.ok || root.locked
    echoMode: root.revealed ? TextInput.Normal : TextInput.Password
    color: Theme.tintBright
    opacity: root.busy ? root.busyOpacity : 1
    font.family: Theme.monoFont
    font.pixelSize: Theme.pkFieldSize
    font.weight: Font.Medium
    selectByMouse: true

    // the specific handlers run before Keys.onPressed and accept the key, so each
    // answers for itself. the numpad's enter is a different key from return.
    Keys.onReturnPressed: root.accepted()
    Keys.onEnterPressed: root.accepted()
    Keys.onEscapePressed: root.escaped()

    Keys.onPressed: event => {
      root.keyPressed()
      event.accepted = false
    }

    placeholder: root.placeholder
    placeholderColor: Theme.pkFieldGlyphColor
    caretShown: !root.busy
  }

  Glyph {
    id: eye

    x: root.width - Theme.pkFieldPaddingH - width
    anchors.verticalCenter: parent.verticalCenter

    size: Theme.pkEyeSize
    icon: root.revealed ? "visibility_off" : "visibility"
    iconColor: eyeHover.containsMouse ? Theme.pkEyeHover : Theme.pkEye

    MouseArea {
      id: eyeHover

      anchors.fill: parent
      enabled: root.eyeEnabled
      hoverEnabled: true

      onClicked: {
        root.revealToggled()
        input.forceActiveFocus()
      }
    }
  }
}
