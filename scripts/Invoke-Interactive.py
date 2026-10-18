#!/usr/bin/env python3

import argparse
import json
import os
import select
import subprocess
import sys
import time


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cwd", required=True)
    parser.add_argument("--interaction", required=True)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.command and args.command[0] == "--":
        args.command = args.command[1:]
    if not args.command:
        parser.error("command is required after --")
    return args


def drive_output(output, steps, next_step, send):
    while next_step < len(steps) and steps[next_step]["match"] in output:
        send(steps[next_step]["response"] + "\n")
        next_step += 1
    return next_step


def run_posix(args, steps, timeout):
    master, slave = os.openpty()
    process = subprocess.Popen(
        args.command,
        cwd=args.cwd,
        env=os.environ.copy(),
        stdin=slave,
        stdout=slave,
        stderr=slave,
        close_fds=True,
    )
    os.close(slave)
    output = ""
    next_step = 0
    deadline = time.monotonic() + timeout
    try:
        while process.poll() is None or select.select([master], [], [], 0)[0]:
            if time.monotonic() >= deadline:
                process.kill()
                raise TimeoutError("interactive command timed out")
            readable, _, _ = select.select([master], [], [], 0.1)
            if not readable:
                continue
            try:
                chunk = os.read(master, 4096)
            except OSError:
                break
            if not chunk:
                break
            output += chunk.decode(errors="replace")
            next_step = drive_output(
                output,
                steps,
                next_step,
                lambda value: os.write(master, value.encode()),
            )
    finally:
        os.close(master)
    return process.wait(), output, next_step


def run_windows(args, steps, timeout):
    try:
        from winpty import PtyProcess
    except ImportError as error:
        raise RuntimeError("pywinpty is required for interactive scenarios on Windows") from error

    process = PtyProcess.spawn(args.command, cwd=args.cwd, env=os.environ.copy())
    output = ""
    next_step = 0
    deadline = time.monotonic() + timeout
    while process.isalive():
        if time.monotonic() >= deadline:
            process.terminate(force=True)
            raise TimeoutError("interactive command timed out")
        try:
            chunk = process.read(4096)
        except EOFError:
            break
        output += chunk
        next_step = drive_output(output, steps, next_step, process.write)
    return process.exitstatus, output, next_step


def main():
    args = parse_args()
    with open(args.interaction, encoding="utf-8") as interaction_file:
        interaction = json.load(interaction_file)
    steps = interaction["steps"]
    timeout = interaction.get("timeoutSeconds", 600)

    if os.name == "nt":
        exit_code, output, next_step = run_windows(args, steps, timeout)
    else:
        exit_code, output, next_step = run_posix(args, steps, timeout)

    sys.stdout.write(output)
    if next_step != len(steps):
        missing = steps[next_step]["match"]
        raise RuntimeError(f"interactive prompt was not observed: {missing}")
    return exit_code


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:
        print(f"Interactive runner failed: {error}", file=sys.stderr)
        sys.exit(1)
