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
  onPrimaryChanged: if (root.primary) prompt.take()

  Component.onCompleted: if (root.primary) prompt.take()

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
      prompt.take()
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

    LockPrompt {
      id: prompt

      anchors.horizontalCenter: parent.horizontalCenter
      y: date.y + date.height + Theme.lockPromptTop + (root.prompting ? 0 : Theme.lockPromptRise)

      primary: root.primary
      prompting: root.prompting
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
}
