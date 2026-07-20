---
name: opensearch
description: Guide for querying OpenSearch via MCP server. Use when user wants to search indices, inspect mappings, or run ML/analytics queries against OpenSearch. Activates on "opensearch", "search index", "gelf logs", or any OpenSearch query task.
---

# OpenSearch MCP

Use `mcp__opensearch-mcp-server-py__*` tools. Schemas not loaded by default — run `ToolSearch` before first call each session.

## Startup

Load schemas before use:
```
ToolSearch: select:mcp__opensearch-mcp-server-py__ListIndexTool,mcp__opensearch-mcp-server-py__IndexMappingTool,mcp__opensearch-mcp-server-py__SearchIndexTool,mcp__opensearch-mcp-server-py__CountTool
```

## Available Tools

| Tool | Purpose |
|------|---------|
| `ListIndexTool` | List indices (`include_detail: false` for names only) |
| `IndexMappingTool` | Get index mapping/schema |
| `SearchIndexTool` | Search with DSL (`query_dsl` param) |
| `CountTool` | Count docs matching query (`body` param) |
| `ClusterHealthTool` | Cluster health status |
| `GetShardsTool` | Shard info |
| `LogPatternAnalysisTool` | Analyze log patterns |
| `MsearchTool` | Multi-search queries |
| `DataDistributionTool` | Data distribution stats |
| `ExplainTool` | Explain query scoring |
| `GenericOpenSearchApiTool` | Raw API calls |

## Workflow: Explore Unknown Index

1. `ListIndexTool` → find index name
2. `IndexMappingTool` → understand fields
3. `SearchIndexTool` / `CountTool` → query

## Time Range Queries

**`now-1h` relative syntax does NOT resolve correctly** — use explicit ISO timestamps.

Get latest timestamp first:
```
SearchIndexTool(index, query_dsl={
  "size": 1,
  "sort": [{"@timestamp": {"order": "desc"}}],
  "_source": ["@timestamp"]
})
```
Then use that timestamp to calculate explicit range.

Always include `format` in range queries:
```json
{
  "range": {
    "@timestamp": {
      "gte": "2026-06-01T11:10:00Z",
      "lte": "2026-06-01T12:10:00Z",
      "format": "strict_date_optional_time||epoch_millis"
    }
  }
}
```

## SearchIndexTool vs CountTool

`SearchIndexTool` — uses `query_dsl` param:
```json
{
  "query": {"bool": {"filter": [{"range": {"@timestamp": {"gte": "...", "lte": "...", "format": "strict_date_optional_time||epoch_millis"}}}]}},
  "size": 20,
  "sort": [{"@timestamp": {"order": "desc"}}],
  "_source": ["@timestamp", "level", "message", "ctx_exception"]
}
```

`CountTool` — uses `body` param:
```json
{
  "query": {"range": {"@timestamp": {"gte": "...", "lte": "...", "format": "strict_date_optional_time||epoch_millis"}}}
}
```

## Known Indices

- `gelf-YYYY.MM.DD` — application logs (Graylog format), 2026-01 to present
- Example: "_index": "gelf-2026.06.02", use wildcard for index name "gelf-*"

## GELF Index Notes

- `@timestamp` — `date` type, ISO 8601
- `level` — 0=emerg, 1=alert, 2=crit, 3=error, 4=warning, 5=notice, 6=info, 7=debug
- `ctx_exception` — JSON string with `class`, `message`, `code`, `file`, `trace`
- `ctx_*` fields — business context (loan_id, payment_id, client_id, etc.)
- All `gelf-*` indices `yellow` — 1 replica, single-node cluster, normal
- Use `filter` (not `must`) for range/term queries — no scoring overhead
