pragma Singleton
import Quickshell

// ranking for the launcher's result list. pure functions over plain data: no state
// and no bindings, so one binding in the panel can call rank() and get the same
// answer for the same input every time.
Singleton {
  id: root

  // what kind of match this is, independent of where it was found. the gaps are 20
  // points, which is what caps the length tiebreak below.
  readonly property int tierPrefix: 100
  readonly property int tierWordPrefix: 80
  readonly property int tierSubstring: 60

  // and where it was found. the name is the only field visible before you type, so
  // any match on it outranks any match anywhere else.
  readonly property int weightName: 4
  readonly property int weightGeneric: 2
  readonly property int weightKeyword: 2
  readonly property int weightComment: 1
  readonly property int weightCommand: 1

  // the separators desktop entries actually use: "Qt Creator",
  // "libreoffice-writer", "org.gnome.Files".
  readonly property string boundaries: " -_./"

  // a multi-word query is matched as one literal needle, not as tokens that must
  // each match. token-AND matching is a later change to score() alone.
  function rank(entries: var, query: string): var {
    const needle = query.trim().toLowerCase()

    // no query at all. this is the first thing the launcher shows, so it has to be
    // cheap and it has to be stable.
    if (needle.length === 0) {
      return entries.slice().sort((a, b) => root.byName(a, b))
    }

    const hits = []

    for (const entry of entries) {
      const score = root.score(entry, needle)

      if (score > 0) hits.push({ entry: entry, score: score })
    }

    // score, then name. without the second key two apps that score the same could
    // swap places between keystrokes for no visible reason.
    hits.sort((a, b) => b.score - a.score || root.byName(a.entry, b.entry))

    // the model gets the entries themselves: scored wrappers would be new objects
    // every keystroke and ScriptModel could not match them up.
    return hits.map(hit => hit.entry)
  }

  // best of every field rather than first field that matches, so a name buried in
  // a long comment cannot beat the command that is exactly what was typed.
  function score(entry: var, needle: string): int {
    const hay = root.haystack(entry)

    let best = root.fieldScore(hay.name, needle) * root.weightName
    best = Math.max(best, root.fieldScore(hay.genericName, needle) * root.weightGeneric)

    // keywords are the entry's author saying what to search for, so they are worth
    // more than the prose in the comment.
    for (const keyword of hay.keywords) {
      best = Math.max(best, root.fieldScore(keyword, needle) * root.weightKeyword)
    }

    best = Math.max(best, root.fieldScore(hay.comment, needle) * root.weightComment)

    // the binary, last: it matches on something nobody ever sees, but it is how you
    // find gimp when the entry is called "GNU Image Manipulation Program".
    best = Math.max(best, root.fieldScore(hay.binary, needle) * root.weightCommand)

    if (best === 0) return 0

    return best + root.lengthBonus(hay.name)
  }

  // every field score() reads, lowercased once and kept on the row. the rows are
  // stable objects -- the launcher depends on that -- so the work is done the
  // first time a row is scored rather than for every row on every keystroke,
  // which with a clipboard history is several hundred rows a key.
  function haystack(entry: var): var {
    if (entry.haystack) return entry.haystack

    entry.haystack = {
      name: (entry.name ?? "").toLowerCase(),
      genericName: (entry.genericName ?? "").toLowerCase(),
      keywords: (entry.keywords ?? []).map(keyword => keyword.toLowerCase()),
      comment: (entry.comment ?? "").toLowerCase(),
      binary: root.binaryOf(entry).toLowerCase()
    }

    return entry.haystack
  }

  // one field against one needle: does it start with it, does a word in it start
  // with it, does it contain it at all.
  function fieldScore(haystack: string, needle: string): int {
    if (haystack.length === 0) return 0
    if (haystack.startsWith(needle)) return root.tierPrefix

    const at = haystack.indexOf(needle)

    if (at < 0) return 0
    if (root.boundaries.includes(haystack[at - 1])) return root.tierWordPrefix

    return root.tierSubstring
  }

  // a tiebreak, not a tier: capped at 12, well under the 20 point gap between two
  // tiers, so a short name can never outrank a better match. "Files" should come
  // before "Files (Nautilus) Preferences" when they match equally well.
  function lengthBonus(name: string): int {
    return Math.max(0, 12 - Math.floor(name.length / 2))
  }

  function binaryOf(entry: var): string {
    // command is execString already parsed into argv. only the program matters
    // here, and only its basename.
    const command = entry.command ?? []
    const program = command.length > 0 ? command[0] : (entry.execString ?? "")

    return program.split("/").pop()
  }

  // a row may ask to sort after the rest of its kind, which is how an action that
  // lives in a list of things -- "Random wallpaper" among the wallpapers -- stays
  // at the bottom instead of landing wherever its name falls. it is a tiebreak
  // only: a query that scores it higher still brings it up.
  function byName(a: var, b: var): int {
    if (!!a.last !== !!b.last) return a.last ? 1 : -1

    // a source that has an order of its own says so, and it wins over the name.
    // a clipboard history sorted alphabetically is not a history.
    if (a.order !== undefined && b.order !== undefined) return a.order - b.order

    return (a.name ?? "").localeCompare(b.name ?? "")
  }
}
