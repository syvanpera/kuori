import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// one of the python helpers in scripts/: a child process that says one JSON
// object per line on stdout and takes one word per line on stdin. they do what
// quickshell cannot -- export a d-bus object, hold an inhibitor -- and they live
// and die with the shell, so a helper that exits is started again, though not in
// a tight loop.
//
// the one file in services/ that is not a singleton. the lock, the pairing
// agent and the screensaver own one each, and a component in qs.components would have the services
// importing the module that imports them.
Scope {
  id: root

  // the file under scripts/.
  required property string script

  // what its lines are called in the log.
  property string name: root.script

  signal event(var message)
  signal exited(int code)

  // a word for the helper. dropped while it is down: whatever it would have
  // answered is asked again when it says it is ready.
  function tell(line: string): void {
    if (proc.running) proc.write(`${line}\n`)
  }

  Process {
    id: proc

    // -B: the helpers import kuori_bus from beside themselves, and a __pycache__
    // written into the config directory is a file quickshell may reload over.
    command: ["python3", "-B", Quickshell.shellPath(`scripts/${root.script}`)]
    running: true
    stdinEnabled: true

    stdout: SplitParser {
      onRead: line => {
        let message

        try {
          message = JSON.parse(line)
        } catch (err) {
          console.warn(`${root.name}: unreadable line: ${line}`)
          return
        }

        root.event(message)
      }
    }

    stderr: SplitParser {
      onRead: line => console.warn(`${root.name}: ${line}`)
    }

    onExited: (code, status) => {
      console.warn(`${root.name}: exited ${code}; restarting`)
      root.exited(code)
      respawn.restart()
    }
  }

  Timer {
    id: respawn

    interval: Theme.helperRespawn

    onTriggered: proc.running = true
  }
}
