import QtQuick
import qs.components
import qs.services
import qs.theme

// the capture block at the foot of the system panel. not a row: it does not fold,
// and everything it offers is visible at once.
Column {
  id: root

  spacing: Theme.capGap

  Row {
    width: parent.width
    spacing: Theme.capTileGap

    readonly property real cell: (width - Theme.capTileGap * 2) / 3

    ModeTile {
      width: parent.cell

      icon: "screenshot_region"
      label: "Screenshot"
      selected: Capture.mode === "shot"

      onPicked: Capture.mode = "shot"
    }

    ModeTile {
      width: parent.cell

      icon: "screen_record"
      label: "Record"
      selected: Capture.mode === "rec"

      onPicked: Capture.mode = "rec"
    }

    ModeTile {
      width: parent.cell

      icon: "colorize"
      label: "Color"
      selected: Capture.mode === "pick"

      onPicked: Capture.mode = "pick"
    }
  }

  // a colour has no target: it is wherever you point.
  Item {
    width: parent.width
    height: Math.max(targetLabel.implicitHeight, targets.implicitHeight)

    visible: Capture.mode !== "pick"

    Caption {
      id: targetLabel

      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      text: "TARGET"
    }

    Segmented {
      id: targets

      anchors.left: targetLabel.right
      anchors.leftMargin: Theme.capTargetGap
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      model: Capture.targets.map(t => ({ label: t.label, value: t.id }))
      current: Capture.target

      onPicked: value => Capture.target = value
    }
  }

  Column {
    width: parent.width
    spacing: Theme.capGap

    visible: Capture.mode === "pick"

    Item {
      width: parent.width
      height: Math.max(formatLabel.implicitHeight, formats.implicitHeight)

      Caption {
        id: formatLabel

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        text: "FORMAT"
      }

      Segmented {
        id: formats

        anchors.left: formatLabel.right
        anchors.leftMargin: Theme.capTargetGap
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        mono: true
        model: Capture.formats.map(f => ({ label: f.toUpperCase(), value: f }))
        current: Capture.format

        onPicked: value => Capture.format = value
      }
    }

    Rectangle {
      width: parent.width
      height: Math.max(Theme.capPickSwatch, pickText.implicitHeight) + Theme.capPickPaddingV * 2

      radius: Theme.capPickRadius
      color: Theme.sysWell

      Rectangle {
        id: swatch

        x: Theme.capPickPaddingH
        anchors.verticalCenter: parent.verticalCenter

        width: Theme.capPickSwatch
        height: Theme.capPickSwatch
        radius: Theme.capPickSwatchRadius

        // nothing picked yet has no colour to show, and a swatch of the panel's
        // own surface would read as black rather than as empty.
        color: Capture.picked.length > 0 ? Capture.picked : "transparent"

        border.width: 1
        border.color: Theme.clipPreviewRing
      }

      Column {
        id: pickText

        anchors.left: swatch.right
        anchors.leftMargin: Theme.capPickGap
        anchors.right: parent.right
        anchors.rightMargin: Theme.capPickPaddingH
        anchors.verticalCenter: parent.verticalCenter

        spacing: Theme.capPickTextGap

        Text {
          width: parent.width

          text: Capture.picked.length > 0 ? Capture.pickedText : "Nothing picked yet"
          elide: Text.ElideRight
          color: Capture.picked.length > 0 ? Theme.text : Theme.clipPreviewMeta
          font.family: Theme.monoFont
          font.pixelSize: Theme.capPickValueSize
          font.weight: Font.Medium
        }

        Text {
          width: parent.width

          // the design's second line, which names the tool doing the work and how
          // long ago it last did it.
          text: {
            if (Capture.flashing) return "hyprpicker · copied to clipboard"
            if (Capture.picked.length === 0) return "hyprpicker"

            // "now ago" is not a thing anyone says.
            const when = Time.ago(Capture.pickedAt, Time.date)

            return `hyprpicker · last pick ${when === "now" ? "just now" : `${when} ago`}`
          }
          elide: Text.ElideRight
          color: Theme.clipPreviewMeta
          font.family: Theme.monoFont
          font.pixelSize: Theme.clipPreviewMetaSize
        }
      }
    }
  }

  // only recording has anything to say about sound.
  CaptureSwitch {
    width: parent.width

    visible: Capture.mode === "rec"
    label: "Record microphone"
    checked: Capture.mic

    onToggled: Capture.mic = !Capture.mic
  }

  Rectangle {
    width: parent.width
    height: label.implicitHeight + Theme.capButtonPaddingV * 2

    radius: Theme.capButtonRadius

    // the design dims the button while it is working, which is also the only sign
    // a recording is running from in here.
    color: {
      if (Capture.recording || Capture.flashing) return Theme.capBusyFill

      return hover.containsMouse ? Theme.accentLift : Theme.accent
    }

    Behavior on color {
      ColorAnimation { duration: Theme.notchFadeDuration }
    }

    Text {
      id: label

      anchors.centerIn: parent

      text: {
        if (Capture.recording) return "Recording…"
        if (Capture.flashing) return Capture.mode === "pick" ? "Copied!" : "Captured!"

        return Capture.mode === "pick" ? "Pick color" : "Capture!"
      }
      color: Capture.recording || Capture.flashing ? Theme.text : Theme.litText
      font.family: Theme.uiFont
      font.pixelSize: Theme.capButtonSize
      font.variableAxes: Theme.uiAxesSemiBold
      font.letterSpacing: Theme.capButtonSpacing
    }

    MouseArea {
      id: hover

      anchors.fill: parent
      hoverEnabled: true

      onClicked: Capture.fire()
    }
  }
}
