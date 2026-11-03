pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.services
import qs.theme

// the status notifier items applications put in a tray, and whose menu is out.
//
// named Tray because Quickshell.Services.SystemTray already exports a singleton
// called SystemTray, the collision Bluez is named around. this is the only file
// that imports it.
//
// reading SystemTray is what registers org.kde.StatusNotifierWatcher on the
// session bus, so with Theme.tray off it is never read and the name is left for
// another bar to take.
Singleton {
  id: root

  // what the tab shows, in the order the applications registered. a passive item
  // is the spec saying it has nothing to report right now.
  readonly property var items: Theme.tray
    ? SystemTray.items.values.filter(item => Theme.trayPassive || item.status !== Status.Passive)
    : []

  // the item whose menu the tab is showing. kept while the tab is shut, so the
  // menu does not empty itself on screen as it fades.
  property SystemTrayItem menuItem: null

  // whether that menu is the one out on this screen.
  function showing(item: SystemTrayItem, screen: string): bool {
    return Notches.openOn(Notches.resolve(screen)) === "tray" && root.menuItem === item
  }

  // a left click: what the application means by it, unless the item is only a
  // menu, which the spec says has nothing to activate.
  function activate(item: SystemTrayItem, screen: string): void {
    if (item.onlyMenu) root.toggleMenu(item, screen)
    else {
      Notches.close()
      item.activate()
    }
  }

  // the same item's menu a second time puts it away, another item's switches to it.
  function toggleMenu(item: SystemTrayItem, screen: string): void {
    if (!item.hasMenu) return

    if (root.showing(item, screen)) {
      Notches.close()
      return
    }

    root.menuItem = item
    Notches.show("tray", screen)
  }

  // an application quitting with its menu out takes the menu with it.
  onItemsChanged: {
    if (root.menuItem && !root.items.includes(root.menuItem)) {
      if (Notches.open === "tray") Notches.close()
      root.menuItem = null
    }
  }
}
