import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme

// one row in the launcher's result grid: an icon chip, the app's name, and
// whatever the entry offers as a second line.
Rectangle {
  id: root

  required property var entry
  property bool selected: false

  // the entry's icon is a NAME, not a path, and iconPath with check:true answers
  // "" instead of a broken image when the theme has nothing under it, which is the
  // only way to know the fallback is needed. some entries ship an absolute path
  // instead of a name, and the icon loader has no idea what to do with one.
  readonly property string iconSource: {
    const icon = root.entry?.icon ?? ""

    if (icon.length === 0) return ""
    if (icon.startsWith("/")) return `file://${icon}`

    return Quickshell.iconPath(icon, true)
  }

  // the design's second line. genericName is the field meant for it; a comment is
  // prose but better than nothing, and the id at least says what will launch.
  readonly property string detail: root.entry?.genericName || root.entry?.comment || root.entry?.id || ""

  radius: Theme.launcherRowRadius
  color: root.selected ? Theme.launcherRaise : "transparent"

  Behavior on color {
    ColorAnimation { duration: 150 }
  }

  Rectangle {
    id: chip

    x: Theme.launcherRowPaddingH
    anchors.verticalCenter: parent.verticalCenter

    width: Theme.launcherIconSize
    height: Theme.launcherIconSize
    radius: Theme.launcherIconRadius
    color: root.selected ? Theme.accent : Theme.launcherRaise

    Behavior on color {
      ColorAnimation { duration: 150 }
    }

    IconImage {
      anchors.centerIn: parent

      visible: root.iconSource !== ""
      source: root.iconSource
      implicitSize: Theme.launcherIconInner

      // the path lookup is synchronous, but decoding the file does not have to be,
      // and a flick through the list would otherwise decode a png per row on the
      // gui thread.
      asynchronous: true
    }

    Text {
      anchors.centerIn: parent

      // the fallback for an icon the theme does not have. a letter says which app
      // this is; a generic placeholder glyph says nothing at all.
      visible: root.iconSource === ""
      text: (root.entry?.name ?? "?").charAt(0).toUpperCase()
      color: root.selected ? Theme.notch : Theme.launcherNameText
      font.family: Theme.uiFont
      font.pixelSize: Theme.launcherNameSize
      font.weight: Font.DemiBold
      font.variableAxes: Theme.uiAxesSemiBold
    }
  }

  Column {
    anchors.left: chip.right
    anchors.leftMargin: Theme.launcherRowGap
    anchors.right: parent.right
    anchors.rightMargin: Theme.launcherRowPaddingH
    anchors.verticalCenter: parent.verticalCenter

    spacing: Theme.launcherRowTextSpacing

    Text {
      width: parent.width

      text: root.entry?.name ?? ""
      elide: Text.ElideRight
      color: root.selected ? Theme.tintBright : Theme.launcherNameText
      font.family: Theme.uiFont
      font.pixelSize: Theme.launcherNameSize
      font.weight: Font.DemiBold

      // Manrope's default instance is its lightest one, so the weight has to be
      // pinned on the axis as well as asked for by name.
      font.variableAxes: Theme.uiAxesSemiBold

      Behavior on color {
        ColorAnimation { duration: 150 }
      }
    }

    Text {
      width: parent.width

      text: root.detail
      elide: Text.ElideRight
      color: Theme.launcherDimText
      font.family: Theme.monoFont
      font.pixelSize: Theme.launcherDetailSize
    }
  }
}
