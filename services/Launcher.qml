pragma Singleton
import QtQuick
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

  // true from the open until the window has finished fading out, which outlasts
  // `opened` by one exit animation. what the rows are built from has to stay put
  // for exactly that long, or the panel empties itself on the way out.
  property bool mapped: false
  property string category: "all"

  // what the last open asked for, which is not always what it got: a category
  // that is not on offer opens on ALL. whether wallpapers are on offer is only
  // re-asked as the launcher opens, so the answer that brings them back lands
  // just after the open that wanted them -- and moves the launcher there.
  property string requested: "all"

  Connections {
    target: LauncherRows

    function onCategoriesChanged(): void {
      if (root.opened && root.category === "all" && root.requested !== "all" && LauncherRows.offers(root.requested)) root.category = root.requested
    }
  }

  function open(category: string): void {
    // an empty argument means the whole list, which is also what a plain open
    // gives: the design resets the chips to ALL every time the launcher is raised.
    //
    // a category that is not on offer -- wallpapers with no awww -- opens on ALL
    // instead, so the keybind still visibly does something.
    root.requested = category.length > 0 ? category : "all"
    root.category = LauncherRows.offers(root.requested) ? root.requested : "all"
    root.opened = true
  }

  function close(): void {
    root.opened = false
  }

  // one bind pressed twice opens and closes. a different category's bind while the
  // launcher is already up switches to it rather than closing: the second press is
  // a request to see something, not to put the launcher away.
  function toggle(category: string): void {
    const wanted = category.length > 0 && LauncherRows.offers(category) ? category : "all"

    if (root.opened && root.category === wanted) {
      root.close()
      return
    }

    root.open(category)
  }
}
