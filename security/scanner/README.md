# security/scanner

Host integrity scanner built on **AIDE** + **`pacman -Qkk`**, with a thin bash
wrapper that merges their output into one report and raises a **swaync** desktop
notification (with Copy/Open buttons) when something deviates from the baseline.

It complements the EDR already on this machine (CrowdStrike Falcon, DriveStrike)
with a transparent, self-hosted, Arch-native check you fully control.

## Design

| Layer              | Role                                                             |
|--------------------|-----------------------------------------------------------------|
| **AIDE**           | File-integrity of systemd units, cron, PATH binaries, login/loader vectors, accounts (`config/aide.conf`). |
| **`pacman -Qkk`**  | Verifies packaged files against the **vendor's** checksums — catches tampering that predates the AIDE baseline. |
| **`security-scan`**| Runs both, merges a report, prunes old ones, fires the notification. |
| **systemd timer**  | Drives the scan on boot and every 3h of uptime.                 |

Why both engines: AIDE diffs against *your* baseline (whatever the disk looked
like at `init`), while `pacman -Qkk` knows what the distro *originally shipped*.
Together they catch both "changed since baseline" and "already-trojaned binary".

## Layout

```
security/scanner/
├── security-scan.sh              # wrapper → /usr/local/bin/security-scan
├── config/
│   ├── aide.conf                 # AIDE policy (what is watched)
│   └── scanner.conf              # wrapper config (notify/user/retention)
├── systemd/
│   ├── security-scan.service     # oneshot root scan
│   └── security-scan.timer       # boot + every 3h
└── README.md
```

Installed locations:

| Source                         | Installed to                              |
|--------------------------------|-------------------------------------------|
| `security-scan.sh`             | `/usr/local/bin/security-scan` (root:root)|
| `config/aide.conf`             | `/etc/security-scanner/aide.conf`         |
| `config/scanner.conf`          | `/etc/security-scanner/scanner.conf` (600)|
| AIDE database (baseline)       | `/var/lib/security-scanner/aide.db.gz`    |
| Reports                        | `/var/log/security-scanner/reports/`      |

## Install

```bash
cd ~/hyprconfig
./install/security.sh          # installs AIDE, deploys, baselines, enables timer
```

The installer builds the initial baseline. **Only baseline a host you believe is
currently clean** — otherwise you bless the malware as trusted.

## Usage

```bash
sudo security-scan scan     # run both checks, write report, notify on findings
sudo security-scan init     # (re)build the trusted baseline
sudo security-scan update   # alias for init — accept current state as good
```

`scan` exit codes: `0` clean, `1` deviations found, `2` tool error.

### After intentional changes

A package update, a new service, or an edited cron entry **will** show up as a
deviation. That's expected — review it, then run `sudo security-scan init` to
fold the new state into the baseline.

## Notifications

On findings, the root scan launches the notifier inside the GUI user's session
(via `systemd-run`, so it survives the service exiting). The swaync notification
offers:

- **Open report** — runs `NOTIFY_OPEN_CMD` (default `kitty -e nvim {}`).
- **Copy path** — `wl-copy`s the report path (or full contents if
  `NOTIFY_COPY_MODE=content`).

If the user has no live session bus (e.g. a boot-time scan before login), the
notification is skipped and the report is still written to disk.

## Configuration (`/etc/security-scanner/scanner.conf`)

Root-owned `600`. The wrapper refuses to source it if it is not root-owned or is
writable by others (a user-writable config sourced by root would be a privilege-
escalation vector). Key options: `RUN_AIDE`, `RUN_PACMAN`, `NOTIFY_ENABLED`,
`NOTIFY_USER`, `NOTIFY_ON_CLEAN`, `NOTIFY_COPY_MODE`, `NOTIFY_OPEN_CMD`,
`REPORT_KEEP`.

Tune **what AIDE watches** in `/etc/security-scanner/aide.conf`.

## Limitations / notes

- AIDE selects by **path**, not by the executable bit, so home coverage targets
  the specific places startup code lives (PATH bin dirs, autostart, shell rc,
  `~/.config/hypr`, user systemd units) rather than hashing the whole home tree.
- The AIDE database and the baseline are only as trustworthy as the moment they
  were taken, and an attacker with root could rewrite them. Falcon + auditd are
  the runtime backstop.
