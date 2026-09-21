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

  // every neutral in the design is one tint at a different alpha, so derive them
  // instead of pasting four near-identical rgba values.
  readonly property color tint: "#dce6f5"
  readonly property color text: root.tint
  readonly property color glyph: root.tint.alpha(0.85)
  readonly property color textDim: root.tint.alpha(0.55)

  // a toggle on the system strip that is off. it is dimmer than textDim because it
  // is not reporting anything -- it is a switch waiting to be pressed.
  readonly property color stripOff: root.tint.alpha(0.38)

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

  // a second frozen map beats mutating iconAxes, which would change every glyph at
  // once and emit no notify.
  //
  // **FILL is 0.995 and must not be 1.** Near the axis maximum qt rasterises these
  // outlines wrong: the glyph comes back speckled and eaten away, as though the
  // inner contour were being XORed out of the outer one rather than merged into it
  // -- a filled moon becomes a moon with holes in it. The window is narrow and it
  // is glyph by glyph: 0.997 already breaks the bell, 0.998 breaks everything, and
  // 0.99 is clean but leaves the moon's last sliver visibly unfilled at 14px. 0.995
  // is filled and clean for every glyph here. Verified by rendering a ramp through
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

  // no launcherTop: the panel is centred in the desktop opening instead, which
  // has to be worked out from the window's own height. windows/LauncherWindow.qml
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

  // the brightness row, which sits under the accordion and is not part of it.
  property int sysBrightPadding: 9
  property int sysBrightGap: 10
  property int sysBrightIcon: 17

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


  readonly property color sysFieldBorder: root.sheen.alpha(0.12)
  readonly property color sysFieldFill: root.sheen.alpha(0.05)
  readonly property color sysJoinFill: root.accent.alpha(0.16)
  readonly property color sysJoinHover: root.accent.alpha(0.26)
  readonly property color sysError: "#e06c75"

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

  property int capSwitchGap: 7
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
  readonly property color toastShadow: root.ink.alpha(0.45)
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

  property string uiFont: "Manrope"

  // Manrope is one variable file whose default named instance is ExtraLight, so
  // font.weight alone leaves a 600 heading looking like a hairline. pinning the
  // axis is the same fix the symbol font already needs.
  property var uiAxesSemiBold: ({ "wght": 600 })

  // and the same again for the one place the design asks for 700.
  property var uiAxesBold: ({ "wght": 700 })

  // css line-height:1.2 in a box. Text.implicitHeight follows the font's own line
  // spacing, which is taller, and would make every chip a few pixels fat.
  function lineBox(size: real): int {
    return Math.round(size * 1.2)
  }
}
