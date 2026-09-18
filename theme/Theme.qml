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

  // the launcher dims the whole screen behind itself. the only colour in the
  // design not derived from the frame's palette, because it is the desktop seen
  // through smoked glass rather than a surface of the shell.
  readonly property color shade: "#06090e"
  readonly property color ink: "#000000"
  readonly property color launcherScrim: root.shade.alpha(0.55)
  readonly property color launcherShadow: root.ink.alpha(0.5)

  // every raised surface inside the panel is white at one of three alphas over
  // the notch colour, the same trick the frame plays with tint.
  readonly property color sheen: "#ffffff"
  readonly property color launcherLine: root.sheen.alpha(0.07)
  readonly property color launcherRaise: root.sheen.alpha(0.06)
  readonly property color launcherSunken: root.sheen.alpha(0.04)
  readonly property color launcherChipActive: root.accent.alpha(0.14)

  // the mockup writes the launcher's neutral as #e0eaf8 and the frame's as
  // #dce6f5. two hex steps apart is not two colours, so the launcher borrows the
  // frame's tint and keeps only the alphas.
  readonly property color launcherKeyText: root.tint.alpha(0.6)
  readonly property color launcherChipText: root.tint.alpha(0.5)
  readonly property color launcherNameText: root.tint.alpha(0.8)
  readonly property color launcherDimText: root.tint.alpha(0.4)

  // the query being typed and the row under the selection are the only things in
  // the panel allowed to be brighter than the frame's text.
  readonly property color tintBright: "#eef4fd"

  property int launcherWidth: 520
  property int launcherTop: 96
  property int launcherRise: 12

  property int launcherPadding: 16
  property int launcherRowGap: 11
  property int launcherSearchPadding: 14
  property int launcherSearchIcon: 19
  property int launcherInputSize: 14

  // the keycaps are their own thing: every future overlay labels its shortcuts
  // the same way, so these are not prefixed.
  property int keyCapPaddingH: 6
  property int keyCapPaddingV: 2
  property int keyCapRadius: 5

  // the design says 9.5px. font.pixelSize is an int, and pointSize would make the
  // size depend on whichever monitor the launcher opened on.
  property int keyCapSize: 10

  property int launcherChipRowPadding: 10
  property int launcherChipRowBottom: 6
  property int launcherChipSpacing: 6
  property int launcherChipPaddingH: 11
  property int launcherChipPaddingV: 6
  property int launcherChipRadius: 9
  property int launcherChipSize: 10

  // css letter-spacing is in em, font.letterSpacing is in pixels.
  readonly property real launcherChipLetterSpacing: root.launcherChipSize * 0.07

  property int launcherGridPadding: 10
  property int launcherGridTop: 6
  property int launcherGridBottom: 12
  property int launcherGridGap: 4
  property int launcherGridMax: 326

  property int launcherRowPaddingH: 11
  property int launcherRowPaddingV: 9
  property int launcherRowRadius: 11
  property int launcherRowTextSpacing: 2
  property int launcherIconSize: 32
  property int launcherIconRadius: 9
  property int launcherIconInner: 20

  // the icon chip plus its padding above and below. the grid's cell height is
  // derived from this, so it cannot just fall out of the row's contents.
  readonly property int launcherRowHeight: root.launcherIconSize + root.launcherRowPaddingV * 2

  property int launcherNameSize: 12
  property int launcherDetailSize: 10
  property int launcherEmptySize: 12
  property int launcherEmptyBottom: 18

  property int launcherFooterPaddingH: 14
  property int launcherFooterPaddingV: 9
  property int launcherFooterSpacing: 8
  property int launcherFooterSize: 10

  property int launcherFade: 160
  property int launcherSlideDuration: 200

  // css cubic-bezier(.2,.8,.2,1). Easing.Bezier wants the two control points
  // followed by the end point, which is always 1,1.
  readonly property var launcherEase: [0.2, 0.8, 0.2, 1.0, 1.0, 1.0]

  property real launcherShadowBlur: 70
  property real launcherShadowOffset: 24

  property string uiFont: "Manrope"

  // Manrope is one variable file whose default named instance is ExtraLight, so
  // font.weight alone leaves a 600 heading looking like a hairline. pinning the
  // axis is the same fix the symbol font already needs.
  property var uiAxesSemiBold: ({ "wght": 600 })

  // css line-height:1.2 in a box. Text.implicitHeight follows the font's own line
  // spacing, which is taller, and would make every chip a few pixels fat.
  function lineBox(size: real): int {
    return Math.round(size * 1.2)
  }
}
