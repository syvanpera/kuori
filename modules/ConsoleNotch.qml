import QtQuick
import QtQuick.Shapes
import Quickshell.Hyprland
import qs.components
import qs.services
import qs.theme

// the quake console's notch: while Theme.consoleWorkspace is showing on this
// monitor, the frame grows down around its windows the way a tab grows round its
// panel. surface from the top band to the console's top edge, a rim beside and
// below it, and the tabs' own fillets where it meets the band, with the console
// punched out of the middle by the odd-even rule -- the same trick the frame uses
// for the desktop, and for the same reason: the hole has to be truly transparent.
//
// this is drawn above every window, so it cannot sit behind the console. it sits
// round it instead, which is why the hole follows the window's own rounding.
//
// nothing reports hyprland's slide while it runs, so the way in does not try to
// follow it: the notch fades in at full size as the console opens, and the window
// slides down from under the top band into a slot already waiting for it. the
// opening curve covers hundreds of pixels in its first frame, so a notch even one
// frame late would be visibly out of step. the way out starts slowly, so there the
// notch goes up with the window, on hyprland's own curve and duration, and
// disappears into the band of the same colour above it. held back instead, it was
// an empty outline over the desktop for most of its wait.
Item {
  id: root

  required property HyprlandMonitor monitor

  readonly property bool showing: Theme.consoleWorkspace !== ""
    && SpecialWorkspaces.on(root.monitor?.name ?? "") === Theme.consoleWorkspace

  // the console's windows, in global logical pixels less the monitor's origin, as
  // in FocusIndicator.
  readonly property var live: SpecialWorkspaces.windows(root.monitor)
    .map(r => Qt.rect(r.x - (root.monitor?.x ?? 0), r.y - (root.monitor?.y ?? 0), r.width, r.height))

  readonly property bool lit: root.showing && root.live.length > 0

  // whether a tab sits across the top of the notch, and so is part of it: the same
  // colour, with its fillets and its rounded bottom all over notch. only its shadow
  // still says it is a tab, falling through the hole onto the console's top rows,
  // so the frame drops the shadow of a tab this answers yes for.
  function covers(item: Item): bool {
    return root.lit && item.x >= root.outerLeft && item.x + item.width <= root.outerRight
  }

  // the last windows the console had, so a notch fading out after its last window
  // closed fades where it was rather than collapsing to the corner.
  property var windows: []

  Binding {
    root.windows: root.live
    when: root.live.length > 0
    restoreMode: Binding.RestoreNone
  }

  // the box they fill together, which the rim goes round.
  readonly property rect box: {
    if (root.windows.length === 0) return Qt.rect(0, 0, 0, 0)

    const left = Math.min(...root.windows.map(r => r.x))
    const top = Math.min(...root.windows.map(r => r.y))
    const right = Math.max(...root.windows.map(r => r.x + r.width))
    const bottom = Math.max(...root.windows.map(r => r.y + r.height))

    return Qt.rect(left, top, right - left, bottom - top)
  }

  // one hole per window, not one for the box: two windows side by side are each
  // rounded, and a single hole left a wedge of desktop between their corners.
  // each is inset by the bleed, so the notch overlaps the window's antialiased edge
  // instead of leaving a hairline of desktop round it, and so neighbours' holes
  // never touch: an overlap would fill back in under the odd-even rule.
  readonly property string holes: root.windows.map(w => {
    const r = Theme.windowRadius - root.bleed
    const x = w.x + root.bleed, y = w.y + root.bleed
    const x2 = w.x + w.width - root.bleed, y2 = w.y + w.height - root.bleed

    return `M ${x + r} ${y} H ${x2 - r} A ${r} ${r} 0 0 1 ${x2} ${y + r} `
      + `V ${y2 - r} A ${r} ${r} 0 0 1 ${x2 - r} ${y2} `
      + `H ${x + r} A ${r} ${r} 0 0 1 ${x} ${y2 - r} `
      + `V ${y + r} A ${r} ${r} 0 0 1 ${x + r} ${y} Z`
  }).join(" ")

  // how far the notch has gone up after the console, while hyprland slides it out.
  property real lift: 0

  onLitChanged: {
    if (root.lit) {
      retract.stop()
      root.lift = 0
    } else {
      retract.restart()
    }
  }

  // the window goes a whole screen height, so the notch does too.
  NumberAnimation {
    id: retract

    target: root
    property: "lift"
    from: 0
    to: -root.height
    duration: Theme.consoleRetract
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.consoleRetractCurve
  }

  readonly property real bleed: Theme.seamBleed
  readonly property real rim: Theme.consoleRim

  // a console as wide as the work area meets the side border with no room for a
  // rim, so that side is square against the border and takes a fillet underneath,
  // like a flush tab.
  readonly property bool flushLeft: root.box.x - root.rim <= Theme.borderWidth
  readonly property bool flushRight: root.box.x + root.box.width + root.rim >= root.width - Theme.borderWidth

  // the band's inner edge, less a bleed so the two shapes overlap.
  readonly property real outerTop: Theme.borderWidth - root.bleed
  readonly property real outerLeft: root.flushLeft ? Theme.borderWidth - root.bleed : root.box.x - root.rim
  readonly property real outerRight: root.flushRight ? root.width - Theme.borderWidth + root.bleed : root.box.x + root.box.width + root.rim
  readonly property real outerBottom: root.box.y + root.box.height + root.rim

  // concentric with the window's corner, so the rim is the same width all the way
  // round it.
  readonly property real outerRadius: Theme.windowRadius + root.rim

  anchors.fill: parent

  opacity: root.lit ? 1 : 0
  visible: root.opacity > 0 && root.box.width > 0

  transform: Translate { y: root.lift }

  // hyprland fades the console as it slides it out, and a notch that only moved
  // was left as a rim over the desktop once the window had faded. so it fades for
  // as long as it rises. the duration is read as the animation starts, by which
  // point lit already holds the value that started it.
  Behavior on opacity {
    NumberAnimation { duration: root.lit ? Theme.notchFadeDuration : Theme.consoleRetract }
  }

  Shape {
    // set explicitly: QQuickShape fights an implicit size binding.
    width: root.width
    height: root.height

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: Theme.notch
      strokeWidth: -1
      fillRule: ShapePath.OddEvenFill

      PathRectangle {
        x: root.outerLeft
        y: root.outerTop
        width: root.outerRight - root.outerLeft
        height: root.outerBottom - root.outerTop
        bottomLeftRadius: root.flushLeft ? 0 : root.outerRadius
        bottomRightRadius: root.flushRight ? 0 : root.outerRadius
      }

      PathSvg {
        path: root.holes
      }
    }
  }

  // where the notch meets the top band, as a tab does.
  InvertedCorner {
    visible: !root.flushLeft
    corner: "bottomLeft"
    x: root.outerLeft - Theme.notchRadius
    y: root.outerTop
  }

  InvertedCorner {
    visible: !root.flushRight
    corner: "bottomRight"
    x: root.outerRight - root.bleed
    y: root.outerTop
  }

  // and where a flush side meets the side border again below it.
  InvertedCorner {
    visible: root.flushLeft
    corner: "bottomRight"
    x: Theme.borderWidth - root.bleed
    y: root.outerBottom - root.bleed
  }

  InvertedCorner {
    visible: root.flushRight
    corner: "bottomLeft"
    x: root.width - Theme.borderWidth - Theme.notchRadius
    y: root.outerBottom - root.bleed
  }
}
