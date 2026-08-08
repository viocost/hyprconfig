#!/usr/bin/env python3
"""
Hyprland IPC command-socket translation proxy.

Part of the hypr-autoname-shim (see README.md in this directory).

Hyprland 0.56+ with the new Lua config parses everything sent to its *command*
socket as Lua. Legacy clients such as hyprland-autoname-workspaces (via the
hyprland-rs crate) send the old plain form, e.g.

    j/dispatch renameworkspace 3 3:foo

which the Lua parser rejects ("')' expected near ..."), so workspace renaming
silently stops working.

This proxy is a man-in-the-middle on the *command* socket only. It:

  * listens on a fake command socket,
  * rewrites `renameworkspace` dispatches into the Lua form
        dispatch hl.dsp.workspace.rename({ workspace = <id>, name = "<name>" })
  * forwards every other request (state queries, other dispatches) unchanged,
  * relays Hyprland's reply back to the client verbatim.

The event socket (.socket2.sock) is NOT proxied; the launcher symlinks it
straight through, so the client still receives genuine Hyprland events.

Usage:
    proxy.py <listen_socket> <real_command_socket> [--log FILE]

If --log is omitted the HYPR_AUTONAME_PROXY_LOG environment variable is used;
if neither is set, only translated commands are... not logged at all.
"""

from __future__ import annotations

import argparse
import os
import re
import socket
import sys
import threading

# Wire-format prefixes Hyprland accepts before the actual command:
#   flags terminated by '/'  -> e.g. "j/" (json), "r/" (refresh), "jr/"
#   "[[BATCH]]"              -> ';'-separated batch of commands
_FLAGS_RE = re.compile(r"^([a-zA-Z]*)/(.*)$", re.S)
_DISPATCH_RE = re.compile(r"^dispatch\s+(.*)$", re.S)

# renameworkspace <id>,<name>   or   renameworkspace <id> <name>
_RENAME_COMMA = re.compile(r"^renameworkspace\s+(-?\d+)\s*,\s*(.*)$", re.S)
_RENAME_SPACE = re.compile(r"^renameworkspace\s+(-?\d+)\s+(.*)$", re.S)

_RECV = 65536
_TIMEOUT = 2.0

_log_path = ""


def _log(msg: str) -> None:
    if not _log_path:
        return
    try:
        with open(_log_path, "a") as fh:
            fh.write(msg + "\n")
    except OSError:
        pass


def _lua_escape(name: str) -> str:
    """Escape a workspace name for embedding in a Lua double-quoted string."""
    return name.replace("\\", "\\\\").replace('"', '\\"')


def translate_command(cmd: str) -> str:
    """Translate a single, unprefixed command (e.g. 'dispatch renameworkspace ...')."""
    m = _DISPATCH_RE.match(cmd)
    if not m:
        return cmd  # not a dispatch (state query etc.) -> unchanged
    rest = m.group(1).strip()
    rm = _RENAME_COMMA.match(rest) or _RENAME_SPACE.match(rest)
    if not rm:
        return cmd  # some other dispatch we don't need to touch -> unchanged
    ws_id, name = rm.group(1), rm.group(2)
    lua = 'hl.dsp.workspace.rename({{ workspace = {id}, name = "{name}" }})'.format(
        id=ws_id, name=_lua_escape(name)
    )
    return "dispatch " + lua


def translate(payload: str) -> str:
    """Translate a full request, preserving [[BATCH]] and flag ('j/', ...) prefixes."""
    batch = ""
    body = payload
    if body.startswith("[[BATCH]]"):
        batch = "[[BATCH]]"
        body = body[len(batch):]

    flags = ""
    fm = _FLAGS_RE.match(body)
    if fm:
        flags = fm.group(1) + "/"
        body = fm.group(2)

    parts = body.split(";") if batch else [body]
    return batch + flags + ";".join(translate_command(p) for p in parts)


def _recv_request(conn: socket.socket) -> bytes:
    """Read one request. hyprland-rs writes the whole command in a single shot."""
    chunks = []
    try:
        while True:
            data = conn.recv(_RECV)
            if not data:
                break
            chunks.append(data)
            if len(data) < _RECV:
                break
    except socket.timeout:
        pass
    return b"".join(chunks)


def _forward(real_path: str, payload: str) -> bytes:
    """Send the translated command to the real socket and return the reply."""
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as up:
        up.settimeout(_TIMEOUT)
        up.connect(real_path)
        up.sendall(payload.encode("utf-8"))
        try:
            up.shutdown(socket.SHUT_WR)
        except OSError:
            pass
        resp = b""
        try:
            while True:
                d = up.recv(_RECV)
                if not d:
                    break
                resp += d
        except socket.timeout:
            pass
        return resp


def handle_client(conn: socket.socket, real_path: str) -> None:
    try:
        conn.settimeout(_TIMEOUT)
        raw = _recv_request(conn)
        if not raw:
            return
        payload = raw.decode("utf-8", "replace")
        translated = translate(payload)
        if translated != payload:
            _log("IN : " + payload)
            _log("OUT: " + translated)
        resp = _forward(real_path, translated)
        try:
            conn.sendall(resp)
        except OSError:
            pass
    except Exception as exc:  # noqa: BLE001 - never let one client kill the proxy
        _log("ERR: " + repr(exc))
    finally:
        try:
            conn.close()
        except OSError:
            pass


def serve(listen_path: str, real_path: str) -> int:
    try:
        os.unlink(listen_path)
    except FileNotFoundError:
        pass

    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(listen_path)
    srv.listen(64)
    _log("proxy listening on %s -> %s" % (listen_path, real_path))

    while True:
        try:
            conn, _ = srv.accept()
        except OSError:
            break
        threading.Thread(
            target=handle_client, args=(conn, real_path), daemon=True
        ).start()
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Hyprland command-socket translation proxy")
    parser.add_argument("listen_socket", help="path of the fake command socket to create")
    parser.add_argument("real_socket", help="path of the real Hyprland command socket")
    parser.add_argument(
        "--log",
        default=os.environ.get("HYPR_AUTONAME_PROXY_LOG", ""),
        help="optional log file for translated commands",
    )
    args = parser.parse_args(argv)

    global _log_path
    _log_path = args.log

    return serve(args.listen_socket, args.real_socket)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
