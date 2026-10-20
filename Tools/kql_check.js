// Usage:
//   node kql_check.js check  <schemas-dir>   < queries.json
//   node kql_check.js tables                 < queries.json
//   node kql_check.js columns <schemas-dir>  < queries.json
// stdin: [{ "id": "...", "query": "..." }]
require("@kusto/language-service-next/bridge.js");
require("@kusto/language-service-next/Kusto.Language.Bridge.js");
const fs = require("fs");
const path = require("path");

const K = Kusto.Language;
const S = K.Symbols;

const TYPES = {
  string: S.ScalarTypes.String,
  datetime: S.ScalarTypes.DateTime,
  long: S.ScalarTypes.Long,
  int: S.ScalarTypes.Int,
  real: S.ScalarTypes.Real,
  bool: S.ScalarTypes.Bool,
  dynamic: S.ScalarTypes.Dynamic,
  guid: S.ScalarTypes.Guid,
  timespan: S.ScalarTypes.TimeSpan,
};

function loadState(dir) {
  const tables = dir
    ? fs.readdirSync(dir).filter((f) => f.endsWith(".json")).map((f) => {
        const t = JSON.parse(fs.readFileSync(path.join(dir, f), "utf8"));
        const cols = t.columns.map((c) => {
          if (!(c.type in TYPES)) throw new Error(`${t.name}.${c.name}: unknown type '${c.type}'`);
          return new S.ColumnSymbol(c.name, TYPES[c.type]);
        });
        return new S.TableSymbol.$ctor4(t.name, cols);
      })
    : [];
  return K.GlobalState.Default.WithDatabase(new S.DatabaseSymbol.$ctor1("db", tables));
}

function diagnostics(query, state) {
  const code = K.KustoCode.ParseAndAnalyze(query, state);
  return Bridge.toArray(code.GetDiagnostics()).map((d) => ({
    severity: String(d.Severity),
    message: d.Message,
    start: d.Start,
  }));
}

const UNKNOWN_TABLE = /^The name '(.+)' does not refer to any known table, tabular variable or function\.$/;

const [mode, dir] = process.argv.slice(2);
const items = JSON.parse(fs.readFileSync(0, "utf8"));

if (mode === "check") {
  const state = loadState(dir);
  const out = items.map(({ id, query }) => ({
    id,
    diagnostics: diagnostics(query, state).filter((d) => d.severity === "Error"),
  }));
  console.log(JSON.stringify(out, null, 2));
} else if (mode === "columns") {
  const state = loadState(dir);
  const out = items.map(({ id, query }) => {
    const code = K.KustoCode.ParseAndAnalyze(query, state);
    const errors = diagnostics(query, state).filter((d) => d.severity === "Error");
    return {
      id,
      columns: errors.length ? null : Bridge.toArray(code.ResultType.Columns).map((c) => c.Name),
    };
  });
  console.log(JSON.stringify(out, null, 2));
} else if (mode === "tables") {
  const state = loadState(null);
  const out = items.map(({ id, query }) => ({
    id,
    tables: [...new Set(diagnostics(query, state)
      .map((d) => (d.message.match(UNKNOWN_TABLE) || [])[1])
      .filter(Boolean))],
  }));
  console.log(JSON.stringify(out, null, 2));
} else {
  console.error("mode must be 'check', 'columns' or 'tables'");
  process.exit(2);
}