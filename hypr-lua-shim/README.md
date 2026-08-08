# hypr-lua-shim

General Hyprland IPC command-socket translation shim for **Hyprland 0.56+ with
the Lua config**.

Under the Lua config, everything sent to Hyprland's command socket is parsed as
Lua, which breaks legacy clients that send the old plain form (`dispatch
workspace 3`, `dispatch renameworkspace 3 3:foo`, plain `hyprctl dispatch ...`,
etc.). This shim runs such a client behind a small proxy that rewrites a known
set of legacy dispatches into their Lua equivalents and forwards everything else
unchanged. The event socket (`.socket2.sock`) is symlinked straight through, so
the client still receives genuine Hyprland events.

See `~/projects/hypr-autoname-workspaces-shim/README.md` for the full
explanation of the mechanism (two sockets, fake instance signature, diagram) —
this is the same technique generalised to more dispatchers.

## Files

| File | Role |
|------|------|
| `proxy.py`    | The translation proxy. Translated dispatches: `workspace`, `movetoworkspace`, `movetoworkspacesilent`, `renameworkspace`. Extend `_TRANSLATORS` to add more. |
| `shim-up.sh`  | `shim-up.sh <slug>` — ensure a proxy is running for `<slug>`; then launch app(s) with `HYPRLAND_INSTANCE_SIGNATURE=<slug>`. |
| `run.sh`      | `run.sh <slug> <cmd...>` — shim-up + `exec` a single command behind the shim. |

## Usage

For a launcher that starts several processes (e.g. waybar's two bars):

```sh
~/hyprconfig/hypr-lua-shim/shim-up.sh waybar
export HYPRLAND_INSTANCE_SIGNATURE=waybar
waybar -c config-top & waybar -c config-bottom &
```

For a single-process tool:

```sh
~/hyprconfig/hypr-lua-shim/run.sh myslug some-legacy-hypr-tool --flags
```

Keep `<slug>` short (a few chars): `AF_UNIX` socket paths are limited to ~108
characters and the real instance signature is already ~60.

## Where it's used here

- **waybar** — `~/.config/waybar/launch.sh` calls `shim-up.sh waybar` and runs
  both bars with `HYPRLAND_INSTANCE_SIGNATURE=waybar` so clicking a workspace
  (`dispatch workspace N`) works.
- **hyprland-autoname-workspaces** — started from `hyprland.lua` via
  `run.sh autoname hyprland-autoname-workspaces --config …`, so its
  `renameworkspace` dispatches are translated.

Each app gets its own slug (and therefore its own proxy instance and fake
instance dir), so they stay isolated while sharing this one codebase.

## Debugging

```sh
HYPR_LUA_SHIM_LOG=/tmp/hypr-lua-shim.log ~/hyprconfig/hypr-lua-shim/shim-up.sh waybar
tail -f /tmp/hypr-lua-shim.log     # IN:/OUT: translated commands
```
