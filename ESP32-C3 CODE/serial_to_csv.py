#!/usr/bin/env python3
"""
Log Arduino serial output to a CSV file.

Expected serial lines from sketch_jul5a.ino:
IR=12345, BPM=72.50, Avg BPM=70, MIC=2048, GSR=1900
IR=12345, BPM=72.50, Avg BPM=70, MIC=2048, GSR=1900 No finger?
"""

from __future__ import annotations

import argparse
import csv
from datetime import datetime
from pathlib import Path
import re
import sys
import time

try:
    import serial
    from serial.tools import list_ports
except ImportError:  # pragma: no cover - only hit when pyserial is missing
    print("Missing dependency: pyserial", file=sys.stderr)
    print("Install it with: python -m pip install pyserial", file=sys.stderr)
    raise SystemExit(1)


SERIAL_PATTERN = re.compile(
    r"IR=(?P<ir>-?\d+),\s*"
    r"BPM=(?P<bpm>-?\d+(?:\.\d+)?),\s*"
    r"Avg BPM=(?P<avg_bpm>-?\d+),\s*"
    r"MIC=(?P<mic>-?\d+),\s*"
    r"GSR=(?P<gsr>-?\d+)"
    r"(?:\s*(?P<note>.*))?"
)

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_LOG_DIR = SCRIPT_DIR / "csv_logs"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Read Arduino serial data and save parsed samples to CSV."
    )
    parser.add_argument(
        "-p",
        "--port",
        help="Serial port, for example COM3. If omitted, available ports are shown.",
    )
    parser.add_argument(
        "-b",
        "--baud",
        type=int,
        default=None,
        help="Serial baud rate. Default: 115200",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="CSV output path. Default: csv_logs/serial_log_YYYYmmdd_HHMMSS.csv",
    )
    parser.add_argument(
        "--raw",
        action="store_true",
        help="Also save lines that do not match the expected sketch format.",
    )
    return parser.parse_args()


def print_ports() -> list:
    ports = list(list_ports.comports())
    if not ports:
        print("No serial ports found.")
        return ports

    print("Available serial ports:")
    for index, port in enumerate(ports, start=1):
        print(f"  {index}. {port.device}: {port.description}")
    return ports


def prompt_for_port() -> str:
    ports = print_ports()
    print()

    while True:
        prompt = "Enter serial port"
        if ports:
            prompt += " number or name"
        prompt += " (example: COM3): "

        answer = input(prompt).strip()
        if not answer:
            print("Please enter a serial port.")
            continue

        if answer.isdigit() and ports:
            index = int(answer)
            if 1 <= index <= len(ports):
                return ports[index - 1].device
            print(f"Please enter a number from 1 to {len(ports)}, or type a port name.")
            continue

        return answer


def prompt_for_baud(default_baud: int) -> int:
    answer = input(f"Baud rate [{default_baud}]: ").strip()
    if not answer:
        return default_baud

    try:
        return int(answer)
    except ValueError:
        print(f"Using default baud rate {default_baud}.")
        return default_baud


def prompt_for_output() -> Path | None:
    answer = input("CSV output file [csv_logs/auto timestamped file]: ").strip()
    if not answer:
        return None
    return Path(answer)


def parse_serial_line(line: str) -> dict[str, str | int | float] | None:
    match = SERIAL_PATTERN.search(line)
    if not match:
        return None

    note = (match.group("note") or "").strip()
    return {
        "ir": int(match.group("ir")),
        "bpm": float(match.group("bpm")),
        "avg_bpm": int(match.group("avg_bpm")),
        "mic": int(match.group("mic")),
        "gsr": int(match.group("gsr")),
        "note": note,
    }


def make_default_output_path() -> Path:
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return DEFAULT_LOG_DIR / f"serial_log_{stamp}.csv"


def resolve_output_path(output_path: Path | None) -> Path:
    if output_path is None:
        return make_default_output_path()
    if output_path.parent == Path("."):
        return DEFAULT_LOG_DIR / output_path
    return output_path


def main() -> int:
    args = parse_args()
    interactive = args.port is None

    if not args.port:
        args.port = prompt_for_port()

    if args.baud is None:
        if interactive:
            args.baud = prompt_for_baud(115200)
        else:
            args.baud = 115200

    if args.output is None and interactive:
        args.output = prompt_for_output()

    output_path = resolve_output_path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    fields = [
        "timestamp",
        "elapsed_seconds",
        "ir",
        "bpm",
        "avg_bpm",
        "mic",
        "gsr",
        "note",
        "raw",
    ]

    print(f"Opening {args.port} at {args.baud} baud...")
    print(f"Writing CSV to {output_path.resolve()}")
    print("Press Ctrl+C to stop.")

    start = time.monotonic()
    rows_written = 0

    try:
        with serial.Serial(args.port, args.baud, timeout=1) as ser:
            # Give the board a moment after the serial connection opens.
            time.sleep(2)
            ser.reset_input_buffer()

            with output_path.open("w", newline="", encoding="utf-8") as csv_file:
                writer = csv.DictWriter(csv_file, fieldnames=fields)
                writer.writeheader()

                while True:
                    raw_bytes = ser.readline()
                    if not raw_bytes:
                        continue

                    raw_line = raw_bytes.decode("utf-8", errors="replace").strip()
                    if not raw_line:
                        continue

                    parsed = parse_serial_line(raw_line)
                    if parsed is None and not args.raw:
                        continue

                    now = datetime.now().isoformat(timespec="milliseconds")
                    row = {
                        "timestamp": now,
                        "elapsed_seconds": f"{time.monotonic() - start:.3f}",
                        "ir": "",
                        "bpm": "",
                        "avg_bpm": "",
                        "mic": "",
                        "gsr": "",
                        "note": "",
                        "raw": raw_line,
                    }
                    if parsed:
                        row.update(parsed)

                    writer.writerow(row)
                    csv_file.flush()
                    rows_written += 1
                    print(f"\rRows written: {rows_written}", end="", flush=True)
    except KeyboardInterrupt:
        print(f"\nStopped. Wrote {rows_written} rows to {output_path.resolve()}")
        return 0
    except serial.SerialException as exc:
        print(f"\nSerial error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())









