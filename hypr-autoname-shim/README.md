# hypr-autoname-shim

A tiny compatibility shim that keeps
[`hyprland-autoname-workspaces`](https://github.com/hyprland-community/hyprland-autoname-workspaces)
working under **Hyprland 0.56+ with the new Lua config**.

---

## The problem

Hyprland exposes two UNIX sockets per running instance, in
`$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/`:

| Socket | Purpose |
|--------|---------|
| `.socket2.sock` | **Event stream** (read-only push). Hyprland writes lines like `openwindow>>…`, `workspace>>3`. |
| `.socket.sock`  | **Command socket** (request → reply). What `hyprctl` uses. |

Since Hyprland switched from the legacy `.conf` format to the **Lua config**,
everything sent to the *command* socket is parsed **as Lua**. Legacy clients
that use the `hyprland-rs` crate — including `hyprland-autoname-workspaces` —
send the old plain form, e.g.:

```
j/dispatch renameworkspace 3 3:foo
```

Under the Lua parser this becomes `hl.dispatch(renameworkspace 3 3:foo)` → a
Lua syntax error. The rename is rejected and workspace auto-naming silently
stops working. (The same breakage affects any tool that speaks legacy socket
dispatch; this shim only fixes the autoname tool.)

Upstream `hyprland-autoname-workspaces` (1.2.0) has no fix yet, so we translate
its traffic instead of modifying it.

---

## How it works

`hyprland-autoname-workspaces` runs a loop:

1. Connects to `.socket2.sock` and **listens** for events.
2. On a relevant event it **queries state** via the command socket
   (`j/clients`, `j/activeworkspace`, …).
3. Computes each workspace label from its TOML config (`3:` + icons).
4. **Writes the label back** via the command socket:
   `j/dispatch renameworkspace 3 3:<icon>`.

Only step 4's *dispatch* is rejected by the Lua parser. Everything else is fine.

The shim gives the tool a **fake, short instance signature** (`autoname`) so it
looks in `…/hypr/autoname/` instead of the real instance dir. In that dir:

```
                        REAL Hyprland instance dir
              .socket2.sock (events)      .socket.sock (commands)
                     ▲                            ▲
                     │ symlink (unchanged)        │ translated
   autoname tool ────┤                            │
  HIS = "autoname"   │                    ┌───────┴────────┐
     ├─ reads events ┘                    │  proxy.py       │
     └─ sends commands ───────────────────►  (our listener) │
                                          └────────────────┘

   …/hypr/autoname/.socket2.sock  ->  symlink to the REAL event socket
   …/hypr/autoname/.socket.sock   ->  proxy.py's own listening socket
```

- **Events are not proxied.** `.socket2.sock` is a symlink straight to the real
  event socket, so the tool receives genuine Hyprland events.
- **Commands go through the proxy.** For each request `proxy.py`:
  1. reads the raw bytes (e.g. `j/dispatch renameworkspace 3 3:foo`);
  2. strips the `j/` / `[[BATCH]]` prefixes and, **only if** it is a
     `renameworkspace` dispatch, rewrites it to Lua:
     ```
     dispatch hl.dsp.workspace.rename({ workspace = 3, name = "3:foo" })
     ```
     any other request (queries, other dispatches) is forwarded **verbatim**;
  3. connects to the **real** command socket, sends the translated request,
     reads Hyprland's reply (`ok`);
  4. relays that reply back to the tool, which is none the wiser.

In practice `renameworkspace` is the only command that ever needs translating.

---

## Directory contents

| File | Role |
|------|------|
| `proxy.py`  | The translation proxy (stdlib-only Python, threaded). |
| `launch.sh` | Sets up the fake instance dir + proxy, waits until the proxy is accepting connections, then `exec`s the tool pointed at it. |
| `README.md` | This document. |

---

## Deployment

The shim is self-contained: `launch.sh` locates `proxy.py` next to itself, so
you can keep the directory anywhere. It currently lives in the dotfiles repo at:

```
~/hyprconfig/hypr-autoname-shim/
```

No symlinking or `$PATH` entry is required. Make sure both scripts are
executable:

```sh
chmod +x ~/hyprconfig/hypr-autoname-shim/launch.sh \
         ~/hyprconfig/hypr-autoname-shim/proxy.py
```

Requirements: `python3` (standard library only) and
`hyprland-autoname-workspaces` on `$PATH`.

---

## Startup

It is launched once per session from the Hyprland Lua config
(`~/.config/hypr/hyprland.lua`), inside the `hyprland.start` autostart handler:

```lua
hl.on("hyprland.start", function()
    ...
    hl.exec_cmd("~/hyprconfig/hypr-autoname-shim/launch.sh")
    ...
end)
```

`launch.sh` then:

1. resolves the **real** instance dir from `HYPRLAND_INSTANCE_SIGNATURE`;
2. creates `…/hypr/autoname/` and symlinks `.socket2.sock` to the real one;
3. starts `proxy.py` and **waits until it accepts connections** (the tool
   panics on a connection-refused, so ordering matters);
4. `exec`s `hyprland-autoname-workspaces` with
   `HYPRLAND_INSTANCE_SIGNATURE=autoname` so its command traffic hits the proxy.

Because the signature changes every login, `launch.sh` recreates the symlink
and rebinds the proxy socket on each run; stale state from a previous session
is harmless.

### Running it manually (e.g. current session)

```sh
~/hyprconfig/hypr-autoname-shim/launch.sh
```

Or as a transient user service (clean, detached):

```sh
systemd-run --user --unit=hypr-autoname --collect \
  --setenv=HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_INSTANCE_SIGNATURE" \
  ~/hyprconfig/hypr-autoname-shim/launch.sh
```

---

## Configuration

The shim itself is configured through environment variables / arguments read by
`launch.sh`:

| Variable / arg | Default | Meaning |
|----------------|---------|---------|
| `$1` or `AUTONAME_CONFIG` | `~/.config/hypr/hyprland-autoname-workspaces.toml` | Tool config passed through with `--config`. |
| `AUTONAME_FAKE_HIS` | `autoname` | Short fake instance name for the proxy dir. Keep it short: `AF_UNIX` paths are limited to ~108 chars and the real signature is already ~60. |
| `HYPR_AUTONAME_PROXY_LOG` | *(unset)* | If set, `proxy.py` appends each translated command (`IN:` / `OUT:`) to this file. |

The **workspace naming itself** (icons, colors, rules) is configured exactly as
before, in the tool's own TOML file — the shim does not touch it.

---

## Troubleshooting

**Names not updating.** Check both processes are alive:

```sh
pgrep -af 'proxy.py|hyprland-autoname-workspaces'
```

Enable command logging and watch translations:

```sh
HYPR_AUTONAME_PROXY_LOG=/tmp/autoname-proxy.log \
  ~/hyprconfig/hypr-autoname-shim/launch.sh
tail -f /tmp/autoname-proxy.log      # look for IN:/OUT: lines
```

Verify a translated rename reaches Hyprland (should print `ok`):

```sh
hyprctl dispatch 'hl.dsp.workspace.rename({ workspace = 1, name = "1:test" })'
```

**`AF_UNIX path too long` / `path must be shorter than SUN_LEN`.**
`AUTONAME_FAKE_HIS` is too long. Keep it a few characters.

**Tool panics with `Connection refused` on startup.** The tool started before
the proxy was listening. `launch.sh` guards against this with a readiness
probe; if you launch things by hand, start `proxy.py` first.

---

## Removing the shim

When `hyprland-autoname-workspaces` / `hyprland-rs` gain native support for the
Lua command syntax (or Hyprland restores legacy dispatch compatibility), delete
this directory and point the autostart back at the tool directly:

```lua
hl.exec_cmd("hyprland-autoname-workspaces --config ~/.config/hypr/hyprland-autoname-workspaces.toml")
```
