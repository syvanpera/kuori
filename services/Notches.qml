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

  function toggle(id: string): void {
    root.open = root.open === id ? "" : id
  }

  function close(): void {
    root.open = ""
  }
}
