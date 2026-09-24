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
  // the colour below is kept only as a reminder of where this one came from.
  // readonly property color surface: "#0f1726"
  readonly property color frame: root.surface
  readonly property color notch: root.surface

  readonly property color accent: "#5aa2ff"
  readonly property color urgent: "#e4574f"

  // every neutral in the design is one tint at a different alpha, so derive them
  // instead of pasting four near-identical rgba values.
  readonly property color tint: "#dce6f5"
  readonly property color text: root.tint
  readonly property color glyph: root.tint.alpha(0.85)
  readonly property color textDim: root.tint.alpha(0.55)

  // a switch in the toggles tab that is off. it is dimmer than textDim because it
  // is not reporting anything -- it is a switch waiting to be pressed.
  readonly property color stripOff: root.tint.alpha(0.38)

  readonly property color workspaceActive: root.accent
  readonly property color workspaceUrgent: root.urgent
  readonly property color workspaceOccupied: "#6f87a8"
  readonly property color workspaceEmpty: root.tint.alpha(0.28)

  // how solid the focus mark is over the window it sits on: 1 is the accent at full
  // strength, which is where it has been left, and anything lower lets the window
  // read through it.
  //
  // this is alpha baked into the fill rather than an opacity on the item, because
  // FocusIndicator drives that property to fade the mark in and out and would
  // overwrite anything set here.
  property real focusOpacity: 1.0

  // the mark borrows the accent the same way the active workspace dot does,
  // instead of reaching for Theme.accent at the call site. the hyprland border it
  // stands in for was this exact colour.
  readonly property color focusColor: root.accent.alpha(root.focusOpacity)

  // every other window on screen gets the same mark in hyprland's own
  // inactive_border, rgba(595959aa) in looknfeel.lua -- the other half of the
  // border the focused mark stands in for. false marks the focused window only.
  property bool focusMarkUnfocused: true

  // how solid that grey is, on the same terms as focusOpacity: alpha in the fill,
  // because UnfocusedIndicators drives each mark's opacity to fade it in. 0.67 is
  // hyprland's own aa.
  property real focusUnfocusedOpacity: 1.0
  readonly property color focusUnfocusedBase: "#595959"
  readonly property color focusUnfocusedColor: root.focusUnfocusedBase.alpha(root.focusUnfocusedOpacity)

  property int borderWidth: 5

  // which monitors carry the tabs. "main" puts the tabs, their panels and the osd
  // on the main monitor -- the one workspace 1 is on, since hyprland has no
  // primary of its own -- and leaves the others the bare border, their top edge
  // given back to windows. "all" gives every monitor its own set of tabs, with
  // keybinds, ipc and the osd going to whichever one is focused.
  property string tabScreens: "main"
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

  // hyprland fires several geometry events at once when a window opens or closes:
  // one refresh for the burst, and one more once the reflow has finished.
  property int focusDebounce: 30
  property int focusSettle: 200

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

  // how round the bar's own outer corners are -- the pair away from the window,
  // not the horns, which have to keep following windowRadius to stay on the same
  // curve the window does. do not scale it to the thickness: half the thickness is
  // round in the arithmetic and square to the eye, because the horn makes the outer
  // edge four times taller than the bar. 0 squares them off; FocusStrip clamps
  // anything too large for the shape to hold.
  // the line below is what this followed before it became its own token, kept as a
  // reminder of where the value came from.
  // property int focusStripEndRadius: root.windowRadius
  property int focusStripEndRadius: 8

  property int systemSpacing: 9
  property int batterySpacing: 5

  // the toggles tab: how far clear of the system tab it floats, and how far apart
  // its switches sit. both are the design's own, and the switches are further apart
  // than the system tab's glyphs because each one is a button rather than a report.
  property int togglesGap: 28
  property int togglesSpacing: 11

  // the rule under the strip icon whose section the system panel is showing. the
  // design draws it as a text-decoration, 1.5px thick and 4px clear of the glyph;
  // it is a rectangle here because a font underline honours neither figure.
  property real stripUnderline: 1.5
  property int stripUnderlineGap: 4

  // font.pixelSize is an int, and a real handed to it is rounded half up: the
  // design's 9.5, 11.5 and 12.5 draw at 10, 12 and 13, measured. they are written
  // here as the design gives them, so the record of what it asked for survives,
  // but no text in the shell is ever a half pixel.
  //
  // "JetBrains Mono" does not resolve on this machine, it falls back to DejaVu.
  // the nerd font patch is the only build installed and keeps the upstream
  // metrics, so the design's advance widths still land where the mockup put them.
  property string monoFont: "JetBrainsMono Nerd Font"

  property string uiFont: "Manrope"

  // Manrope is one variable file whose default named instance is ExtraLight, so
  // font.weight alone leaves a 600 heading looking like a hairline. pinning the
  // axis is the same fix the symbol font already needs.
  property var uiAxesSemiBold: ({ "wght": 600 })

  // and the same again for the one place the design asks for 700.
  property var uiAxesBold: ({ "wght": 700 })

  // and for the clock's own lines, which the design sets at 500.
  property var uiAxesMedium: ({ "wght": 500 })

  // and for body text, which the design leaves at 400. without it a toast's body
  // or a calendar event reads at the file's ExtraLight default.
  property var uiAxesRegular: ({ "wght": 400 })

  property string iconFont: "Material Symbols Rounded"

  // material symbols ship as one variable font, and four axes shape every icon on
  // the frame:
  //   FILL  0 outlined, 1 solid. values between work.
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

  // a second frozen map beats mutating iconAxes, which would change every glyph at
  // once and emit no notify.
  //
  // FILL is 0.995 and must not be 1. near the axis maximum qt rasterises these
  // outlines wrong: the glyph comes back speckled and eaten away, as though the
  // inner contour were being XORed out of the outer one rather than merged into it
  // -- a filled moon becomes a moon with holes in it. the window is narrow and it
  // is glyph by glyph: 0.997 already breaks the bell, 0.998 breaks everything, and
  // 0.99 is clean but leaves the moon's last sliver visibly unfilled at 14px. 0.995
  // is filled and clean for every glyph here. verified by rendering a ramp through
  // qt and the same names through chromium from the very same font file, where FILL
  // 1 is correct -- so this is qt, not the font, and not the design asking for
  // something the font cannot do.
  property var iconAxesFilled: ({
    "FILL": 0.995,
    "wght": 400,
    "GRAD": 0,
    "opsz": 24
  })

  // the launcher dims the whole screen behind itself. the only colour in the
  // design not derived from the frame's palette, because it is the desktop seen
  // through smoked glass rather than a surface of the shell.
  readonly property color shade: "#06090e"
  readonly property color ink: "#000000"

  // every raised surface inside the panel is white at one of three alphas over
  // the notch colour, the same trick the frame plays with tint.
  readonly property color sheen: "#ffffff"

  readonly property color launcherScrim: root.shade.alpha(0.55)
  readonly property color launcherShadow: root.ink.alpha(0.5)

  // the design gives the notches a two layer elevation shadow: a soft ambient
  // spread, plus a tight contact line right under the edge. qt takes blur as the
  // pixel distance the falloff reaches, fed to a smoothstep over a signed distance
  // field, rather than a gaussian sigma, so css blur radii transfer at about 1.2x.
  // the alphas are dials like the blurs and offsets below, not literals buried in
  // a colour expression: darkening the shadow is the one adjustment worth making
  // without enlarging it. these were .34 and .28 in the design, deepened here
  // because it was drawn against a lighter surface than this shell runs -- and the
  // design has since taken these values back.
  property real notchShadowAmbientAlpha: 0.45
  property real notchShadowContactAlpha: 0.38

  readonly property color notchShadowAmbient: root.ink.alpha(root.notchShadowAmbientAlpha)
  readonly property color notchShadowContact: root.ink.alpha(root.notchShadowContactAlpha)

  property real notchShadowAmbientBlur: 17
  property real notchShadowAmbientOffset: 5
  property real notchShadowContactBlur: 4
  property real notchShadowContactOffset: 1

  // spread grows the silhouette before the falloff is applied, so it thickens the
  // dark core rather than reaching further with the same fade. the design had none
  // at all until it adopted these, and it is the dial with the most effect per
  // unit if the shadow ever wants more weight.
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

  // how long a tab takes to grow into its panel, and every fold that grows the
  // same way.
  property int notchExpandDuration: 240

  // named for the notch, but it is the shell's one hover fade: every colour that
  // answers a pointer uses it, here and in the panels. the design's own most
  // common transition is .16s and this is it.
  property int notchFadeDuration: 160

  // a control that moves rather than fades -- the switch knob travelling across
  // its track, a row's chevron turning over. the design gives both .2s.
  property int controlMoveDuration: 200

  // the design uses one easing curve everywhere, css cubic-bezier(.2,.8,.2,1).
  // Easing.Bezier wants the two control points followed by the end point, which is
  // always 1,1.
  readonly property var easeStandard: [0.2, 0.8, 0.2, 1.0, 1.0, 1.0]

  // css cubic-bezier(.4, 0, .2, 1): the lock screen's way in and out, which
  // starts slower than the notches do.
  readonly property var easeExit: [0.4, 0.0, 0.2, 1.0, 1.0, 1.0]

  // the workspace panel: one pill per workspace, the same states the dots show.
  property int wsPillSize: 30
  property int wsPillRadius: 10
  property int wsPillSpacing: 4
  property int wsPillTextSize: 13

  // dark text for anything sitting on a lit accent surface: a workspace pill, the
  // calendar's today. the rest are a wash over the surface, the same sheen the
  // launcher raises its rows with.
  readonly property color litText: "#081018"
  readonly property color wsPillOccupied: root.sheen.alpha(0.09)
  readonly property color wsPillEmpty: root.sheen.alpha(0.04)
  readonly property color wsPillEmptyText: root.tint.alpha(0.38)

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

  // the clock panel's vertical rhythm, top to bottom: under the date, above the
  // month, between the month's name and its grid, under the grid, and above the
  // events. the design writes each as its own margin.
  property int clockRuleTop: 12
  property int calTop: 10
  property int calNavBottom: 8
  property int calBottom: 13
  property int eventTop: 11
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

  // the WK heading over the week column, a shade quieter than the day headings
  // beside it and than the numbers under it.
  readonly property color calWeekHeadText: root.tint.alpha(0.28)
  readonly property color calWeekText: root.tint.alpha(0.3)
  readonly property color calDayText: root.tint.alpha(0.72)
  readonly property color calNavText: root.tint.alpha(0.55)

  // the event dots under a day number, one per calendar with something on that
  // day, and the wash a selected day sits on.
  property int calDotSize: 3
  property int calDotGap: 2
  property real calDotSpacing: 1.5
  readonly property color calSelectedBg: root.accent.alpha(0.16)

  property int eventIcon: 18
  property int eventTitleSize: 12
  property int eventDetailSize: 11
  property int eventGap: 10
  property int eventRowGap: 8

  // the time column of an event row: the design's 9.5px, which draws at 10 --
  // see the note on half-pixel sizes over monoFont.
  property real eventTimeSize: 9.5
  property int eventTimeWidth: 32
  property int eventLineHeight: 15

  // the bar at the start of a row, in its calendar's colour, and the gap between
  // it, the time and the title.
  property int eventBarWidth: 2
  property int eventBarGap: 8

  // the legend of calendars under the list: a dot and a name per calendar.
  property int legendDot: 5
  property int legendDotGap: 5
  property int legendItemGap: 11
  property int legendRowGap: 4
  property int legendTop: 3
  property real legendSize: 9.5
  readonly property real legendSpacing: root.legendSize * 0.03
  readonly property color legendText: root.tint.alpha(0.45)

  // rows past this fold into "+N more": the panel is a glance, not a diary.
  property int eventMax: 4

  readonly property color eventText: root.tint.alpha(0.72)

  // "No events" and its siblings, and the "+N more" line.
  readonly property color eventEmptyText: root.tint.alpha(0.5)

  // how old the calendar file may be when the tab opens before the fetcher is
  // asked to run again. ms.
  property int calSyncStale: 300000

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

  // no launcherTop: the panel is placed in the desktop opening instead, by the
  // share of the free space launcherBias names below. windows/LauncherWindow.qml
  // does the arithmetic and says why.

  // how far above its resting place the panel starts, and falls back to on the
  // way out.
  property int launcherRise: 12

  // how the free space above and below the launcher is split. 0.5 is centred;
  // this sits it in the optical upper third, where a panel reads as placed rather
  // than as floating -- and where the clipboard's preview has somewhere to grow
  // into without crowding the bottom of the screen.
  //
  // it applies to every category, not only the ones that are tall. the panel is
  // positioned on the height it would have with the grid full, so the top never
  // moves between categories, and that is worth more than the perfect balance of
  // any one of them.
  property real launcherBias: 0.38

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
  property int sysRowPaddingV: 8
  property int sysRowGap: 10
  property int sysRowIcon: 17
  // the design sets a row's title apart from its contents by weight and size as
  // well as by the well below: 600 at 12.5 against the 12 of everything inside.
  property real sysRowLabelSize: 12.5
  property int sysRowValueSize: 12
  property int sysChevron: 15

  // what folds out of a row sits in a sunken well, inset from the row's own edges,
  // so the title above it reads as a title rather than as the first line of it.
  property int sysWellMargin: 6
  property int sysWellRadius: 9
  property int sysWellPaddingH: 10
  property int sysWellTop: 10
  property int sysWellBottom: 11
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

  // how often the network row pings and re-reads its counters while it is open.
  property int sysNetPoll: 10000

  // the pill switch. 2 + 11 + 11 + 2 is the design's 26, which is why the knob's
  // travel is exactly its own width.
  property int switchWidth: 26
  property int switchHeight: 15
  property int switchPadding: 2
  property int switchKnob: 11
  property real switchDisabledOpacity: 0.4

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

  // how far the keyboard's wash reaches past a switch row on every side. the well
  // pads its contents by sysWellPaddingH, so this stays inside the well.
  property int keyWashInset: 5

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

  // the glyph beside a slider in the display section. it outlived the brightness
  // row it was named for: the design folded that row into display, and what is left
  // of it is components/DisplaySlider.qml.
  readonly property color sysBrightGlyph: root.tint.alpha(0.6)

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

  // how long a refused join's reason stays under its row.
  property int sysErrorLinger: 1800

  readonly property color sysFieldBorder: root.sheen.alpha(0.12)
  readonly property color sysFieldFill: root.sheen.alpha(0.05)
  readonly property color sysJoinFill: root.accent.alpha(0.16)
  readonly property color sysJoinHover: root.accent.alpha(0.26)
  readonly property color sysError: "#e06c75"

  // the card a bluetooth device opens under itself while bluez has a question.
  // its left inset is the row's own padding, glyph and gap, so the card's text
  // starts under the device's name rather than under its icon.
  readonly property int btCardInset: root.sysNetPaddingH + root.sysNetIcon + root.sysNetGap
  property int btCardTop: 3
  property int btCardBottom: 9
  property int btCardGap: 10
  property int btCardTextGap: 7
  property int btCardTextSize: 11
  property int btCardTextLine: 15
  property int btCodeSize: 22
  readonly property real btCodeSpacing: root.btCodeSize * 0.08
  property int btDigitWidth: 15
  property int btDigitSplit: 9
  property real btCounterSize: 9.5
  property int btButtonGap: 6
  property int btButtonPaddingH: 11
  property int btButtonPaddingV: 7
  property int btButtonRadius: 8
  property int btButtonSize: 10
  property real btButtonRing: 1.5
  property int btFieldPaddingH: 8
  property int btFieldPaddingV: 6
  property real btFieldSize: 10.5
  property int btCancelledIcon: 13
  property int btCancelledSize: 10
  property real btLockedOpacity: 0.45
  property real btPrimaryDisabledOpacity: 0.45
  property int btFold: 240

  // how long a refusal stays on a row, and how long "pairing cancelled" is shown
  // before its card folds away.
  property int btFailLinger: 2600
  property int btCancelLinger: 1500

  // pairing and paired can arrive from bluez in either order, so a pairing that
  // stopped is judged this long later. and one that never moves at all is given
  // up on after the longer wait.
  property int btPairSettle: 500
  property int btPairTimeout: 20000

  readonly property color btCardText: root.tint.alpha(0.72)
  readonly property color btCode: root.tintBright
  readonly property color btDigitDim: root.tint.alpha(0.3)
  readonly property color btCounter: root.tint.alpha(0.4)
  readonly property color btSecondaryText: root.tint.alpha(0.7)
  readonly property color btSecondaryRing: root.tint.alpha(0.55)
  readonly property color btCancelledIconColor: root.tint.alpha(0.5)
  readonly property color btCancelledText: root.tint.alpha(0.6)

  readonly property color sysRowOpen: root.sheen.alpha(0.05)

  // sunk into the row rather than lifted off it. .42 in the design at first, where
  // that darkened an open row by 27% against its lighter surface and only 23%
  // against this one; deepened here to land on the same step, and the design has
  // since taken this value back.
  readonly property color sysWell: Qt.rgba(8 / 255, 13 / 255, 24 / 255, 0.52)
  readonly property color sysNetActive: root.sheen.alpha(0.06)
  readonly property color sysLine: root.sheen.alpha(0.07)
  readonly property color switchTrack: root.sheen.alpha(0.13)
  readonly property color switchKnobOff: root.tint.alpha(0.55)

  // the polkit dialog: a modal card asking for a password when something
  // privileged is attempted. the design writes its type in halves again, so the
  // sizes are rounded the way every other panel's are.
  property int pkWidth: 404
  property int pkGutter: 18
  property int pkHeadTop: 18
  property int pkHeadBottom: 14
  property int pkHeadGap: 13
  property int pkTitleGap: 6
  property int pkChipSize: 38
  property int pkChipRadius: 11
  property int pkChipIcon: 21
  property int pkTitleSize: 14
  property int pkMessageSize: 12

  // css line-height:1.5. qml's lineHeight multiplies the font's own line spacing,
  // which is already taller than the pixel size, so the ratio has to be turned
  // into a fixed box or the paragraph comes out airy.
  readonly property int pkMessageLine: Math.round(root.pkMessageSize * 1.5)

  property int pkIdentityPaddingH: 12
  property int pkIdentityPaddingV: 10
  property int pkIdentityRadius: 11
  property int pkIdentityGap: 10
  property int pkIdentityCircle: 26
  property int pkIdentityIcon: 15
  property int pkIdentityNameSize: 12
  property int pkIdentitySubSize: 10
  property int pkIdentityTextGap: 3

  property int pkFieldTop: 12
  property int pkFieldGap: 7
  property int pkFieldHeight: 38
  property int pkFieldPaddingH: 11
  property int pkFieldRadius: 10
  property int pkFieldIconGap: 9
  property int pkFieldGlyph: 15
  property int pkFieldSize: 12
  property int pkEyeSize: 16

  property int pkNoteHeight: 16
  property int pkNoteGap: 6
  property int pkNoteIcon: 12
  property int pkNoteSize: 10

  // one turn of the glyph that spins while pam is thinking.
  property int noteSpin: 900

  property int pkDetailsTop: 6
  property int pkDetailsGap: 5
  property int pkDetailsChevron: 14
  property int pkDetailsCapSize: 10
  property int pkDetailsBoxTop: 8
  property int pkDetailsBoxPaddingH: 11
  property int pkDetailsBoxPaddingV: 9
  property int pkDetailsBoxRadius: 10
  property int pkDetailsRowGap: 6
  property int pkDetailsColGap: 10
  property int pkDetailsKeyWidth: 62
  property int pkDetailsKeySize: 9
  property int pkDetailsValueSize: 10
  property int pkDetailsLine: 14
  readonly property real pkDetailsKeySpacing: root.pkDetailsKeySize * 0.06

  property int pkButtonsTop: 14
  property int pkButtonsBottom: 16
  property int pkButtonsGap: 8
  property int pkButtonPaddingV: 10
  property int pkButtonRadius: 10
  property int pkButtonSize: 12

  // the card lifts further off the desktop than anything else in the shell, and
  // the design hangs a hairline outline on it as well as the shadow.
  property real pkShadowBlur: 80
  property real pkShadowOffset: 30
  property real pkScaleFrom: 0.96
  property int pkFade: 160
  property int pkRise: 200

  // the mock flow's pam: how long it thinks, and how long an accepted card stays
  // up before it goes, which is the design's own hold.
  property int pkMockVerdict: 600
  property int pkMockSettle: 1100

  // the chip behind the admin glyph, and the colour of a passphrase accepted.
  // neither is anywhere else in the shell yet.
  readonly property color elevated: "#f0a35e"
  readonly property color success: "#8fd48a"

  readonly property color pkScrim: root.shade.alpha(0.6)
  readonly property color pkShadow: root.ink.alpha(0.55)
  readonly property color pkOutline: root.sheen.alpha(0.05)
  readonly property color pkChipFill: root.elevated.alpha(0.13)
  readonly property color pkMessageText: root.tint.alpha(0.58)
  readonly property color pkIdentityFill: root.sheen.alpha(0.04)
  readonly property color pkIdentityCircleFill: root.accent.alpha(0.16)
  readonly property color pkIdentitySub: root.tint.alpha(0.4)
  readonly property color pkFieldFill: root.sheen.alpha(0.05)
  readonly property color pkFieldBorder: root.sheen.alpha(0.12)
  readonly property color pkFieldBorderError: root.sysError.alpha(0.55)
  readonly property color pkFieldBorderOk: root.success.alpha(0.5)
  readonly property color pkFieldGlyphColor: root.tint.alpha(0.4)
  readonly property color pkEye: root.tint.alpha(0.42)
  readonly property color pkEyeHover: root.tint.alpha(0.8)
  readonly property color pkNoteIdle: root.tint.alpha(0.45)
  readonly property color pkDetailsFill: root.sheen.alpha(0.03)
  readonly property color pkDetailsCap: root.tint.alpha(0.4)
  readonly property color pkDetailsKey: root.tint.alpha(0.35)
  readonly property color pkDetailsValue: root.tint.alpha(0.6)
  readonly property color pkCancelFill: root.sheen.alpha(0.06)
  readonly property color pkCancelHover: root.sheen.alpha(0.1)
  readonly property color pkCancelText: root.tint.alpha(0.7)
  readonly property color pkDoneFill: root.success.alpha(0.2)

  // the lock screen. how long the desktop may sit idle before it locks, and how
  // long the lock may then sit idle before the screen goes off -- in seconds,
  // which is what IdleMonitor counts in. the design's stay awake row says "idle
  // after 10 min", and this is that ten minutes.
  // how long a python helper -- the lock's, the pairing agent -- stays down after
  // it exits before it is started again.
  property int helperRespawn: 5000

  property int lockIdle: 600
  property int lockBlank: 60

  // the design's column starts 208px down a 900px screen. a fraction rather than
  // the pixels, so it sits the same way on a 960 and a 1440 high monitor.
  property real lockTop: 0.231

  property int lockClockSize: 136
  readonly property real lockClockSpacing: -root.lockClockSize * 0.02
  property int lockDateTop: 20
  property int lockDateSize: 19
  readonly property real lockDateSpacing: root.lockDateSize * 0.01
  property int lockPromptTop: 62
  property int lockPromptWidth: 300
  property int lockPromptGap: 14
  property int lockPromptRise: 8

  property int lockTileSize: 38
  property int lockTileRadius: 11
  property int lockTileText: 16
  property int lockIdentityGap: 11
  property int lockNameSize: 14

  property int lockFingerGlyph: 20
  property int lockFingerGap: 8
  property real lockFingerSize: 11.5
  property int lockFingerLine: 15

  // the field is the polkit dialog's, give or take its fill.
  property int lockFieldGap: 8
  property int lockCapsGap: 6
  property int lockNoteLine: 15

  // the picture behind it: the wallpaper, blurred, desaturated and darkened, and
  // a second wash of the surface over that. the secondary screens are darker
  // still, since nothing on them is asking for anything.
  property real lockBlur: 34
  property real lockSaturation: -0.2
  property real lockBright: 0.62
  property real lockBrightSecondary: 0.42
  property real lockBackdropScale: 1.06
  property real lockClockDim: 0.55

  // the time from locking to the prompt being usable, and from the right
  // password to the desktop.
  property int lockWake: 900
  property int lockExit: 450
  property int lockExitContent: 350
  property real lockExitScale: 1.04
  property int lockPromptFade: 220
  property int lockPromptMove: 260
  property int lockShake: 360
  property int lockFingerHold: 2400
  property int lockFingerOk: 700

  // a fingerprint conversation that was listening and gave up starts again after
  // this; caps lock is asked about this long after each key, once the keyboard
  // has had time to report it.
  property int lockFingerRetry: 1000
  property int lockCapsDelay: 80

  readonly property color lockWash: root.shade
  readonly property real lockWashAlpha: 0.38
  readonly property color lockFieldFill: root.surface.alpha(0.6)
  readonly property color lockFieldBusy: root.accent.alpha(0.4)
  readonly property color lockFingerText: root.tint.alpha(0.7)
  readonly property color lockFingerIdle: root.tint.alpha(0.72)
  readonly property color lockDateText: root.tint.alpha(0.72)
  readonly property color lockBadge: root.tint.alpha(0.7)

  // the confirmation in front of a power action. it borrows the polkit card's
  // width, shadow and entry animation -- the design draws them identically -- and
  // differs in its type and its buttons: pills that hug their labels, centred,
  // rather than two half-width ones.
  property int cfPaddingTop: 26
  property int cfPaddingH: 24
  property int cfPaddingBottom: 20
  property int cfGap: 14
  property int cfTitleGap: 7
  property int cfChipSize: 56
  property int cfChipRadius: 15
  property int cfChipIcon: 26
  property int cfTitleSize: 17
  property real cfExecSize: 11.5
  property int cfButtonsTop: 2
  property int cfButtonsGap: 10
  property int cfButtonPaddingH: 22
  property int cfButtonPaddingV: 10
  property int cfButtonSize: 12
  property int cfHintSize: 10
  readonly property real cfHintSpacing: root.cfHintSize * 0.02

  // a hair darker than the polkit scrim, which the design writes as .62 against
  // that card's .6. it sits over the launcher rather than over the desktop.
  readonly property color cfScrim: root.shade.alpha(0.62)
  readonly property color cfChipFill: root.accent.alpha(0.12)

  // the design hovers the confirm button with filter:brightness(1.08), which has
  // no equivalent here -- a lighter accent is the same idea at the same strength.
  readonly property color accentLift: Qt.lighter(root.accent, 1.08)
  readonly property color cfExecText: root.tint.alpha(0.45)
  readonly property color cfHintText: root.tint.alpha(0.32)

  // the clipboard preview under the launcher's list: the same sunken well the
  // system panel's rows fold into, since it is the same idea -- contents set
  // apart from the thing that named them.
  property int clipPreviewMargin: 10
  property int clipPreviewBottom: 12
  property int clipPreviewPaddingH: 12
  property int clipPreviewTop: 11
  property int clipPreviewGap: 9
  property int clipPreviewRadius: 11
  property int clipPreviewTextMax: 104
  property int clipPreviewTextSize: 11
  readonly property real clipPreviewTextLine: root.clipPreviewTextSize * 1.55
  property int clipPreviewSwatch: 52
  property int clipPreviewSwatchRadius: 10
  property int clipPreviewSwatchGap: 11
  property int clipPreviewValueSize: 13
  property int clipPreviewImageHeight: 120
  property int clipPreviewImageRadius: 10
  property int clipPreviewImageGlyph: 24
  property int clipPreviewNameSize: 10
  property real clipPreviewMetaSize: 9.5
  property int clipPreviewFootGap: 8

  // the chequerboard behind a transparent image, the design's 16px squares.
  property int clipCheckerTile: 16

  // the preview decodes this long after the selection stops moving, so arrowing
  // through the list does not run a process per keystroke.
  property int clipSettle: 120

  readonly property color clipPreviewFill: root.sysWell
  readonly property color clipPreviewText: root.tint.alpha(0.86)
  readonly property color clipPreviewMeta: root.tint.alpha(0.35)
  readonly property color clipPreviewHint: root.tint.alpha(0.38)
  readonly property color clipPreviewName: root.tint.alpha(0.6)
  readonly property color clipPreviewRing: root.sheen.alpha(0.12)
  readonly property color clipPreviewImageRing: root.sheen.alpha(0.07)
  readonly property color clipPreviewChecker: root.sheen.alpha(0.045)

  // the capture block at the foot of the system panel: two mode tiles, a target
  // selector and one button. it is not a row and does not fold.
  property int capGap: 9
  property int capTileGap: 8
  property int capTileTop: 9
  property int capTileBottom: 8
  property int capTileRadius: 12
  property int capTileInnerGap: 6
  property int capTileCircle: 26
  property int capTileIcon: 15
  property int capTileLabelSize: 10

  property int capTargetGap: 8
  property int capTrackPadding: 3
  property int capTrackRadius: 9
  property int capSegmentGap: 4
  property int capSegmentRadius: 7
  property int capSegmentPaddingV: 5
  property int capSegmentSize: 10

  // the picked colour, in the same sunken well the panel's rows fold into.
  property int capPickGap: 10
  property int capPickPaddingH: 10
  property int capPickPaddingV: 9
  property int capPickRadius: 10
  property int capPickSwatch: 30
  property int capPickSwatchRadius: 8
  property real capPickValueSize: 11.5
  property int capPickTextGap: 4

  property int capSwitchLabelSize: 11

  property int capButtonPaddingV: 9
  property int capButtonRadius: 11
  property real capButtonSize: 11.5
  readonly property real capButtonSpacing: root.capButtonSize * 0.03

  // how long the button says "Captured!" before going back to asking. the design
  // holds it for 1.4s, which is long enough to read and short enough not to nag.
  property int capFlash: 1400

  // the panel has to be gone before the shutter, or it is in the picture -- and
  // slurp cannot have the pointer while the panel is holding a focus grab.
  readonly property int capSettle: root.notchExpandDuration + 60

  // how long after hyprpicker starts before the pointer is nudged: long enough for
  // its overlay to be up and listening for the motion.
  property int capNudge: 400

  readonly property color capTileOn: root.accent.alpha(0.12)
  readonly property color capTileOff: root.sheen.alpha(0.04)
  readonly property color capChipOff: root.sheen.alpha(0.07)
  readonly property color capTileText: root.tint.alpha(0.62)
  readonly property color capTrack: root.sheen.alpha(0.05)
  readonly property color capSegmentOn: root.accent.alpha(0.16)
  readonly property color capSegmentText: root.tint.alpha(0.55)
  readonly property color capSwitchLabel: root.tint.alpha(0.72)
  readonly property color capBusyFill: root.accent.alpha(0.22)

  // the display section: two toggles over the brightness slider, and a
  // temperature slider that appears with the night light.
  property int dispToggleGap: 8
  property int dispToggleIcon: 15
  property int dispToggleTextGap: 3
  property int dispToggleLabelSize: 11
  property real dispToggleSubSize: 9.5
  property int dispTempLabelWidth: 34

  // hyprsunset takes 1000K to 20000K, which is far more than a night light means.
  // the design puts 4200K at 42% of its track, and 2500..6500 is the range that
  // lands it there -- 6500 being daylight, where the slider stops doing anything.
  property int dispTempMin: 2500
  property int dispTempMax: 6500
  property int dispTempDefault: 4200

  // a drag reaches hyprsunset and the state file this long after it stops moving.
  property int dispSettle: 120

  readonly property color dispToggleLabel: root.tint.alpha(0.82)
  readonly property color dispToggleSub: root.tint.alpha(0.4)
  readonly property color dispToggleOff: root.tint.alpha(0.4)

  // notifications. the toasts hang off the top right, clear of the band and the
  // notches; the design writes their offsets from the screen edge, not the frame.
  property int toastTop: 50

  // and where they sit while the osd is out of the same corner. the design's own
  // number rather than the osd's measured height plus a gap: it is the position it
  // was drawn at, and the two boxes are different heights here anyway.
  property int toastTopOsd: 124
  property int toastRight: 14
  property int toastWidth: 308
  property int toastGap: 8
  property int toastPaddingH: 14
  property int toastPaddingV: 13
  property int toastRadius: 14
  property int toastRowGap: 11
  property int toastChipSize: 30
  property int toastChipRadius: 9
  property int toastChipIcon: 16
  property int toastTextGap: 5
  property int toastAppSize: 11
  property real toastTimeSize: 9.5
  property int toastBodySize: 11
  readonly property int toastBodyLine: 15
  property int toastActionsTop: 3
  property int toastActionsGap: 6
  property int toastActionPaddingH: 11
  property int toastActionPaddingV: 6
  property int toastActionRadius: 8
  property int toastActionSize: 10
  property real toastDismissSize: 9.5
  property int toastDismissPaddingH: 11
  property int toastDismissPaddingV: 6
  readonly property real toastDismissSpacing: root.toastDismissSize * 0.07

  // the bluetooth toast's "OPEN BLUETOOTH", which stands where an ordinary
  // toast's buttons would.
  property real toastLinkSize: 9.5
  readonly property real toastLinkSpacing: root.toastLinkSize * 0.07
  property int toastLinkTop: 2

  // four on screen, and the ones behind the first sit back a little further with
  // every card, which is how the design says a stack rather than a list.
  property int toastMax: 4
  property real toastFadeStep: 0.04
  property int toastSlide: 20
  property int toastEnter: 260

  // 5.2 seconds is the design's. a client asking for its own timeout gets it, and
  // a critical notification gets none at all.
  property int toastTimeout: 5200

  readonly property color toastFill: root.notch.alpha(0.94)
  readonly property color toastChipFill: root.sheen.alpha(0.06)
  readonly property color toastTime: root.tint.alpha(0.35)
  readonly property color toastBody: root.tint.alpha(0.66)
  readonly property color toastActionFill: root.sheen.alpha(0.06)
  readonly property color toastActionHover: root.sheen.alpha(0.12)
  readonly property color toastActionText: root.tint.alpha(0.7)
  readonly property color toastPrimaryFill: root.accent.alpha(0.16)
  readonly property color toastPrimaryHover: root.accent.alpha(0.26)
  readonly property color toastDismissText: root.tint.alpha(0.55)

  // and the history, inside the system panel
  property int notifListMax: 186
  property int notifEntryGap: 2
  property int notifEntryPaddingH: 8
  property int notifEntryPaddingV: 7
  property int notifEntryRadius: 9
  property int notifEntryGlyph: 14
  property int notifEntryTextGap: 4
  property int notifAppSize: 11
  property real notifTimeSize: 9.5
  property real notifBodySize: 10.5
  readonly property int notifBodyLine: 14
  property int notifEmptySize: 11

  readonly property color notifEntryHover: root.sheen.alpha(0.12)
  readonly property color notifBody: root.tint.alpha(0.6)
  readonly property color notifEmpty: root.tint.alpha(0.4)
  readonly property color notifDim: root.tint.alpha(0.45)
  readonly property color notifClear: root.tint.alpha(0.45)
  readonly property color notifClearHover: root.tint.alpha(0.85)

  // the on-screen display: the box that drops out of the system tab when the
  // volume or the brightness keys are pressed.
  //
  // it is wider than the strip it hangs from, which is what osdWiden says, so its
  // left corners are exposed and take the tab's own radius while its right edge
  // stays flush against the border.
  property int osdWiden: 34
  property int osdGap: 13
  property int osdPaddingH: 16
  property int osdPaddingTop: 13
  property int osdPaddingBottom: 14
  property int osdGlyphSize: 22
  property int osdColumn: 172
  property int osdColumnGap: 7
  property real osdTitleSize: 11
  property real osdValueSize: 11
  property int osdTrack: 5
  property int osdTrackRadius: 3

  readonly property color osdTitleText: root.tintBright
  readonly property color osdValueText: root.tint.alpha(0.6)
  readonly property color osdRail: root.sheen.alpha(0.1)
  readonly property color osdFill: root.accent

  // a muted volume still draws its bar, at nothing, in a colour that is not the
  // accent: the design says the level is zero and says why in the same glance.
  readonly property color osdFillMuted: root.tint.alpha(0.35)

  // how long it stays up after the last change.
  property int osdHold: 1700

  // the drop-in: from ten pixels high, squashed to 0.82 and transparent, over the
  // notch's own easing.
  property int osdDuration: 200
  property int osdRise: 10
  property real osdSquash: 0.82

  // the bar tracks the value rather than jumping to it, as the design's
  // `transition: width .14s` does.
  property int osdFillDuration: 140

  // css line-height:1.2 in a box. Text.implicitHeight follows the font's own line
  // spacing, which is taller, and would make every chip a few pixels fat.
  function lineBox(size: real): int {
    return Math.round(size * 1.2)
  }
}
