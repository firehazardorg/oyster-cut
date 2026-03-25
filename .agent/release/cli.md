# Logseq CLI & MCP Server - 05/03/2026

The Logseq CLI (`@logseq/cli`) provides offline and in-app access to DB graphs from the terminal. It also ships an MCP server that exposes graph read/write to AI tools.

---

## Installation

```bash
# Global install from npm
npm install -g @logseq/cli

# Or run locally from repo
cd deps/cli && yarn install && node cli.mjs -h
```

### Dev mode (limited — no JS-dependent commands like mcp-server)

```bash
cd deps/db && yarn install
yarn nbb-logseq -cp src:../cli/src:../graph-parser/src:../outliner/src -m logseq.cli <command>
```

> `bb dev:cli` is defined in `bb.edn` but doesn't appear in `bb tasks` due to a task registration issue. The underlying command works directly.

---

## Two Modes of Operation

| Mode | How | When to use |
|---|---|---|
| **Local** | `-g <graph-name>` | Offline, works directly against SQLite files in `~/logseq/graphs/` |
| **In-app** | `-a <token>` or `$LOGSEQ_API_SERVER_TOKEN` | Connects to running desktop app's HTTP API server |

Current API token: `<LOGSEQ_API_TOKEN>` (configured in Logseq desktop settings).

---

## CLI Commands

| Command | Local | In-app | Description |
|---|---|---|---|
| `list` | Yes | — | List all local graphs |
| `show <graph>` | Yes | — | Graph metadata — creation date, schema version, commit |
| `search <term>` | Yes | Yes | Search block titles (local) or full content (in-app) |
| `query <datalog>` | Yes | Yes | Datalog queries, entity lookups by id/uuid/ident, simple queries (in-app) |
| `export` | Yes | — | Export graph as Markdown zip |
| `export-edn` | Yes | Yes | Export graph as EDN (properties, classes, pages) |
| `import-edn` | Yes | Yes | Import properties, classes, pages from EDN file |
| `append <text>` | — | Yes | Append block to currently open page |
| `mcp-server` | Yes | Yes | Start MCP server for AI tool integration |
| `validate` | Yes | — | Validate graph schema integrity |

---

## Command Examples

```bash
# List local graphs
logseq list
# => logseq-kb

# Show graph info
logseq show logseq-kb
# => Schema v65.22, created Feb 23 2026, imported from file-graph

# Search locally
logseq search "health" -g logseq-kb
# => 6 results

# Datalog query — count all blocks with titles
logseq query '[:find (count ?b) :where [?b :block/title]]' -g logseq-kb
# => [7761]

# Entity lookup by id or ident
logseq query 10 :logseq.class/Tag -g logseq-kb

# Export as markdown
logseq export -g logseq-kb
# => Exported 211 pages to logseq-kb_markdown_*.zip

# Export as EDN
logseq export-edn -g logseq-kb -f backup.edn

# Import EDN into in-app graph
logseq import-edn -f data.edn -a <LOGSEQ_API_TOKEN>

# Append text to current page (in-app only)
logseq append "Hello from CLI" -a <LOGSEQ_API_TOKEN>

# Validate graph integrity
logseq validate -g logseq-kb

# In-app search (searches all content, not just titles)
logseq search "health" -a <LOGSEQ_API_TOKEN>

# In-app simple query
logseq query '(task DOING)' -a <LOGSEQ_API_TOKEN>
```

---

## MCP Server

### What it is

A [Model Context Protocol](https://modelcontextprotocol.io) server that exposes the Logseq graph to AI tools (Claude, Cursor, etc.) over HTTP Streamable or stdio transport.

### Starting the server

```bash
# Against local graph (offline, no app needed)
cd deps/cli && node cli.mjs mcp-server -g logseq-kb -p 12316

# Against in-app graph (requires desktop app running with API server on)
cd deps/cli && node cli.mjs mcp-server -a <LOGSEQ_API_TOKEN>

# Stdio mode (for embedding in AI tools that use stdio transport)
cd deps/cli && node cli.mjs mcp-server -g logseq-kb --stdio
```

> MCP server must be run from `deps/cli/` (not via `bb dev:cli`) because it requires JS deps (`@modelcontextprotocol/sdk`, `fastify`, `zod`) that aren't in `deps/db/`.

### MCP Tools Exposed

| Tool | Description |
|---|---|
| **`getPage`** | Get a page's full content including all blocks. Accepts page name or UUID. |
| **`listPages`** | List all pages. Optional `expand` flag for extra detail. |
| **`listTags`** | List all tags/classes. Optional `expand` for parents and tag properties. |
| **`listProperties`** | List all properties. Optional `expand` for type and cardinality. |
| **`upsertNodes`** | Batch create/edit pages, blocks, tags, and properties. |
| **`searchBlocks`** | Search graph for blocks containing a term (in-app mode only). |

### upsertNodes — the write tool

This is the most powerful tool. It accepts an array of operations, each with:

- **`operation`**: `add` or `edit`
- **`entityType`**: `block`, `page`, `tag`, or `property`
- **`id`**: UUID string (required for `edit`), temp string for `add` if referenced later
- **`data`**: fields to set — `title`, `page-id`, `tags`, `property-type`, `property-cardinality`, `property-classes`, `class-extends`, `class-properties`

**Example — add a block to a page:**
```json
{
  "operations": [
    {
      "operation": "add",
      "entityType": "block",
      "id": null,
      "data": {
        "page-id": "119268a6-704f-4e9e-8c34-36dfc6133729",
        "title": "New block text"
      }
    }
  ]
}
```

**Example — create a page and add a task to it:**
```json
{
  "operations": [
    {
      "operation": "add",
      "entityType": "page",
      "id": "temp-Inbox",
      "data": { "title": "Inbox" }
    },
    {
      "operation": "add",
      "entityType": "block",
      "data": {
        "page-id": "temp-Inbox",
        "title": "Buy groceries",
        "tags": ["00000002-1282-1814-5700-000000000000"]
      }
    }
  ]
}
```

Supports `dry-run: true` to validate without committing.

### Local vs In-app MCP tools

| Tool | Local | In-app |
|---|---|---|
| `getPage` | Yes | Yes |
| `listPages` | Yes | Yes |
| `listTags` | Yes | Yes |
| `listProperties` | Yes | Yes |
| `upsertNodes` | Yes | Yes |
| `searchBlocks` | — | Yes |

### Connecting AI tools to the MCP server

The server runs at `http://127.0.0.1:<port>/mcp` (default port 12316 or as specified with `-p`).

For Claude Desktop or similar tools, add to the MCP config:
```json
{
  "mcpServers": {
    "logseq": {
      "command": "node",
      "args": ["<path-to-repo>/deps/cli/cli.mjs", "mcp-server", "-g", "logseq-kb", "--stdio"]
    }
  }
}
```

### Debug a tool directly

```bash
# Test a tool without starting the full server
cd deps/cli && node cli.mjs mcp-server -g logseq-kb -t listPages --expand true
cd deps/cli && node cli.mjs mcp-server -g logseq-kb -t getPage --pageName "oyster"
```

---

## Known Issues

### Validation errors in `logseq-kb` graph

`validate -g logseq-kb` reports 3 entities with errors:

1. **Block `699c4b52`** on page "oyster" — `block/tags` references `:user.property/issues-uxmxrJpE` which is a Property, not a Class. Also has a disallowed `whiteboard-block` order key. Cannot be fixed via CLI or HTTP API (block/tags is not editable through the plugin SDK). Needs UI or direct SQLite fix.

2. **Entities 7609 & 7582** — `hnsw-label-updated-at` embedding property has value `0`, causing "invalid dispatch value" errors.

### `export-edn` fails on `logseq-kb`

Fails with: `The following classes, uuids and properties are not defined: {:classes #{:user.property/issues-uxmxrJpE}}`. Same root cause as validation error #1.

### `bb dev:cli` task not visible

The `dev:cli` task is defined in `bb.edn` but doesn't appear in `bb tasks` output. None of the `dev:` prefixed tasks are listed. The underlying nbb-logseq command works directly.

---

## Key Files

| File | Purpose |
|---|---|
| `deps/cli/cli.mjs` | CLI entry point (Node.js) |
| `deps/cli/src/logseq/cli.cljs` | Main CLI namespace, command dispatch |
| `deps/cli/src/logseq/cli/commands/` | Individual command implementations |
| `deps/cli/src/logseq/cli/common/mcp/server.cljs` | MCP server setup, tool registration, HTTP transport |
| `deps/cli/src/logseq/cli/common/mcp/tools.cljs` | MCP tool implementations (getPage, listPages, upsertNodes, etc.) |
| `deps/cli/src/logseq/cli/spec.cljs` | CLI option specs for all commands |
| `deps/cli/package.json` | npm package config (`@logseq/cli` v0.4.3) |
| `deps/cli/README.md` | Upstream documentation |
