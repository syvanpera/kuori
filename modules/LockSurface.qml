import QtQuick
import QtQuick.Effects
import qs.components
import qs.services
import qs.theme

// what one screen shows while locked: the wallpaper, blurred and darkened, the
// frame and two of its tabs, a big clock, and on the screen with the keyboard the
// prompt under it.
//
// the prompt is the design's: the clock alone at rest, the field on the first key
// or click with that key already typed into it, escape to put it away.
Item {
  id: root

  property string screenName: ""

  readonly property bool primary: !Lock.previewSecondary && root.screenName === Lock.primary
  readonly property bool prompting: root.primary && Lock.prompt
  readonly property bool busy: Lock.status === "busy"
  readonly property bool errored: Lock.status === "error"

  // the whole thing fades on the way out, and the content grows a little as it
  // goes, which is the design's exit.
  opacity: Lock.leaving ? 0 : 1

  Behavior on opacity {
    NumberAnimation {
      duration: Theme.lockExit
      easing.type: Easing.Bezier
      easing.bezierCurve: Theme.easeExit
    }
  }

  // the prompt belongs to whichever screen has the keyboard, and follows it.
  onPrimaryChanged: if (root.primary) field.take()

  Component.onCompleted: if (root.primary) field.take()

  Rectangle {
    anchors.fill: parent
    color: Theme.surface
  }

  Image {
    id: wallpaper

    anchors.fill: parent

    // blurred into a wash anyway, so decoded at a fraction of the screen: the
    // blur's cost follows the texture, and nothing of the detail survives it.
    source: Wallpapers.current.length > 0 ? `file://${Wallpapers.current}` : ""
    sourceSize.width: Math.round(root.width / 3)
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    visible: false
  }

  // the one MultiEffect in the shell, and the reason it is allowed: it exists
  // only while the screen is locked, over a picture that never changes, so the
  // blur is rendered once and then sits there.
  MultiEffect {
    anchors.fill: parent

    source: wallpaper
    scale: Theme.lockBackdropScale
    visible: wallpaper.status === Image.Ready

    autoPaddingEnabled: false
    blurEnabled: true
    blur: 1
    blurMax: Math.round(Theme.lockBlur * 2)
    saturation: Theme.lockSaturation
  }

  // css brightness() multiplies, and MultiEffect's brightness adds, so the
  // darkening is ink laid over the top at whatever it takes away.
  Rectangle {
    anchors.fill: parent
    color: Theme.ink
    opacity: 1 - (root.primary ? Theme.lockBright : Theme.lockBrightSecondary)
  }

  Rectangle {
    anchors.fill: parent
    color: Theme.lockWash
    opacity: Theme.lockWashAlpha
  }

  // a click anywhere brings the prompt up, or gives the field back its focus.
  MouseArea {
    anchors.fill: parent
    enabled: root.primary

    onClicked: {
      Lock.prompt = true
      field.take()
    }
  }

  Item {
    id: content

    anchors.fill: parent

    opacity: Lock.leaving ? 0 : 1
    scale: Lock.leaving ? Theme.lockExitScale : 1

    Behavior on opacity {
      NumberAnimation { duration: Theme.lockExitContent }
    }

    Behavior on scale {
      NumberAnimation {
        duration: Theme.lockExit
        easing.type: Easing.Bezier
        easing.bezierCurve: Theme.easeExit
      }
    }

    Text {
      id: clock

      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.round(root.height * Theme.lockTop)

      // css line-height:1, so the box is the size and the date hangs off it where
      // the design puts it.
      height: Theme.lockClockSize
      lineHeightMode: Text.FixedHeight
      lineHeight: Theme.lockClockSize
      verticalAlignment: Text.AlignVCenter

      text: Qt.formatDateTime(Time.date, "hh:mm")
      color: Theme.tintBright
      opacity: root.primary ? 1 : Theme.lockClockDim
      font.family: Theme.monoFont
      font.pixelSize: Theme.lockClockSize
      font.weight: Font.Medium
      font.letterSpacing: Theme.lockClockSpacing
    }

    Text {
      id: date

      anchors.horizontalCenter: parent.horizontalCenter
      y: clock.y + clock.height + Theme.lockDateTop

      height: Theme.lockDateSize
      lineHeightMode: Text.FixedHeight
      lineHeight: Theme.lockDateSize
      verticalAlignment: Text.AlignVCenter

      text: Qt.formatDateTime(Time.date, "dddd d MMMM")
      color: Theme.lockDateText
      opacity: clock.opacity
      font.family: Theme.uiFont
      font.pixelSize: Theme.lockDateSize
      font.variableAxes: Theme.uiAxesMedium
      font.letterSpacing: Theme.lockDateSpacing
    }

    Column {
      id: prompt

      anchors.horizontalCenter: parent.horizontalCenter
      y: date.y + date.height + Theme.lockPromptTop + (root.prompting ? 0 : Theme.lockPromptRise)

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
        NumberAnimation {
          duration: Theme.lockPromptMove
          easing.type: Easing.Bezier
          easing.bezierCurve: Theme.easeStandard
        }
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
  }

  // the frame and its two tabs, as they are on the desktop, so the shell is still
  // recognisably there. the shadows go first for the reason FrameWindow's do.
  NotchShadow { notch: badge }
  NotchShadow { notch: status; opacity: status.opacity }

  DesktopFrame {
    anchors.fill: parent
  }

  Notch {
    id: badge

    x: Math.round((root.width - width) / 2)
    y: Theme.borderWidth
    placement: "center"

    Glyph {
      icon: "lock"
      iconColor: Theme.lockBadge
      filled: true
    }
  }

  // what is worth knowing without unlocking: whether it is online and how much
  // battery is left. read-only, and only where the prompt is.
  Notch {
    id: status

    x: root.width - width - Theme.borderWidth
    y: Theme.borderWidth
    placement: "right"
    aside: !root.primary

    Row {
      spacing: Theme.systemSpacing

      Glyph {
        icon: Network.linkGlyph
        iconColor: Network.online ? Theme.glyph : Theme.textDim
      }

      Row {
        spacing: Theme.batterySpacing

        Glyph {
          icon: Power.glyph
          iconColor: Power.charging ? Theme.accent : Theme.glyph
        }

        Text {
          height: Theme.iconSize
          verticalAlignment: Text.AlignVCenter

          text: `${Power.percent}%`
          color: Theme.textDim
          font.family: Theme.monoFont
          font.pixelSize: Theme.labelSize
        }
      }
    }
  }

  // locking comes up out of black, which is the design's wake.
  Rectangle {
    id: wake

    anchors.fill: parent
    color: Theme.ink

    NumberAnimation on opacity {
      from: 1
      to: 0
      duration: Theme.lockWake
      easing.type: Easing.Bezier
      easing.bezierCurve: Theme.easeExit
    }
  }

  function enter(): void {
    if (!Lock.prompt) {
      Lock.prompt = true
      return
    }

    Lock.submit(field.text)
  }
}
