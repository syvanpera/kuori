pragma Singleton
import Quickshell

// resolving a desktop entry's icon name to a file, once per name per session.
//
// `Quickshell.iconPath` caches what it finds and nothing of what it does not: a
// hit costs ~8ms the first time and nothing after, but every miss walks the icon
// themes again, ~15ms a go -- measured here at 1537ms for a hundred of them, on
// the gui thread, which is the frame the launcher was supposed to draw in. Names
// that no theme answers for are exactly what a launcher is full of: a script
// somebody wrote, a window class with no entry behind it.
//
// so misses are remembered too. the launcher asks per row and per delegate reuse,
// which means a list that scrolls asks the same question dozens of times.
Singleton {
  id: root

  property var cache: ({})

  function path(icon: string): string {
    if (!icon || icon.length === 0) return ""

    // some entries ship an absolute path instead of a theme name, and the icon
    // loader has no idea what to do with one.
    if (icon.startsWith("/")) return `file://${icon}`

    const known = root.cache[icon]
    if (known !== undefined) return known

    // check: true answers "" rather than a broken image when the theme has
    // nothing, which is the only way the row knows to draw its letter instead.
    const resolved = Quickshell.iconPath(icon, true)

    root.cache[icon] = resolved

    return resolved
  }
}
