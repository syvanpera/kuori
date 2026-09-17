import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
  spacing: 5

  Repeater {
    model: 5

    Rectangle {
      id: wsButton
      required property int index

      property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
      property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)

      implicitWidth: label.implicitWidth + 14
      implicitHeight: 20
      radius: 6

      // color: isActive ? "#f7768e" : "#a9b1d6"
      color: isActive ? "#1d3631" : (ws ? "#0f211f" : "transparent")

      Behavior on color {
        ColorAnimation { duration: 150 }
      }

      Text {
        id: label
        anchors.centerIn: parent
        text: wsButton.index + 1
        color: wsButton.isActive ? "#3dd1b0" : (wsButton.ws ? "#f5e2c5": "#5a4d3e")

        font {
          family: "SFProDisplay Nerd Font"
          pixelSize: 13
          weight: 600
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (parent.index + 1) + " })")
      }
    }
  }
}
