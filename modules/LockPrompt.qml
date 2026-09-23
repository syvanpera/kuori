import QtQuick
import qs.components
import qs.services
import qs.theme

// the lock's prompt: who is locked, the fingerprint line, the password field and
// what pam last said. the surface places it and says whether it is the screen
// with the keyboard; everything else it reads off Lock.
Column {
  id: root

  // this is the screen with the keyboard, and so the one typed into.
  property bool primary: false

  // and the prompt is up rather than hidden under the clock.
  property bool prompting: false

  readonly property bool busy: Lock.status === "busy"
  readonly property bool errored: Lock.status === "error"

  function take(): void {
    field.take()
  }

  function enter(): void {
    if (!Lock.prompt) {
      Lock.prompt = true
      return
    }

    Lock.submit(field.text)
  }

  width: Theme.lockPromptWidth
  spacing: Theme.lockPromptGap

  // never disabled, however hidden: the field in here takes the first key of
  // a password while the prompt is still down, and a disabled item cannot
  // hold focus. only the eye, the one thing to click, is gated.
  opacity: root.prompting ? 1 : 0

  Behavior on opacity {
    NumberAnimation { duration: Theme.lockPromptFade }
  }

  Behavior on y {
    Glide { duration: Theme.lockPromptMove }
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Theme.lockIdentityGap

    Rectangle {
      width: Theme.lockTileSize
      height: Theme.lockTileSize
      radius: Theme.lockTileRadius
      color: Theme.accent

      Text {
        anchors.centerIn: parent

        text: Lock.initial
        color: Theme.litText
        font.family: Theme.uiFont
        font.pixelSize: Theme.lockTileText
        font.variableAxes: Theme.uiAxesSemiBold
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter

      text: Lock.realName
      color: Theme.tintBright
      font.family: Theme.uiFont
      font.pixelSize: Theme.lockNameSize
      font.variableAxes: Theme.uiAxesSemiBold
    }
  }

  Row {
    id: finger

    anchors.horizontalCenter: parent.horizontalCenter
    visible: Lock.fingerReady
    spacing: Theme.lockFingerGap

    readonly property color shade: {
      if (Lock.fingerMissed) return Theme.sysError
      if (Lock.fingerOk) return Theme.accent
      return Theme.lockFingerIdle
    }

    transform: Translate { id: fingerShift }

    Glyph {
      anchors.verticalCenter: parent.verticalCenter

      size: Theme.lockFingerGlyph
      icon: "fingerprint"
      iconColor: finger.shade
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter

      text: {
        if (Lock.fingerMissed) return "Fingerprint not recognised. Try again."
        if (Lock.fingerOk) return "Fingerprint recognised"
        return "Touch the sensor or type your password"
      }
      color: Lock.fingerMissed ? Theme.sysError : Theme.lockFingerText
      font.family: Theme.uiFont
      font.pixelSize: Theme.lockFingerSize
      font.variableAxes: Theme.uiAxesMedium
      lineHeightMode: Text.FixedHeight
      lineHeight: Theme.lockFingerLine
    }

    Shake {
      id: fingerShake

      shift: fingerShift
    }

    Connections {
      target: Lock

      function onFingerMissesChanged(): void {
        fingerShake.restart()
      }
    }
  }

  Column {
    width: parent.width
    spacing: Theme.lockFieldGap

    SecretField {
      id: field

      width: parent.width

      // the field takes every key the lock hears, visible or not: that is how
      // the first key of a password both raises the prompt and is typed.
      inputFocus: root.primary
      locked: Lock.leaving
      revealed: Lock.revealed
      busy: root.busy
      errored: root.errored
      eyeEnabled: root.prompting

      fill: Theme.lockFieldFill
      busyBorder: Theme.lockFieldBusy
      busyOpacity: 0.5
      fade: Theme.notchFadeDuration

      onTextChanged: {
        if (field.text.length === 0) return

        Lock.prompt = true
        if (root.errored) Lock.status = ""
      }

      onEscaped: Lock.rest()
      onAccepted: root.enter()
      onRevealToggled: Lock.revealed = !Lock.revealed

      // every key is a chance caps lock changed, and the only way to find out.
      onKeyPressed: Lock.probeCaps()

      Connections {
        target: Lock

        function onFailuresChanged(): void {
          if (root.primary) field.shake()
        }

        // a wrong password, escape, or a preview scene with something typed.
        function onFill(text: string): void {
          field.setText(text)
        }
      }
    }

    Row {
      visible: Lock.caps
      spacing: Theme.lockCapsGap

      Glyph {
        anchors.verticalCenter: parent.verticalCenter

        size: Theme.pkNoteIcon
        icon: "keyboard_capslock"
        iconColor: Theme.elevated
        filled: true
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter

        text: "Caps Lock is on"
        color: Theme.elevated
        font.family: Theme.uiFont
        font.pixelSize: Theme.pkNoteSize
        font.variableAxes: Theme.uiAxesMedium
      }
    }

    // verifying, or what pam said about the last try. its height is kept while
    // empty so the column does not jump when something arrives in it.
    StatusNote {
      width: parent.width

      wraps: true
      line: Theme.lockNoteLine
      text: root.errored ? Lock.message : "Verifying…"
      shade: root.errored ? Theme.sysError : Theme.pkNoteIdle
      icon: root.errored ? "error" : "progress_activity"
      spinning: root.busy && root.prompting

      opacity: root.busy || root.errored ? 1 : 0

      Behavior on opacity {
        NumberAnimation { duration: Theme.notchFadeDuration }
      }
    }
  }
}
