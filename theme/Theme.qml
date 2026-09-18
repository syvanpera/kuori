pragma Singleton
import QtQuick
import Quickshell

Singleton {
  id: root

  // the design's palette, hardcoded. the colors.json this singleton used to
  // watch is not on disk any more, and a frame this specific is not meant to be
  // recoloured from a generated palette.
  readonly property color frame: "#0b0f16"
  readonly property color notch: "#0f1726"

  readonly property color accent: "#5aa2ff"
  readonly property color urgent: "#e4574f"
  readonly property color warm: "#f0c674"

  // every neutral in the design is one tint at a different alpha, so derive them
  // instead of pasting four near-identical rgba values.
  readonly property color tint: "#dce6f5"
  readonly property color text: root.tint
  readonly property color glyph: root.tint.alpha(0.85)
  readonly property color textDim: root.tint.alpha(0.55)

  readonly property color workspaceActive: root.accent
  readonly property color workspaceUrgent: root.urgent
  readonly property color workspaceOccupied: "#6f87a8"
  readonly property color workspaceEmpty: root.tint.alpha(0.28)

  property int borderWidth: 5
  property int screenCornerRadius: 12

  // the design draws a 5px border inside a 12px corner, which leaves the
  // desktop opening rounded by whatever is left over.
  readonly property int screenInnerRadius: Math.max(0, root.screenCornerRadius - root.borderWidth)

  property int notchHeight: 25
  property int notchRadius: 12

  // half a logical pixel of overlap wherever two separately rasterised shapes
  // meet, so their antialiased edges cannot leave a hairline of transparent
  // panel showing between them.
  readonly property real seamBleed: 0.5

  // the design sizes everything inside a notch off its height, so one change to
  // notchHeight rescales the whole strip the way the mockup does.
  readonly property int notchPadding: Math.round(root.notchHeight * 0.56)
  readonly property int notchPaddingWide: Math.round(root.notchHeight * 0.8)
  readonly property int iconSize: Math.round(root.notchHeight * 0.56)
  readonly property int clockSize: Math.round(root.notchHeight * 0.48)
  readonly property int labelSize: 10

  // css letter-spacing is in em, font.letterSpacing is in pixels.
  readonly property real clockLetterSpacing: root.clockSize * 0.04

  property int dotSize: 5
  property int dotSpacing: 7
  property real dotGlow: 7

  property int systemSpacing: 9
  property int batterySpacing: 5

  // "JetBrains Mono" does not resolve on this machine, it falls back to DejaVu.
  // the nerd font patch is the only build installed and keeps the upstream
  // metrics, so the design's advance widths still land where the mockup put them.
  property string monoFont: "JetBrainsMono Nerd Font"

  property string iconFont: "Material Symbols Rounded"

  // Material Symbols ship as one variable font.
  // Four axes shape every icon on the frame:
  //   FILL  0 outlined, 1 solid. Values between work.
  //   wght  stroke thickness, 100 thin to 700 bold
  //   GRAD  emphasis tweak, -25 to 200
  //   opsz  the size you draw at, so the font tunes proportions
  // the design pins opsz to 24 even though the glyphs render at 14, so keep it
  // rather than matching pixelSize.
  property var iconAxes: ({
    "FILL": 0,
    "wght": 400,
    "GRAD": 0,
    "opsz": 24
  })

  // only the do-not-disturb lamp is filled. a second frozen map beats mutating
  // iconAxes, which would change every glyph at once and emit no notify.
  property var iconAxesFilled: ({
    "FILL": 1,
    "wght": 400,
    "GRAD": 0,
    "opsz": 24
  })
}
