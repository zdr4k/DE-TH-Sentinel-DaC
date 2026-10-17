import sys, json
import yaml
from jsonschema import Draft201909Validator

rule_path = sys.argv[1]
rule = yaml.safe_load(open(rule_path, encoding='utf-8'))
schema = json.load(open('Schemas/rule_schema.json', encoding='utf-8'))

errors = list(Draft201909Validator(schema).iter_errors(rule))

if errors:
    for e in errors:
        where = ".".join(str(p) for p in e.absolute_path) or "(root)"
        print("INVALID", where, e.message)
    sys.exit(1)
print("OK", rule_path)