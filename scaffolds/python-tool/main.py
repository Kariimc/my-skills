#!/usr/bin/env python3
"""REPLACE: one-line tool purpose.

Run (Windows, fast interpreter):
  C:/Users/karii/AppData/Local/Python/pythoncore-3.14-64/python.exe main.py --help
Venv (if deps needed):
  python -m venv .venv && .venv\\Scripts\\activate && pip install -r requirements.txt
"""
import argparse
import sys


def run(args: argparse.Namespace) -> int:
    # REPLACE: the actual work. Return 0 on success, nonzero on failure —
    # callers (and gates) rely on the exit code, not on printed prose.
    print(f"ok: {args.target}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("target", help="REPLACE: what the tool operates on")
    p.add_argument("--dry-run", action="store_true", help="show, don't do")
    return run(p.parse_args())


if __name__ == "__main__":
    sys.exit(main())
