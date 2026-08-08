#!/usr/bin/env python3
"""
Hyprland IPC command-socket translation proxy (general).

Hyprland 0.56+ with the Lua config parses everything sent to its *command*
socket as Lua. Legacy clients (anything using hyprland-rs, waybar's
hyprland/workspaces module, plain `hyprctl dispatch ...`, ...) send the old
plain form, e.g.:

    dispatch workspace 3
    j/dispatch renameworkspace 3 3:foo

which the Lua parser rejects. This proxy sits in front of the command socket,
rewrites a small set of legacy dispatches into their Lua equivalents, and
forwards everything else unchanged. The event socket (.socket2.sock) is not
proxied — the launcher symlinks it straight through.

Usage:
    proxy.py <listen_socket> <real_command_socket> [--log FILE]
"""

from __future__ import annotations

import argparse
import os
import re
import socket
import sys
import threading

# Wire-format prefixes: "j/", "r/", "jr/" (flags) and "[[BATCH]]".
_FLAGS_RE = re.compile(r"^([a-zA-Z]*)/(.*)$", re.S)
_DISPATCH_RE = re.compile(r"^dispatch\s+(.*)$", re.S)

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


def _lua_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def _sel(value: str) -> str:
    """Render a workspace selector as a Lua value: bare int, else quoted string."""
    value = value.strip()
    if re.fullmatch(r"-?\d+", value):
        return value
    return '"' + _lua_escape(value) + '"'


# --- Per-dispatch translators -------------------------------------------------
# Each takes the argument string (everything after the dispatcher name) and
# returns the Lua dispatcher call, or None to leave the command untouched.

def _tr_workspace(arg: str):
    return "hl.dsp.focus({{ workspace = {} }})".format(_sel(arg))


def _tr_movetoworkspace(arg: str):
    return "hl.dsp.window.move({{ workspace = {}, follow = true }})".format(_sel(arg))


def _tr_movetoworkspacesilent(arg: str):
    return "hl.dsp.window.move({{ workspace = {}, follow = false }})".format(_sel(arg))


def _tr_renameworkspace(arg: str):
    m = re.match(r"^(-?\d+)\s*,\s*(.*)$", arg, re.S) or re.match(r"^(-?\d+)\s+(.*)$", arg, re.S)
    if not m:
        return None
    return 'hl.dsp.workspace.rename({{ workspace = {id}, name = "{name}" }})'.format(
        id=m.group(1), name=_lua_escape(m.group(2))
    )


# dispatcher name -> translator
_TRANSLATORS = {
    "workspace": _tr_workspace,
    "movetoworkspace": _tr_movetoworkspace,
    "movetoworkspacesilent": _tr_movetoworkspacesilent,
    "renameworkspace": _tr_renameworkspace,
}


def translate_command(cmd: str) -> str:
    """Translate a single, unprefixed command (e.g. 'dispatch workspace 3')."""
    m = _DISPATCH_RE.match(cmd)
    if not m:
        return cmd  # not a dispatch (state query etc.) -> unchanged
    rest = m.group(1).strip()
    name, _, arg = rest.partition(" ")
    fn = _TRANSLATORS.get(name)
    if not fn:
        return cmd  # dispatch we don't need to touch -> unchanged
    lua = fn(arg.strip())
    if lua is None:
        return cmd
    return "dispatch " + lua


def translate(payload: str) -> str:
    """Translate a full request, preserving [[BATCH]] and flag prefixes."""
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
    except Exception as exc:  # noqa: BLE001
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
        threading.Thread(target=handle_client, args=(conn, real_path), daemon=True).start()
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Hyprland command-socket translation proxy")
    parser.add_argument("listen_socket")
    parser.add_argument("real_socket")
    parser.add_argument("--log", default=os.environ.get("HYPR_LUA_SHIM_LOG", ""))
    args = parser.parse_args(argv)
    global _log_path
    _log_path = args.log
    return serve(args.listen_socket, args.real_socket)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
