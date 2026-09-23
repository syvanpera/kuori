import QtQuick
import qs.components
import qs.services
import qs.theme

// the capture block at the foot of the system panel. not a row: it does not fold,
// and everything it offers is visible at once.
Column {
  id: root

  // a caption at the left and a segmented choice filling the rest: the target
  // for a capture and the format for a colour.
  component Choice: Item {
    id: choice

    property string caption: ""
    property alias model: segments.model
    property alias current: segments.current
    property alias mono: segments.mono

    signal picked(var value)

    height: Math.max(label.implicitHeight, segments.implicitHeight)

    Caption {
      id: label

      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      text: choice.caption
    }

    Segmented {
      id: segments

      anchors.left: label.right
      anchors.leftMargin: Theme.capTargetGap
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      onPicked: value => choice.picked(value)
    }
  }

  spacing: Theme.capGap

  Row {
    id: modes

    readonly property real cell: (modes.width - Theme.capTileGap * 2) / 3

    width: parent.width
    spacing: Theme.capTileGap

    ModeTile {
      width: modes.cell

      icon: "screenshot_region"
      label: "Screenshot"
      selected: Capture.mode === "shot"

      onPicked: Capture.mode = "shot"
    }

    ModeTile {
      width: modes.cell

      icon: "screen_record"
      label: "Record"
      selected: Capture.mode === "rec"

      onPicked: Capture.mode = "rec"
    }

    ModeTile {
      width: modes.cell

      icon: "colorize"
      label: "Color"
      selected: Capture.mode === "pick"

      onPicked: Capture.mode = "pick"
    }
  }

  // a colour has no target: it is wherever you point.
  Choice {
    width: parent.width
    visible: Capture.mode !== "pick"

    caption: "TARGET"
    model: Capture.targets.map(t => ({ label: t.label, value: t.id }))
    current: Capture.target

    onPicked: value => Capture.target = value
  }

  Column {
    width: parent.width
    spacing: Theme.capGap

    visible: Capture.mode === "pick"

    Choice {
      width: parent.width

      caption: "FORMAT"
      mono: true
      model: ColourPicker.formats.map(f => ({ label: f.toUpperCase(), value: f }))
      current: ColourPicker.format

      onPicked: value => ColourPicker.format = value
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
        color: ColourPicker.picked.length > 0 ? ColourPicker.picked : "transparent"

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

          text: ColourPicker.picked.length > 0 ? ColourPicker.pickedText : "Nothing picked yet"
          elide: Text.ElideRight
          color: ColourPicker.picked.length > 0 ? Theme.text : Theme.clipPreviewMeta
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
            if (ColourPicker.picked.length === 0) return "hyprpicker"

            // "now ago" is not a thing anyone says.
            const when = Time.ago(ColourPicker.pickedAt, Time.date)

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
