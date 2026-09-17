pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  FileView {
    path: `${Quickshell.env("HOME")}/Playground/poly-quickshell/colors.json`
    watchChanges: true
    onFileChanged: reload()

    JsonAdapter {
      id: palette

      property string name: "unknown"

      property string bg0: "#040e0d"
      property string bg1: "#0a1816"
      property string bg2: "#0f211f"
      property string bg3: "#152a26"
      property string bg4: "#1d3631"

      property string fg: "#f5e2c5"

      property string red: "#ff6048"
      property string orange: "#ffa478"
      property string yellow: "#f5cd5b"
      property string green: "#7ad9a8"
      property string aqua: "#3dd1b0"
      property string blue: "#5fc8d4"
      property string purple: "#e89aa8"

      property string grey0: "#3a1a35"
      property string grey1: "#5a4d3e"
      property string grey2: "#c4b09a"
    }
  }

  readonly property string name: palette.name

  property color bg: "transparent"

  readonly property color pill: palette.bg1
  readonly property color pillIcon: palette.bg3
  readonly property color text: palette.fg

  readonly property color red: palette.red
  readonly property color orange: palette.orange
  readonly property color yellow: palette.yellow
  readonly property color green: palette.green
  readonly property color cyan: palette.aqua
  readonly property color teal: palette.blue
  readonly property color blue: palette.blue
  readonly property color purple: palette.purple
  readonly property color magenta: palette.purple
  readonly property color pink: palette.purple

  readonly property color accent: cyan

  property int barHeight: 50
  property int moduleHeight: 30
  property int spacing: 8
  property int radius: moduleHeight / 2
  property int margin: 13

  property int shadowRoom: 24
  property real shadowBlur: 16
  property real shadowSpread: 1
  property real shadowOffset: 3
  property color shadowColor: Qt.rgba(0, 0, 0, 0.45)

  property string font: "SFProDisplay Nerd Font"
  property real letterSpacing: 0

  property string iconFont: "Material Symbols Rounded"

  // Material Symbols ship as one variable font.
  // Four axes shape every icon on the bar:
  //   FILL  0 outlined, 1 solid. Values between work.
  //   wght  stroke thickness, 100 thin to 700 bold
  //   GRAD  emphasis tweak, -25 to 200
  //   opsz  the size you draw at, so the font tunes proportions
  property var iconAxes: ({
    "FILL": 0,
    "wght": 700,
    "GRAD": 0,
    "opsz": 20
  })

  property real textSize: 13
  property int iconSize: 14
}
