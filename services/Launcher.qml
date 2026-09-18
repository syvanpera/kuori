pragma Singleton
import Quickshell

// whether the launcher is open, and nothing else. alone in a singleton so the ipc
// handler, the window that draws it and (later) a button on the frame all address
// one object rather than reaching into each other's windows.
//
// the query deliberately does not live here: the window is destroyed on close, so
// the field starts empty on every open without anything having to remember it.
Singleton {
  id: root

  property bool opened: false

  function open(): void {
    root.opened = true
  }

  function close(): void {
    root.opened = false
  }

  function toggle(): void {
    root.opened = !root.opened
  }
}
