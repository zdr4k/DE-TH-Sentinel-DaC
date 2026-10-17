import json
import shutil
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = ROOT / "Rules"
SCHEMAS_DIR = ROOT / "Schemas" / "tables"
KQL_TOOL = Path(__file__).resolve().parent / "kql_check.js"

UNKNOWN_TABLE = "does not refer to any known table"


def load_queries():
    items = []
    for path in sorted(RULES_DIR.glob("*.yml")):
        with open(path, encoding="utf-8") as f:
            rule = yaml.safe_load(f)
        items.append({"id": path.name, "query": rule.get("query", "")})
    return items


def run_check(items):
    proc = subprocess.run(
        [shutil.which("node"), str(KQL_TOOL), "check", str(SCHEMAS_DIR)],
        input=json.dumps(items),
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if proc.returncode != 0:
        sys.exit(f"kql_check.js failed:\n{proc.stderr}")
    return json.loads(proc.stdout)


def position(query, offset):
    before = query[:offset]
    line = before.count("\n") + 1
    column = offset - (before.rfind("\n") + 1) + 1
    return line, column


def main():
    if not SCHEMAS_DIR.is_dir():
        sys.exit("No schemas found. Run Tools/Sentinel-Schemas.ps1 and choose option 2.")

    items = load_queries()
    queries = {i["id"]: i["query"] for i in items}
    failed = 0

    for result in run_check(items):
        rule_id = result["id"]
        errors = result["diagnostics"]
        if not errors:
            print(f"OK     {rule_id}")
            continue
        failed += 1
        print(f"FAILED {rule_id}")
        for e in errors:
            line, column = position(queries[rule_id], e["start"])
            print(f"  query line {line}, column {column}: {e['message']}")
            if UNKNOWN_TABLE in e["message"]:
                print("  hint: run Tools/Sentinel-Schemas.ps1 and choose option 2 to download the schema")

    print(f"\n{len(items) - failed} of {len(items)} rules passed")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()