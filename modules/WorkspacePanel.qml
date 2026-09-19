import QtQuick
import qs.services
import qs.theme

// what the workspaces tab becomes while hovered: one pill per workspace slot,
// carrying the same four states the collapsed dots show, and clickable.
Row {
  id: root

  // the strip and the panel have to agree on how many slots there are, or the tab
  // would show three dots and open onto five pills.
  readonly property var slots: Workspaces.slots

  leftPadding: Theme.notchPanelPadding
  rightPadding: Theme.notchPanelPadding
  topPadding: Theme.notchPanelPadding
  bottomPadding: Theme.notchPanelPadding

  spacing: Theme.wsPillSpacing

  Repeater {
    model: root.slots

    Rectangle {
      id: pill

      required property int index
      required property var modelData

      readonly property int id: pill.index + 1
      readonly property bool occupied: pill.modelData !== null
      readonly property bool active: pill.modelData?.active ?? false
      readonly property bool urgent: pill.modelData?.urgent ?? false

      // lit means the pill carries a state colour and needs dark text on it.
      readonly property bool lit: pill.active || pill.urgent

      width: Theme.wsPillSize
      height: Theme.wsPillSize
      radius: Theme.wsPillRadius

      color: {
        if (pill.urgent) return Theme.workspaceUrgent
        if (pill.active) return Theme.workspaceActive
        if (pill.occupied) return Theme.wsPillOccupied
        return Theme.wsPillEmpty
      }

      Behavior on color {
        ColorAnimation { duration: 150 }
      }

      Text {
        anchors.centerIn: parent

        text: pill.id
        color: {
          if (pill.lit) return Theme.litText
          if (pill.occupied) return Theme.workspaceOccupied
          return Theme.wsPillEmptyText
        }

        font.family: Theme.monoFont
        font.pixelSize: Theme.wsPillTextSize
        font.weight: Font.Medium

        Behavior on color {
          ColorAnimation { duration: 150 }
        }
      }

      MouseArea {
        anchors.fill: parent

        // a workspace hyprland has never heard of has no object to activate, so it
        // has to be summoned by id the way the dots do it.
        onClicked: Workspaces.focus(pill.id)
      }
    }
  }
}
