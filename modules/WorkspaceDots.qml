import QtQuick
import QtQuick.Effects
import qs.services
import qs.theme

// the left tab: one dot per workspace slot, lit from hyprland's state.
Row {
  id: root

  // shared with the panel this tab opens onto, so the two always agree on how
  // many slots there are.
  readonly property var slots: Workspaces.slots

  spacing: Theme.dotSpacing

  Repeater {
    model: root.slots

    Item {
      id: dot

      required property int index
      required property var modelData

      readonly property bool occupied: dot.modelData !== null
      // active rather than focused: on a multi-head setup each monitor shows one,
      // and a dot should track the monitor it lives on, not the keyboard.
      readonly property bool active: dot.modelData?.active ?? false
      readonly property bool urgent: dot.modelData?.urgent ?? false
      readonly property bool glowing: dot.active || dot.urgent

      readonly property color shade: {
        if (dot.urgent) return Theme.workspaceUrgent
        if (dot.active) return Theme.workspaceActive
        if (dot.occupied) return Theme.workspaceOccupied
        return Theme.workspaceEmpty
      }

      implicitWidth: Theme.dotSize
      implicitHeight: Theme.dotSize

      // the design writes this as `box-shadow: 0 0 7px accent`. RectangularShadow
      // is the analytic equivalent, drawn straight into the scene graph, where
      // MultiEffect would allocate a framebuffer per five pixel dot.
      RectangularShadow {
        anchors.fill: parent
        radius: Theme.dotSize / 2
        blur: Theme.dotGlow
        spread: 0
        color: dot.shade
        opacity: dot.glowing ? 1 : 0

        Behavior on opacity {
          NumberAnimation { duration: 150 }
        }
      }

      Rectangle {
        anchors.fill: parent
        radius: Theme.dotSize / 2
        color: dot.shade

        Behavior on color {
          ColorAnimation { duration: 150 }
        }
      }

      MouseArea {
        // five pixels is unclickable, so grow the hit area halfway into the gap
        // on each side. this makes the whole strip hittable without moving paint.
        anchors.fill: parent
        anchors.margins: -Theme.dotSpacing / 2

        onClicked: Workspaces.focus(dot.index + 1)
      }
    }
  }
}
