"""Running a host's steps: output streamed to the terminal and written to the
host's log, and several hosts at once when a run has more than one."""

from __future__ import annotations

import json
import os
import shlex
import subprocess
import sys
import threading
import time
from dataclasses import dataclass
from typing import Callable, BinaryIO, TextIO

from report import clean_line

# Stands for the store path `nix flake archive` printed, in the steps after it.
SRC = "{src}"
_COLOURS = ("36", "35", "33", "32", "34", "96", "95", "93")


@dataclass(frozen=True)
class Step:
    argv: tuple[str, ...]
    ok_codes: frozenset[int] = frozenset({0})
    # stdout is `nix flake archive --json`; its path fills SRC in later steps.
    captures_src: bool = False
    env: tuple[tuple[str, str], ...] = ()

    def resolved(self, src: str | None) -> tuple[str, ...]:
        return tuple(a.replace(SRC, src) for a in self.argv) if src else self.argv


@dataclass(frozen=True)
class Outcome:
    ok: bool
    exit_code: int | None
    seconds: float
    commands: tuple[str, ...]


def colour(text: str, code: str, stream: TextIO) -> str:
    if os.environ.get("NO_COLOR") or not stream.isatty():
        return text
    return f"\x1b[{code}m{text}\x1b[0m"


class Console:
    """Terminal output shared by every job, one line at a time."""

    def __init__(self, stream: TextIO | None = None):
        self.stream = stream or sys.stdout
        self.lock = threading.Lock()
        self._labels: dict[str, str] = {}

    def line(self, text: str = "") -> None:
        with self.lock:
            print(text, file=self.stream, flush=True)

    def raw(self, data: bytes) -> None:
        with self.lock:
            self.stream.buffer.write(data)
            self.stream.flush()

    def label(self, name: str) -> str:
        """`[Name]` padded to one width, in a colour of its own."""
        if name not in self._labels:
            code = _COLOURS[len(self._labels) % len(_COLOURS)]
            self._labels[name] = colour(f"{f'[{name}]':<13}", code, self.stream)
        return self._labels[name]


class Sink:
    """A job's output: clean lines into its log, and onto the terminal either
    as it comes (one job, progress bars and prompts intact) or line by line
    behind the host's label (several jobs)."""

    def __init__(self, log: TextIO, console: Console, label: str | None):
        self.log, self.console, self.label = log, console, label
        self._pending = b""

    def feed(self, data: bytes) -> None:
        if self.label is None:
            self.console.raw(data)
        *lines, self._pending = (self._pending + data).split(b"\n")
        for line in lines:
            self._emit(line)

    def close(self) -> None:
        if self._pending:
            self._emit(self._pending)
            self._pending = b""

    def note(self, text: str) -> None:
        """A line of fleet's own, for the log and the terminal."""
        self.log.write(text + "\n")
        self.log.flush()
        self.console.line(f"{self.label}{text}" if self.label is not None else text)

    def _emit(self, raw: bytes) -> None:
        text = clean_line(raw.decode("utf-8", "replace"))
        self.log.write(text + "\n")
        self.log.flush()
        if self.label is not None:
            self.console.line(f"{self.label}{text}")


class Jobs:
    """Every child process running, so Ctrl-C can stop them all."""

    def __init__(self) -> None:
        self.stopping = threading.Event()
        self._lock = threading.Lock()
        self._procs: set[subprocess.Popen] = set()

    def start(self, argv: tuple[str, ...], **kwargs) -> subprocess.Popen:
        with self._lock:
            if self.stopping.is_set():
                raise InterruptedError("stopping")
            proc = subprocess.Popen(argv, **kwargs)
            self._procs.add(proc)
            return proc

    def done(self, proc: subprocess.Popen) -> None:
        with self._lock:
            self._procs.discard(proc)

    def stop_all(self) -> None:
        with self._lock:
            self.stopping.set()
            for proc in self._procs:
                if proc.poll() is None:
                    proc.terminate()


def _pump(stream: BinaryIO, sink: Sink) -> None:
    fd = stream.fileno()
    while chunk := os.read(fd, 65536):
        sink.feed(chunk)


def _run_one(argv, step: Step, sink: Sink, cwd, solo: bool, jobs: Jobs) -> tuple[int, bytes]:
    env = {**os.environ, **dict(step.env)} if step.env else None
    # One job keeps the terminal's stdin so sudo and ssh can prompt; several
    # read nothing, so a remote sudo that wants a password fails instead of waiting.
    stdin = None if solo else subprocess.DEVNULL
    out = subprocess.PIPE
    err = subprocess.PIPE if step.captures_src else subprocess.STDOUT
    proc = jobs.start(argv, cwd=cwd, env=env, stdin=stdin, stdout=out, stderr=err)
    try:
        if not step.captures_src:
            _pump(proc.stdout, sink)
            return proc.wait(), b""
        reader = threading.Thread(target=_pump, args=(proc.stderr, sink), daemon=True)
        reader.start()
        captured = proc.stdout.read()
        code = proc.wait()
        reader.join()
        return code, captured
    finally:
        for stream in (proc.stdout, proc.stderr):
            if stream:
                stream.close()
        jobs.done(proc)


def run_steps(steps: list[Step], sink: Sink, *, jobs: Jobs, cwd: str | None = None, solo: bool = False) -> Outcome:
    """Run the steps in order, stopping at the first that fails."""
    started, commands, src, code = time.monotonic(), [], None, 0
    for step in steps:
        argv = step.resolved(src)
        commands.append(shlex.join(argv))
        sink.note(f"$ {shlex.join(argv)}")
        try:
            code, captured = _run_one(argv, step, sink, cwd, solo, jobs)
        except InterruptedError:
            return Outcome(False, 130, time.monotonic() - started, tuple(commands))
        except OSError as error:
            sink.note(f"fleet: could not run {argv[0]}: {error}")
            return Outcome(False, 127, time.monotonic() - started, tuple(commands))
        if code not in step.ok_codes:
            return Outcome(False, code, time.monotonic() - started, tuple(commands))
        if step.captures_src:
            try:
                src = json.loads(captured)["path"]
            except (ValueError, KeyError, TypeError):
                sink.note(f"fleet: expected JSON with a store path from {argv[0]}, got {captured[:200]!r}")
                return Outcome(False, 1, time.monotonic() - started, tuple(commands))
    return Outcome(True, code, time.monotonic() - started, tuple(commands))


def run_parallel(tasks: list[Callable[[], None]], jobs: Jobs) -> None:
    """Run each task in a thread and wait for all of them. Ctrl-C stops every
    child process, waits for the tasks to notice, and is raised again."""
    threads = [threading.Thread(target=task, daemon=True) for task in tasks]
    for thread in threads:
        thread.start()
    try:
        while any(t.is_alive() for t in threads):
            for thread in threads:
                thread.join(0.2)
    except KeyboardInterrupt:
        jobs.stop_all()
        for thread in threads:
            thread.join(10)
        raise


def wait_for(target: str, up: bool, timeout: float, jobs: Jobs, probe: Callable[[str], bool], interval: float = 5) -> float | None:
    """Seconds until the host answers (up) or stops answering (not up) over
    ssh, or None when that hasn't happened within the timeout."""
    started = time.monotonic()
    while not jobs.stopping.is_set():
        if probe(target) == up:
            return time.monotonic() - started
        if time.monotonic() - started >= timeout:
            return None
        jobs.stopping.wait(interval)
    return None
