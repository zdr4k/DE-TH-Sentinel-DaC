import sys
from collections import defaultdict
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = ROOT / "Rules"


def main():
    files_by_id = defaultdict(list)
    paths = sorted(RULES_DIR.glob("*.yml"))

    for path in paths:
        with open(path, encoding="utf-8") as f:
            rule = yaml.safe_load(f)
        rule_id = str(rule.get("id", "")).lower()
        if rule_id:
            files_by_id[rule_id].append(path.name)

    duplicates = {i: files for i, files in files_by_id.items() if len(files) > 1}
    if duplicates:
        for rule_id, files in duplicates.items():
            print(f"DUPLICATE {rule_id}: {', '.join(files)}")
        sys.exit(1)

    print(f"OK     {len(paths)} rules, all ids are unique")


if __name__ == "__main__":
    main()