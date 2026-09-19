pragma Singleton
import QtQuick
import Quickshell

Singleton {
  id: root

  // the design's palette, hardcoded. the colors.json this singleton used to
  // watch is not on disk any more, and a frame this specific is not meant to be
  // recoloured from a generated palette.

  // the frame and the notches are one surface: the border band and the tabs
  // hanging off it read as a single continuous shape, which only works while they
  // are exactly the same colour. they were #0b0f16 and #0f1726 until the design
  // merged them, so this is one token with two names rather than two values that
  // have to be kept in step by hand.
  readonly property color surface: "#0b0f16"
  // The color below is here just so that I remember it
  // readonly property color surface: "#0f1726"
  readonly property color frame: root.surface
  readonly property color notch: root.surface

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

  // how solid the focus mark is over the window it sits on. at full strength the
  // accent is a hard block against a dark window, so it is let down a little and
  // the window reads through it.
  //
  // this is alpha baked into the fill rather than an opacity on the item, because
  // FrameWindow drives that property to fade the mark in and out and would
  // overwrite anything set here.
  property real focusOpacity: 1.0

  // the mark borrows the accent the same way the active workspace dot does,
  // instead of reaching for Theme.accent at the call site. the hyprland border it
  // stands in for was this exact colour.
  readonly property color focusColor: root.accent.alpha(root.focusOpacity)

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

  // the wedge marking the focused window, which fills its upper-right corner out
  // to both edges. this is how far it reaches along each of them, not the length
  // of the hypotenuse across the back.
  //
  // it has to clear windowRadius comfortably or the corner arc eats the whole
  // shape and the wedge stops reading as one.
  property int focusMarkSize: 20

  // the mark sits flush in the corner, so its own outer corner has to be rounded
  // by exactly what hyprland rounds the window by -- decoration.rounding in
  // looknfeel.lua, which nothing here can read, so the two are kept in step by
  // hand. it is an arc rather than a superellipse because rounding_power is 2;
  // anything else there and this would have to be drawn as a curve.
  property int windowRadius: 12

  property int focusFade: 150

  // "mark" for the wedge in the window's top-right corner, "strip" for a bar the
  // width of the window hung above it. both read the same focusColor and fade.
  property string focusStyle: "strip"

  // the strip is placed against the window's top edge, not inside the gap above
  // it, so changing hyprland's gaps moves the window and the strip together and
  // nothing here has to know what they are. how thick is the whole shape of it:
  // it sits on the edge rather than floating over it, so that it can fill the
  // wedges the window's rounded corners leave and read as part of the window.
  property int focusStripThickness: 5

  // which of the window's horizontal edges the strip sits on: "top" or "bottom".
  property string focusStripEdge: "top"

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

  // the design gives the notches a two layer elevation shadow: a soft ambient
  // spread, plus a tight contact line right under the edge. qt takes blur as the
  // pixel distance the falloff reaches, fed to a smoothstep over a signed distance
  // field, rather than a gaussian sigma, so css blur radii transfer at about 1.2x.
  // the alphas are dials like the blurs and offsets below, not literals buried in
  // a colour expression: darkening the shadow is the one adjustment worth making
  // without enlarging it. the design writes .34 and .28, but it was drawn against
  // its own lighter #0f1726 surface and reads weaker over the #0b0f16 this runs.
  property real notchShadowAmbientAlpha: 0.45
  property real notchShadowContactAlpha: 0.38

  readonly property color notchShadowAmbient: root.ink.alpha(root.notchShadowAmbientAlpha)
  readonly property color notchShadowContact: root.ink.alpha(root.notchShadowContactAlpha)

  property real notchShadowAmbientBlur: 17
  property real notchShadowAmbientOffset: 5
  property real notchShadowContactBlur: 4
  property real notchShadowContactOffset: 1

  // spread grows the silhouette before the falloff is applied, so it thickens the
  // dark core rather than reaching further with the same fade. the design writes
  // no spread at all; this is deliberately past it, and it is the dial with the
  // most effect per unit if the shadow still wants more weight.
  property real notchShadowAmbientSpread: 2
  property real notchShadowContactSpread: 1

  // hovering a tab collapses its strip and puts a panel in its place. one box that
  // grows, rather than the design's two stacked boxes, because the tab and the
  // panel share a corner and the fillets already follow the body wherever it goes.
  property int notchPanelPadding: 8

  // the strip breathes this much above and below its contents, which is what lets
  // the clock grow taller when it peeks its date.
  property int notchStripPadding: 5

  // the clock's date peek: a second line that slides out under the time on hover.
  property int clockPeekSize: 10
  property int clockPeekHeight: 13
  property int clockPeekGap: 10
  readonly property real clockPeekSpacing: root.clockPeekSize * 0.05
  property int notchExpandDuration: 240
  property int notchFadeDuration: 160

  // the workspace panel: one pill per workspace, the same states the dots show.
  property int wsPillSize: 30
  property int wsPillRadius: 10
  property int wsPillSpacing: 4
  property int wsPillTextSize: 13

  // the clock panel: a big time, the date, a month grid and whatever is on today.
  // 224 of content inside 18 of padding. the design writes the 224, because css
  // pads outside a stated width -- the same reading as the system panel's 314.
  property int clockPanelWidth: 260
  property int clockPanelPaddingH: 18
  property int clockPanelPaddingV: 14

  readonly property color notchPanelLine: root.sheen.alpha(0.09)

  property int clockBigSize: 30
  property int clockDateSize: 12
  property int clockDateGap: 6
  property int dateUndoSize: 13
  property int dateUndoGap: 5

  readonly property color clockDateText: root.tint.alpha(0.62)

  // css letter-spacing is in em, font.letterSpacing is in pixels.
  readonly property real clockBigSpacing: root.clockBigSize * 0.02

  property int calNavSize: 20
  property int calNavRadius: 6
  property int calNavIcon: 16
  property int calMonthSize: 11
  readonly property real calMonthSpacing: root.calMonthSize * 0.06

  property int calWeekColumn: 22
  property int calCellHeight: 22
  property int calHeadHeight: 16
  property int calCellRadius: 7
  property int calGap: 2
  property int calDaySize: 11
  property int calHeadSize: 9

  readonly property color calHeadText: root.tint.alpha(0.35)
  readonly property color calWeekText: root.tint.alpha(0.3)
  readonly property color calDayText: root.tint.alpha(0.72)
  readonly property color calNavText: root.tint.alpha(0.55)

  property int eventIcon: 18
  property int eventTitleSize: 12
  property int eventDetailSize: 11
  property int eventGap: 10

  // dark text for anything sitting on a lit accent surface: a workspace pill, the
  // calendar's today. the rest are a wash over the surface, the same sheen the
  // launcher raises its rows with.
  readonly property color litText: "#081018"
  readonly property color wsPillOccupied: root.sheen.alpha(0.09)
  readonly property color wsPillEmpty: root.sheen.alpha(0.04)
  readonly property color wsPillEmptyText: root.tint.alpha(0.38)

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

  // the design uses one easing curve everywhere, css cubic-bezier(.2,.8,.2,1).
  // Easing.Bezier wants the two control points followed by the end point, which is
  // always 1,1.
  readonly property var easeStandard: [0.2, 0.8, 0.2, 1.0, 1.0, 1.0]

  property real launcherShadowBlur: 70
  property real launcherShadowOffset: 24

  // the system panel: rows that fold open, one at a time. the design writes its
  // type sizes in halves -- 11.5, 10.5, 9.5 -- and font.pixelSize is an int, so
  // each one is rounded up the way the launcher's keycaps already are.
  // the design writes the panel as 286 wide with 14 of padding, and css pads
  // outside a stated width, so the box is 314. the strip grows to exactly this
  // when the tab opens, which is the number the design states outright.
  property int sysPanelWidth: 314
  property int sysPanelPadding: 14
  property int sysSectionGap: 12
  property int sysRowSpacing: 4

  property int sysRowRadius: 11
  property int sysRowPaddingH: 9
  property int sysRowPaddingV: 7
  property int sysRowGap: 10
  property int sysRowIcon: 17
  property int sysRowLabelSize: 12
  property int sysRowValueSize: 12
  property int sysChevron: 15

  property int sysBodyPaddingH: 9
  property int sysBodyTop: 2
  property int sysBodyBottom: 10
  property int sysBodyGap: 9

  // the small all-caps headings inside a folded-open row.
  property int sysCapSize: 10
  readonly property real sysCapSpacing: root.sysCapSize * 0.09

  property int sysStatSize: 11
  property int sysStatGapH: 14
  property int sysStatGapV: 6

  property int sysNetRadius: 9
  property int sysNetPaddingH: 8
  property int sysNetPaddingV: 6
  property int sysNetGap: 9
  property int sysNetIcon: 14
  property int sysNetNameSize: 11
  property int sysNetDetailSize: 10
  property int sysNetTextSpacing: 3
  property int sysNetSpacing: 2

  // the pill switch. 2 + 11 + 11 + 2 is the design's 26, which is why the knob's
  // travel is exactly its own width.
  property int switchWidth: 26
  property int switchHeight: 15
  property int switchPadding: 2
  property int switchKnob: 11

  readonly property color sysDim: root.tint.alpha(0.4)
  readonly property color sysValue: root.tint.alpha(0.55)
  readonly property color sysCap: root.tint.alpha(0.35)
  readonly property color sysStatKey: root.tint.alpha(0.45)
  readonly property color sysStatValue: root.tint.alpha(0.8)
  readonly property color sysNetName: root.tint.alpha(0.62)
  readonly property color sysNetDetail: root.tint.alpha(0.4)
  readonly property color sysNetGlyph: root.tint.alpha(0.45)
  readonly property color sysNetLock: root.tint.alpha(0.35)

  // a network you are pointing at, and one whose row is open for a passphrase.
  readonly property color sysNetHover: root.sheen.alpha(0.12)

  property int sysLockIcon: 12

  // the volume and gain sliders. the knob is centred on the end of the fill, so
  // at full it sits half outside the track, which is what the design draws.
  property int sysSliderTrack: 5
  property int sysSliderRadius: 3
  property int sysSliderKnob: 10
  property int sysSliderGap: 8
  property int sysSliderLabelSize: 10
  property int sysSliderLabelWidth: 26

  readonly property color sysSliderRail: root.sheen.alpha(0.1)

  // the power profile buttons: three of them sharing the width.
  property int sysProfileGap: 6
  property int sysProfilePaddingV: 7
  property int sysProfileRadius: 9
  property int sysProfileSize: 10

  readonly property color sysProfileOn: root.accent.alpha(0.14)
  readonly property color sysProfileOff: root.sheen.alpha(0.04)
  readonly property color sysSliderText: root.tint.alpha(0.6)

  // an output or input you could pick. two hex steps dimmer than a network name
  // in the same kind of row, and the design means it.
  readonly property color sysDeviceName: root.tint.alpha(0.58)

  // the passphrase row a locked network opens, and the refusal that can follow.
  property int sysFieldHeight: 45
  property int sysFieldPaddingH: 8
  property int sysFieldTop: 6
  property int sysFieldBottom: 8
  property int sysFieldGap: 6
  property int sysFieldInnerH: 8
  property int sysFieldInnerV: 6
  property int sysFieldRadius: 8
  property int sysFieldSize: 11
  property int sysJoinPaddingH: 10
  property int sysJoinPaddingV: 7
  property int sysJoinSize: 10
  property int sysErrorGap: 7
  property int sysErrorIcon: 13
  property int sysErrorSize: 10


  readonly property color sysFieldBorder: root.sheen.alpha(0.12)
  readonly property color sysFieldFill: root.sheen.alpha(0.05)
  readonly property color sysJoinFill: root.accent.alpha(0.16)
  readonly property color sysJoinHover: root.accent.alpha(0.26)
  readonly property color sysError: "#e06c75"

  readonly property color sysRowOpen: root.sheen.alpha(0.05)
  readonly property color sysNetActive: root.sheen.alpha(0.06)
  readonly property color sysLine: root.sheen.alpha(0.07)
  readonly property color switchTrack: root.sheen.alpha(0.13)
  readonly property color switchKnobOff: root.tint.alpha(0.55)

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
