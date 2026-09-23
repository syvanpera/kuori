"""What kuori's d-bus helpers have in common.

Each helper is a child process of the shell: it says one JSON object per line on
stdout, takes one word per line on stdin, and exits when stdin closes, because
that is the shell going away. The scripts are run by path, so this directory is
sys.path[0] and a plain import finds this file.
"""

import json
import os
import sys

from jeepney import HeaderFields, MessageType, new_method_call


def emit(**event):
    """One line to the shell."""
    sys.stdout.write(json.dumps(event) + "\n")
    sys.stdout.flush()


def logger(name):
    """A function that writes to stderr, which the shell puts in its own log."""

    def log(text):
        print(f"{name}: {text}", file=sys.stderr, flush=True)

    return log


def call(conn, address, method, signature=None, body=()):
    """A method call whose error reply raises rather than coming back as a body."""
    reply = conn.send_and_get_reply(new_method_call(address, method, signature, body), timeout=5)
    if reply.header.message_type == MessageType.error:
        raise RuntimeError(f"{method}: {reply.header.fields.get(HeaderFields.error_name)} {reply.body}")
    return reply.body


class Lines:
    """The shell's side of the pipe, a line at a time."""

    def __init__(self):
        self.fd = sys.stdin.fileno()
        self.pending = b""

    def read(self):
        """The whole lines that have arrived, or None once the shell has gone."""
        chunk = os.read(self.fd, 4096)
        if not chunk:
            return None

        self.pending += chunk
        *lines, self.pending = self.pending.split(b"\n")
        return [line.decode(errors="replace").strip() for line in lines]


def drain(conn):
    """Every message jeepney has buffered.

    One read can carry several messages, and select only knows about the socket,
    not jeepney's buffer -- so a readable socket is drained until it has nothing
    left, or the rest wait for the next message to wake select up.
    """
    while True:
        try:
            yield conn.receive(timeout=0)
        except TimeoutError:
            return
