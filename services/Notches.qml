pragma Singleton
import QtQuick
import Quickshell
import qs.services

// which tab is showing its panel, if any, and on which screen. one place rather
// than a flag per tab, because only one can be open at a time: clicking one has to
// shut whichever was already out, and a tab that opens on hover has to keep quiet
// while another is being read.
//
// one at a time across every screen, not per screen, because a panel holds a
// focus grab and hyprland keeps only one of those. with a tab open on each of two
// monitors the second grab would clear the first, which this shell reads as a click
// elsewhere -- and with every frame reading one global flag, that is exactly what
// happened: three grabs on open and the panel shut again within 6ms.
Singleton {
  id: root

  // the open tab's id, or "" for none.
  property string open: ""

  // the name of the screen it is open on. a ShellScreen's name is hyprland's
  // monitor name, which is also how Screens finds the focused one.
  property string screen: ""

  // and which of the system panel's rows is folded out, "" for none. it lives here
  // rather than in the panel for the reason the launcher's category does: the
  // system tab's strip has to be able to open a row, and to know which one is out
  // so it can underline its icon, and the panel does not exist to be asked until
  // after the tab is open.
  property string row: ""

  // the strip button whose name is showing under it, and the screen it is on, so
  // only that screen's frame draws it. one for the whole shell, because there is
  // one pointer. tipGone is when the last one went, for Theme.tipWarm.
  property Item tip: null
  property string tipScreen: ""
  property double tipGone: 0

  // asks the frame's key sink to take the keyboard back. a field inside a panel
  // takes it for itself, and when the field goes away qt hands focus to nobody --
  // after which escape stops reaching anything.
  signal refocus()

  // a row cannot be out while the panel it is in is away.
  onOpenChanged: if (root.open !== "system") root.row = ""

  // what is open on this screen: the tab's id, or "" when nothing is, or when what
  // is open is on another screen.
  function openOn(screen: string): string {
    return root.screen === screen ? root.open : ""
  }

  // a keybind or an ipc call names no screen, and means the one with the tabs on
  // it -- or, with tabs on every screen, the one being worked on.
  function resolve(screen: string): string {
    return screen !== "" ? screen : Screens.tabsName
  }

  // the screen is set before the tab, so the frame that is about to open never
  // sees the new tab while the old screen is still named.
  function show(id: string, screen: string): void {
    root.screen = root.resolve(screen)
    root.open = id
  }

  // a second press of the same tab on the same screen puts it away. the same tab
  // on another screen moves it there, rather than closing it where you are not
  // looking.
  function toggle(id: string, screen: string): void {
    const on = root.resolve(screen)

    if (root.open === id && root.screen === on) root.close()
    else root.show(id, on)
  }

  function close(): void {
    root.open = ""
  }

  // the panel's own row header: fold this row out, or fold it away again, leaving
  // the panel where it is.
  function foldRow(id: string): void {
    root.row = root.row === id ? "" : id
  }

  // open the system tab onto a row, whatever is showing now.
  function showRow(id: string, screen: string): void {
    root.show("system", screen)
    root.row = id
  }

  // the same row's icon on the strip: open the tab onto it, or -- when it is
  // already what the panel is showing -- put the whole tab away, the way a second
  // press of a launcher bind does.
  function toggleRow(id: string, screen: string): void {
    if (root.openOn(root.resolve(screen)) === "system" && root.row === id) {
      root.close()
      return
    }

    root.showRow(id, screen)
  }

  // a panel on a monitor that has just been unplugged is a grab on a surface that
  // no longer exists, holding the keyboard somewhere nobody can see.
  Connections {
    target: Quickshell

    function onScreensChanged(): void {
      if (!Array.from(Quickshell.screens).some(s => s.name === root.screen)) root.close()
    }
  }
}
