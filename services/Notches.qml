pragma Singleton
import Quickshell

// which tab is showing its panel, if any. one place rather than a flag per tab,
// because only one can be open at a time: clicking one has to shut whichever was
// already out, and a tab that opens on hover has to keep quiet while another is
// being read.
Singleton {
  id: root

  // the open tab's id, or "" for none.
  property string open: ""

  // and which of the system panel's rows is folded out, "" for none. it lives here
  // rather than in the panel for the reason the launcher's category does: the
  // system tab's strip has to be able to open a row, and to know which one is out
  // so it can underline its icon, and the panel does not exist to be asked until
  // after the tab is open.
  property string row: ""

  // a row cannot be out while the panel it is in is away.
  onOpenChanged: if (root.open !== "system") root.row = ""

  function toggle(id: string): void {
    root.open = root.open === id ? "" : id
  }

  function close(): void {
    root.open = ""
  }

  // the panel's own row header: fold this row out, or fold it away again, leaving
  // the panel where it is.
  function foldRow(id: string): void {
    root.row = root.row === id ? "" : id
  }

  // the same row's icon on the strip: open the tab onto it, or -- when it is
  // already what the panel is showing -- put the whole tab away, the way a second
  // press of a launcher bind does.
  function toggleRow(id: string): void {
    if (root.open === "system" && root.row === id) {
      root.close()
      return
    }

    root.open = "system"
    root.row = id
  }
}
