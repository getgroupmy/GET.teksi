# Project skills

Two third-party skills are vendored here so they travel with the repository
rather than depending on each developer's global setup.

## `ui-ux-pro-max/` — UI/UX design intelligence

- Source: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill (MIT, © Next Level Builder)
- Vendored from `.claude/skills/ui-ux-pro-max/` at v2.13.0.
- Local changes: the `${CLAUDE_PLUGIN_ROOT}` prefix in `SKILL.md` was replaced
  with a repo-relative path, and `scripts/tests/` was dropped. The data and
  search logic are unmodified.

Searchable UX guidelines, styles, palettes, typography and per-stack rules —
including a `flutter` stack. Query it directly:

```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "touch target size" --domain ux
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "theming tokens" --stack flutter
```

`references/pro-rules.md` holds the native-app polish rules and the
pre-delivery checklist that the accessibility pass in `docs/UI-UX-AUDIT.md`
was run against.

## `graphify/` — codebase knowledge graph

- Source: https://github.com/Graphify-Labs/graphify (Apache-2.0, © Graphify Labs)
- Installed via `pip install graphifyy` and copied here from the CLI's own
  `graphify install` output, unmodified.

Maps the repository into a queryable graph instead of grepping. The CLI is a
dev dependency, not an app dependency:

```bash
pip install graphifyy       # or: uv tool install graphifyy
graphify update .           # deterministic AST pass, no LLM, no API cost
```

Writes `graphify-out/`. Only `GRAPH_REPORT.md` is committed — `graph.json` and
`graph.html` are ~2 MB of regenerable output and are ignored.
