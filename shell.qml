import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.theme

ShellRoot {
  id: shell

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: Theme.barHeight
      color: Theme.bg

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Text {
          id: logo
          color: "#a9b1d6"

          font {
            pixelSize: 14
            family: "UbuntuMono Nerd Font"
            weight: 600
          }

          text: " "
        }

        Workspaces {}

        Item { Layout.fillWidth: true }

        Volume {}
        Network {}
        Battery {}
        Clock {}
      }
    }
  }
}
