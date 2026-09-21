import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme

// one row in the launcher's result grid: a square tile, a name, and a second line
// saying what the row is. it renders whatever the row object offers for the tile
// and knows nothing about where the row came from -- an app, a wallpaper and
// (later) a clipboard entry are all the same shape here.
Rectangle {
  id: root

  required property var row
  property bool selected: false

  // for a row that is already in effect, which today means the wallpaper on
  // screen. the design has no state for it; without one, the list cannot say
  // which of six pictures you are looking at.
  property bool marked: false

  // the tile, in order of what the row offers: a picture of its own, a material
  // symbol, the icon a desktop entry names, and failing all three a letter.
  readonly property string image: root.row?.image ?? ""
  readonly property string glyph: root.row?.glyph ?? ""

  // a colour that is itself the content, which is the design's own idea: a hex
  // code on the clipboard shows as the colour rather than as a glyph. it paints
  // the tile and nothing is drawn on top.
  readonly property string swatch: root.row?.swatch ?? ""

  // a desktop entry's icon is a NAME, not a path, and iconPath with check:true
  // answers "" instead of a broken image when the theme has nothing under it,
  // which is the only way to know the fallback is needed. some entries ship an
  // absolute path instead, and the icon loader has no idea what to do with one.
  readonly property string iconSource: {
    const icon = root.row?.icon ?? ""

    if (icon.length === 0) return ""
    if (icon.startsWith("/")) return `file://${icon}`

    return Quickshell.iconPath(icon, true)
  }

  readonly property string detail: {
    const detail = root.row?.detail ?? ""

    return root.marked ? `${detail} · current` : detail
  }

  radius: Theme.launcherRowRadius
  color: root.selected ? Theme.launcherRaise : "transparent"

  Behavior on color {
    ColorAnimation { duration: 150 }
  }

  // clipping rather than a plain Rectangle so a thumbnail takes the tile's rounded
  // corners. Item.clip is a scissor rectangle and would leave the picture square
  // inside a round tile; this is quickshell's stencil-clipped one.
  ClippingRectangle {
    id: chip

    x: Theme.launcherRowPaddingH
    anchors.verticalCenter: parent.verticalCenter

    width: Theme.launcherIconSize
    height: Theme.launcherIconSize
    radius: Theme.launcherIconRadius

    // a picture fills the tile, so the tile's own colour would only show at the
    // corners it is already clipping away.
    color: {
      if (root.swatch !== "") return root.swatch
      if (root.image !== "") return "transparent"

      return root.selected ? Theme.accent : Theme.launcherRaise
    }

    Behavior on color {
      ColorAnimation { duration: 150 }
    }

    Image {
      anchors.fill: parent

      visible: root.image !== ""
      source: root.image
      fillMode: Image.PreserveAspectCrop

      // decoded at the tile's height rather than the file's: a wallpaper is a
      // screen-sized picture and the tile is 32px. only the height is given, so a
      // panorama stays a panorama and still covers the square after the crop.
      sourceSize.height: Theme.launcherIconSize * 2

      // decoding is what costs, and a flick through the list would otherwise do it
      // on the gui thread.
      asynchronous: true
    }

    Glyph {
      anchors.centerIn: parent

      visible: root.image === "" && root.swatch === "" && root.glyph !== ""
      icon: root.glyph
      size: Theme.launcherIconInner
      iconColor: root.selected ? Theme.notch : Theme.launcherNameText
    }

    IconImage {
      anchors.centerIn: parent

      visible: root.image === "" && root.swatch === "" && root.glyph === "" && root.iconSource !== ""
      source: root.iconSource
      implicitSize: Theme.launcherIconInner
      asynchronous: true
    }

    Text {
      anchors.centerIn: parent

      // the fallback for an icon the theme does not have. a letter says which app
      // this is; a generic placeholder glyph says nothing at all.
      visible: root.image === "" && root.swatch === "" && root.glyph === "" && root.iconSource === ""
      text: (root.row?.name ?? "?").charAt(0).toUpperCase()
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

      text: root.row?.name ?? ""
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
