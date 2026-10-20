"""Check that every column used in entity_mappings is returned by the rule query."""
import json
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = ROOT / "Rules"
SCHEMAS_DIR = ROOT / "Schemas" / "tables"
KQL_TOOL = Path(__file__).resolve().parent / "kql_check.js"


def main():
    rules = {}
    for path in sorted(RULES_DIR.glob("*.yml")):
        rules[path.name] = yaml.safe_load(path.read_text(encoding="utf-8"))

    items = [{"id": name, "query": rule["query"]} for name, rule in rules.items()]
    result = subprocess.run(
        ["node", str(KQL_TOOL), "columns", str(SCHEMAS_DIR)],
        input=json.dumps(items), capture_output=True, text=True, check=True,
    )
    columns = {r["id"]: r["columns"] for r in json.loads(result.stdout)}

    failed = 0
    for name, rule in rules.items():
        output = columns[name]
        if output is None:
            print(f"SKIPPED {name}: the query has errors, see the KQL validation")
            failed += 1
            continue
        missing = [
            (m["entity_type"], f["identifier"], f["column_name"])
            for m in rule["entity_mappings"]
            for f in m["field_mappings"]
            if f["column_name"] not in output
        ]
        if not missing:
            print(f"OK      {name}")
            continue
        failed += 1
        print(f"FAILED  {name}")
        for entity, identifier, column in missing:
            print(f"        {entity}.{identifier} maps to '{column}', which the query does not return")
        print(f"        columns returned: {', '.join(output)}")

    print(f"\n{len(rules) - failed} of {len(rules)} rules passed")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()