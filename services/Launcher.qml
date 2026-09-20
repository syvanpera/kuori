pragma Singleton
import Quickshell

// whether the launcher is open and which category it is showing, and nothing
// else. alone in a singleton so the ipc handler, the window that draws it and
// (later) a button on the frame all address one object rather than reaching into
// each other's windows.
//
// the query deliberately does not live here: the window is destroyed on close, so
// the field starts empty on every open without anything having to remember it.
// the category does live here, because a keybind that opens straight into one has
// to be able to say so before there is a panel to tell.
Singleton {
  id: root

  property bool opened: false
  property string category: "all"

  function open(category: string): void {
    // an empty argument means the whole list, which is also what a plain open
    // gives: the design resets the chips to ALL every time the launcher is raised.
    root.category = category.length > 0 ? category : "all"
    root.opened = true
  }

  function close(): void {
    root.opened = false
  }

  // one bind pressed twice opens and closes. a different category's bind while the
  // launcher is already up switches to it rather than closing: the second press is
  // a request to see something, not to put the launcher away.
  function toggle(category: string): void {
    const wanted = category.length > 0 ? category : "all"

    if (root.opened && root.category === wanted) {
      root.close()
      return
    }

    root.open(wanted)
  }
}
