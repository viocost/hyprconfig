#!/usr/bin/env python3
"""Feed a passphrase to an interactive program (e.g. steghide) through a PTY.

steghide reads its passphrase with getpass() from the controlling terminal and
ignores stdin, so it cannot be driven by an ordinary pipe. This helper allocates
a pseudo-terminal, runs the wrapped command on it, and "types" the passphrase
each time a prompt containing the word "passphrase" appears.

Usage:
    SM_PP='<passphrase>' ptyfeed.py <num_prompts> <command> [args...]

Notes:
  * The passphrase is read from the SM_PP environment variable, never from argv,
    so it does not appear in /proc/<pid>/cmdline.
  * <num_prompts> is how many times to send it (steghide asks twice when
    embedding, once when extracting).
  * The wrapped command's exit status is propagated.
"""
import os
import pty
import sys


def main() -> int:
    if len(sys.argv) < 3:
        sys.stderr.write(
            "ptyfeed: usage: SM_PP=... ptyfeed.py <num_prompts> <cmd> [args...]\n"
        )
        return 2

    try:
        state = {"remaining": int(sys.argv[1]), "buf": b""}
    except ValueError:
        sys.stderr.write("ptyfeed: <num_prompts> must be an integer\n")
        return 2

    cmd = sys.argv[2:]

    passphrase = os.environ.get("SM_PP")
    if passphrase is None:
        sys.stderr.write("ptyfeed: SM_PP environment variable is not set\n")
        return 2
    pw_bytes = passphrase.encode() + b"\n"

    def on_master_read(fd: int) -> bytes:
        data = os.read(fd, 1024)
        state["buf"] += data.lower()
        while state["remaining"] > 0 and b"passphrase" in state["buf"]:
            idx = state["buf"].find(b"passphrase")
            state["buf"] = state["buf"][idx + len(b"passphrase"):]
            os.write(fd, pw_bytes)
            state["remaining"] -= 1
        # keep the scan buffer bounded
        if len(state["buf"]) > 4096:
            state["buf"] = state["buf"][-256:]
        return data

    status = pty.spawn(cmd, on_master_read)
    return os.waitstatus_to_exitcode(status)


if __name__ == "__main__":
    sys.exit(main())
