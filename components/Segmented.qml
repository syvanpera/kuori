import QtQuick
import qs.theme

// one choice out of a few, laid out in a track: the design's TARGET control.
//
// the power profiles in modules/BatteryRow.qml are the same idea without the
// track around them, which is why the cell arithmetic here looks familiar.
Rectangle {
  id: root

  // [{ label, value }]. value is whatever the caller wants back.
  property var model: []
  property var current: null

  signal picked(var value)

  readonly property real cell: {
    const n = Math.max(1, root.model.length)

    return (root.width - Theme.capTrackPadding * 2 - Theme.capSegmentGap * (n - 1)) / n
  }

  implicitHeight: segments.implicitHeight + Theme.capTrackPadding * 2

  radius: Theme.capTrackRadius
  color: Theme.capTrack

  Row {
    id: segments

    x: Theme.capTrackPadding
    y: Theme.capTrackPadding

    spacing: Theme.capSegmentGap

    Repeater {
      model: root.model

      Rectangle {
        id: segment

        required property var modelData

        readonly property bool chosen: root.current === segment.modelData.value

        width: root.cell
        height: label.implicitHeight + Theme.capSegmentPaddingV * 2

        radius: Theme.capSegmentRadius
        color: {
          if (segment.chosen) return Theme.capSegmentOn

          return hover.containsMouse ? Theme.sysNetHover : "transparent"
        }

        Behavior on color {
          ColorAnimation { duration: Theme.notchFadeDuration }
        }

        Text {
          id: label

          anchors.centerIn: parent

          text: segment.modelData.label
          color: segment.chosen ? Theme.text : Theme.capSegmentText
          font.family: Theme.uiFont
          font.pixelSize: Theme.capSegmentSize
          font.weight: Font.Medium
        }

        MouseArea {
          id: hover

          anchors.fill: parent
          hoverEnabled: true

          onClicked: root.picked(segment.modelData.value)
        }
      }
    }
  }
}
