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

    readonly property real cell: (width - Theme.capTileGap) / 2

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
  }

  Item {
    width: parent.width
    height: Math.max(targetLabel.implicitHeight, targets.implicitHeight)

    Text {
      id: targetLabel

      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      text: "TARGET"
      color: Theme.sysCap
      font.family: Theme.monoFont
      font.pixelSize: Theme.sysCapSize
      font.weight: Font.Medium
      font.letterSpacing: Theme.sysCapSpacing
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
        if (Capture.flashing) return "Captured!"

        return "Capture!"
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
