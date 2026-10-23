"""Checks the ADS documents of a pull request.
1. Every rule added in the pull request needs Docs/ADS/<rule>.md.
2. Every ADS document added or changed must have all the sections of
   Templates/ads_template.md and balanced, correctly closed section markers.

Usage: python Tools/check_ads_present.py <base ref>
"""
import re
import subprocess
import sys
from pathlib import Path

MARKER = re.compile(r"<!--\s*(/?)ads:(fixed|draft|analyst)\s*-->")
HEADING = re.compile(r"^## (.+?)\s*$", re.MULTILINE)


def changed(base, diff_filter, folder):
    out = subprocess.run(
        ["git", "diff", "--name-only", f"--diff-filter={diff_filter}", f"{base}...HEAD", "--", folder],
        capture_output=True, text=True, check=True,
    ).stdout.split("\n")
    return [Path(p) for p in out if p.strip()]


def marker_problems(text):
    problems = []
    open_kind = None
    for match in MARKER.finditer(text):
        closing, kind = match.group(1) == "/", match.group(2)
        line = text.count("\n", 0, match.start()) + 1
        if not closing:
            if open_kind:
                problems.append(f"line {line}: ads:{kind} opened before ads:{open_kind} was closed")
            open_kind = kind
        elif open_kind != kind:
            problems.append(f"line {line}: /ads:{kind} closes {'nothing' if not open_kind else 'ads:' + open_kind}")
            open_kind = None
        else:
            open_kind = None
    if open_kind:
        problems.append(f"ads:{open_kind} is never closed")
    return problems


def structure_problems(path, expected):
    text = path.read_text(encoding="utf-8")
    problems = [f"missing section '{h}'" for h in expected if h not in HEADING.findall(text)]
    return problems + marker_problems(text)


def main():
    base = sys.argv[1]
    template = Path("Templates/ads_template.md")
    expected = HEADING.findall(template.read_text(encoding="utf-8")) if template.exists() else []

    failed = False
    for rule in [p for p in changed(base, "A", "Rules") if p.suffix == ".yml"]:
        ads = Path("Docs/ADS") / f"{rule.stem}.md"
        if ads.exists():
            print(f"OK       {rule.name} has {ads}")
        else:
            failed = True
            print(f"MISSING  {rule.name}: no {ads}")
            print("         Open an ADS request issue, assign it to Copilot, pick ads_writer and choose this branch as base.")

    for ads in [p for p in changed(base, "AM", "Docs/ADS") if p.suffix == ".md" and p.name != "README.md" and p.exists()]:
        problems = structure_problems(ads, expected)
        if problems:
            failed = True
            print(f"FAILED   {ads}")
            for problem in problems:
                print(f"         {problem}")
        else:
            print(f"OK       {ads} structure")

    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()