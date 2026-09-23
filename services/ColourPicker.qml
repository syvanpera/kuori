pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme

// the capture section's third mode. hyprpicker freezes the screen, magnifies what
// is under the pointer and prints the colour; this service asks it once and
// remembers the answer.
//
// it shares the capture button with the other two modes, so the button's
// "Captured!" flash and the notification both still go through Capture.
Singleton {
  id: root

  // hex whatever the chosen format, because the swatch needs a colour QML can
  // parse and one pick has to answer both. Qt's colour carries its own HSL, so
  // the other two formats are arithmetic rather than a second invocation.
  property string format: "hex"
  property string picked: ""
  property real pickedAt: 0

  readonly property var formats: ["hex", "rgb", "hsl"]

  // the picked colour written the way the panel is showing it, which is also what
  // reaches the clipboard.
  readonly property string pickedText: root.formatted(root.picked, root.format)

  // the design's own strings: "#7aa2f7", "rgb(122, 162, 247)", "hsl(219, 88%, 72%)".
  function formatted(hex: string, format: string): string {
    if (hex.length === 0) return ""
    if (format === "hex") return hex

    const c = Qt.color(hex)

    if (format === "rgb") {
      return `rgb(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)})`
    }

    return `hsl(${Math.round(c.hslHue * 360)}, ${Math.round(c.hslSaturation * 100)}%, ${Math.round(c.hslLightness * 100)}%)`
  }

  function pick(): void {
    hyprpicker.running = true
  }

  // hyprpicker only learns where the pointer is from motion events it receives
  // after its own surface is up. click without moving first -- to take the colour
  // already under the cursor, which is a reasonable thing to want -- and it has no
  // position at all and reports #000000. so the pointer is nudged one pixel once
  // the overlay exists, which is imperceptible and is a real motion event.
  Timer {
    id: nudge

    interval: Theme.capNudge

    onTriggered: wake.running = true
  }

  Process {
    id: wake

    // out one pixel and straight back: the move away is the event hyprpicker needs,
    // and the move back is what makes the colour the one that was under the
    // pointer rather than its neighbour.
    //
    // concatenation rather than the backtick literal used everywhere else here:
    // this script is mostly `${...}` parameter expansions, every one of which a
    // template literal would try to evaluate as javascript.
    command: ["sh", "-c",
      "pos=$(hyprctl cursorpos); x=${pos%%,*}; y=${pos##*, };"
      + " hyprctl dispatch \"hl.dsp.cursor.move({ x = $((x + 1)), y = $y })\";"
      + " hyprctl dispatch \"hl.dsp.cursor.move({ x = $x, y = $y })\""]
  }

  Process {
    id: hyprpicker

    onStarted: nudge.restart()

    // -b is not cosmetic: without it hyprpicker wraps the value in ANSI truecolor
    // escapes to print it in its own colour, and what arrives is
    // "\e[38;2;122;162;247m#7aa2f7\e[0m" rather than a hex.
    //
    // and -q is deliberately absent, however tempting "disable most logs" sounds:
    // the colour is printed through the same logger, so quiet means it prints
    // nothing at all and the pick silently does nothing. its logs go to stderr.
    command: ["hyprpicker", "-f", "hex", "-b"]

    stdout: StdioCollector { id: colour }

    onExited: exitCode => {
      // right-click or escape, which is how you change your mind about a colour.
      if (exitCode !== 0) return

      // and the hex is dug out rather than trimmed, so any decoration hyprpicker
      // grows later cannot turn the swatch into an invalid colour again.
      const found = /#[0-9a-fA-F]{6}/.exec(colour.text)

      if (!found) {
        Capture.notify("Colour picker", `hyprpicker said something unexpected: ${colour.text.trim()}`, "")
        return
      }

      const hex = found[0].toLowerCase()

      root.picked = hex
      root.pickedAt = Date.now()
      Capture.flash()

      // copied here rather than with hyprpicker's own -a, because the format on
      // the clipboard has to be the one the panel is showing, and that conversion
      // happens on this side.
      const value = root.formatted(hex, root.format)

      Quickshell.execDetached(["wl-copy", "--", value])
      Capture.notify("Colour picked", value, "")
    }
  }
}
