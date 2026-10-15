#!/usr/bin/env python3
"""Write Intel GPU engine-busy Prometheus metrics from intel_gpu_top 2.3.

Integration contract:
  intel-gpu-sample.py --output /run/node-exporter/intel-gpu.prom

The output contains only these metric names:
  server_intel_gpu_engine_busy_percent{device="cardX",engine="..."}
  server_intel_gpu_sample_success
  server_intel_gpu_last_success_timestamp_seconds

Each Intel DRM card is sampled separately with:
  intel_gpu_top -J -n 3 -s 1000 -d drm:/dev/dri/cardX
"""

import argparse
import fcntl
import json
import math
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time
from typing import Iterable


INTEL_VENDOR_ID = "0x8086"
CARD_NAME = re.compile(r"card(\d+)")
LAST_SUCCESS = "server_intel_gpu_last_success_timestamp_seconds"


class SampleError(RuntimeError):
    """intel_gpu_top did not provide a safe, usable sample."""


def prometheus_escape(value: str) -> str:
    """Escape a Prometheus label value."""
    return value.replace("\\", "\\\\").replace("\n", "\\n").replace('"', '\\"')


def find_intel_cards(sysfs_root: Path) -> list[str]:
    """Return Intel DRM card names in stable numeric order."""
    cards: list[tuple[int, str]] = []
    try:
        entries = list(sysfs_root.iterdir())
    except OSError:
        return []

    for entry in entries:
        match = CARD_NAME.fullmatch(entry.name)
        if not match:
            continue
        try:
            vendor = (entry / "device" / "vendor").read_text(encoding="ascii").strip().lower()
        except OSError:
            continue
        if vendor == INTEL_VENDOR_ID:
            cards.append((int(match.group(1)), entry.name))
    return [name for _, name in sorted(cards)]


def _reject_json_constant(value: str) -> None:
    raise ValueError(f"non-finite JSON constant {value!r}")


def _finite_json_float(value: str) -> float:
    result = float(value)
    if not math.isfinite(result):
        raise ValueError(f"non-finite JSON number {value!r}")
    return result


def _decode_samples(stdout: str) -> list[dict]:
    """Decode an array, allowing only IGT 2.3's empty-clients separator bug.

    Its global json_struct_members counter is reset by an empty clients object,
    so the next sample's comma is omitted. Decode intact objects, never repair
    their text: nested JSON and strings must retain normal JSON semantics.
    """
    decoder = json.JSONDecoder(
        parse_constant=_reject_json_constant, parse_float=_finite_json_float,
    )
    whitespace = re.compile(r"[ \t\r\n]*")
    position = whitespace.match(stdout, 0).end()
    if stdout[position:position + 1] != "[":
        raise ValueError("expected sample array")
    position += 1
    samples: list[dict] = []
    while True:
        position = whitespace.match(stdout, position).end()
        sample, position = decoder.raw_decode(stdout, position)
        if not isinstance(sample, dict):
            raise ValueError("intel_gpu_top sample is not an object")
        samples.append(sample)
        position = whitespace.match(stdout, position).end()
        separator = stdout[position:position + 1]
        if separator == "]":
            position = whitespace.match(stdout, position + 1).end()
            if position != len(stdout):
                raise ValueError("trailing data after sample array")
            return samples
        if separator == ",":
            position += 1
        elif separator != "{" or sample.get("clients") != {}:
            raise ValueError("expected sample comma or closing array bracket")


def parse_engine_busy(stdout: str) -> list[tuple[str, float]]:
    """Extract the final usable per-engine busy percentages from IGT's JSON.

    intel_gpu_top 2.3 prints a JSON array.  With ``-n 3`` it has exactly three
    objects: discard its first sample and publish the final one.  The upstream
    schema stores engine metrics at ``sample['engines'][engine]['busy']`` and
    gives those values the percent unit.
    """
    try:
        samples = _decode_samples(stdout)
    except (json.JSONDecodeError, ValueError) as error:
        raise SampleError(f"invalid intel_gpu_top JSON: {error}") from error

    if not isinstance(samples, list) or len(samples) != 3:
        raise SampleError("intel_gpu_top must return exactly three JSON samples")

    # The startup sample is intentionally not considered for a scrape.
    final_sample = samples[2]
    if not isinstance(final_sample, dict):
        raise SampleError("final intel_gpu_top sample is not an object")
    engines = final_sample.get("engines")
    if not isinstance(engines, dict) or not engines:
        raise SampleError("final intel_gpu_top sample has no engines object")

    result: list[tuple[str, float]] = []
    for engine, values in engines.items():
        if not isinstance(engine, str) or not engine:
            raise SampleError("engine name is not a non-empty string")
        if not isinstance(values, dict) or values.get("unit") != "%":
            raise SampleError(f"engine {engine!r} does not have a percent unit")
        busy = values.get("busy")
        if isinstance(busy, bool) or not isinstance(busy, (int, float)):
            raise SampleError(f"engine {engine!r} busy is not a JSON number")
        busy_value = float(busy)
        if not math.isfinite(busy_value) or not 0.0 <= busy_value <= 100.0:
            raise SampleError(f"engine {engine!r} busy is outside 0..100")
        result.append((engine, busy_value))

    return sorted(result, key=lambda item: item[0])


def sample_card(executable: str, card: str, timeout_seconds: float) -> list[tuple[str, float]]:
    """Run the bounded Intel GPU sampler for one DRM card."""
    command = [
        executable,
        "-J",
        "-n", "3",
        "-s", "1000",
        "-d", f"drm:/dev/dri/{card}",
    ]
    try:
        completed = subprocess.run(
            command,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            errors="replace",
            timeout=timeout_seconds,
        )
    except subprocess.TimeoutExpired as error:
        raise SampleError(f"intel_gpu_top timed out for {card}") from error
    except OSError as error:
        raise SampleError(f"could not start intel_gpu_top for {card}: {error}") from error

    if completed.returncode != 0:
        raise SampleError(f"intel_gpu_top failed for {card} with exit {completed.returncode}")
    return parse_engine_busy(completed.stdout)


def previous_success_timestamp(output: Path) -> str | None:
    """Preserve a previously published success time across a failed scrape."""
    try:
        text = output.read_text(encoding="utf-8")
    except OSError:
        return None
    match = re.search(
        rf"^{re.escape(LAST_SUCCESS)} ([0-9]+(?:\.[0-9]+)?)$",
        text,
        flags=re.MULTILINE,
    )
    return match.group(1) if match else None


def write_atomic(output: Path, metrics: str) -> None:
    """Replace the textfile atomically, never exposing a partial scrape."""
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary_name: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=output.parent,
            prefix=f".{output.name}.",
            suffix=".tmp",
            delete=False,
        ) as temporary:
            temporary_name = temporary.name
            # NamedTemporaryFile starts at 0600; the separate node-exporter user
            # must be able to read this non-secret metrics file after replacement.
            os.fchmod(temporary.fileno(), 0o644)
            temporary.write(metrics)
            temporary.flush()
            os.fsync(temporary.fileno())
        os.replace(temporary_name, output)
    finally:
        if temporary_name is not None:
            try:
                os.unlink(temporary_name)
            except FileNotFoundError:
                pass


def format_success(samples: Iterable[tuple[str, str, float]], timestamp: float) -> str:
    lines = [
        f'server_intel_gpu_engine_busy_percent{{device="{prometheus_escape(card)}",engine="{prometheus_escape(engine)}"}} {busy:g}'
        for card, engine, busy in samples
    ]
    lines.extend((
        "server_intel_gpu_sample_success 1",
        f"{LAST_SUCCESS} {timestamp:.6f}",
    ))
    return "\n".join(lines) + "\n"


def format_failure(last_timestamp: str | None) -> str:
    lines = ["server_intel_gpu_sample_success 0"]
    if last_timestamp is not None:
        lines.append(f"{LAST_SUCCESS} {last_timestamp}")
    return "\n".join(lines) + "\n"


def run(output: Path, sysfs_root: Path, executable: str, timeout_seconds: float) -> int:
    """Collect all Intel cards, or fail closed without stale utilization."""
    output.parent.mkdir(parents=True, exist_ok=True)
    lock_path = Path(f"{output}.lock")
    with lock_path.open("a", encoding="utf-8") as lock:
        try:
            fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            # Another invocation owns the output and will publish its atomic scrape.
            return 0

        prior_timestamp = previous_success_timestamp(output)
        try:
            cards = find_intel_cards(sysfs_root)
            if not cards:
                raise SampleError("no Intel DRM cards found")
            samples: list[tuple[str, str, float]] = []
            for card in cards:
                samples.extend((card, engine, busy) for engine, busy in sample_card(executable, card, timeout_seconds))
            if not samples:
                raise SampleError("Intel DRM cards reported no engine busy values")
        except SampleError as error:
            write_atomic(output, format_failure(prior_timestamp))
            print(f"intel-gpu-sample: {error}", file=os.sys.stderr)
            return 1

        write_atomic(output, format_success(samples, time.time()))
        return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path, help="Prometheus textfile output path")
    parser.add_argument("--sysfs-root", default="/sys/class/drm", type=Path, help="DRM sysfs root")
    parser.add_argument("--intel-gpu-top", default="intel_gpu_top", help="intel_gpu_top executable")
    parser.add_argument(
        "--timeout-seconds",
        default=10.0,
        type=float,
        help="bounded timeout for each card's finite intel_gpu_top command (default: 10)",
    )
    args = parser.parse_args()
    if not math.isfinite(args.timeout_seconds) or args.timeout_seconds <= 0:
        parser.error("--timeout-seconds must be a finite value greater than zero")
    return args


def main() -> int:
    args = parse_args()
    return run(args.output, args.sysfs_root, args.intel_gpu_top, args.timeout_seconds)


if __name__ == "__main__":
    raise SystemExit(main())
