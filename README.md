# Tdarr MCP

A FastMCP server that exposes the endpoints in `tdarr.openapi.json` as MCP tools. The document must be a valid OpenAPI 3.x specification; Swagger/OpenAPI 2.0 is not converted by this project.

## Skill

A skill is provided which can be used to assist with investigating failed transcode jobs

```shell
npx skills add hollanbm/tdarr-mcp
```

## Generate the OpenAPI specification

Generate `tdarr.openapi.json` repeatably from Tdarr's published Swagger 2 document:

```bash
make openapi TDARR_URL=https://tdarr.tld
```

The target pins `swagger2openapi`, enables its source repair mode, removes the invalid empty `externalDocs` object emitted from Tdarr's source, and verifies with `uv tool run fastmcp inspect` that FastMCP can load every generated tool before replacing the existing file. Override the source when needed:

```bash
make openapi TDARR_URL=https://your-tdarr.example.com
# Or provide the complete documentation URL:
make openapi TDARR_DOCS_URL=https://your-tdarr.example.com/api/v2/public/api-docs/json
```

## Run

Python 3.11+ and [`uv`](https://docs.astral.sh/uv/) are recommended:

```bash
export TDARR_URL=http://localhost:8265
# If API authentication is enabled in Tdarr:
export TDARR_API_KEY=your-api-key

uv run tdarr-mcp
```

The server uses Streamable HTTP and listens on `http://0.0.0.0:8000/mcp` by default. Example Codex MCP configuration:

```toml
[mcp_servers.tdarr]
url = "http://localhost:8000/mcp"
```

Configuration variables:

- `MCP_HOST` — HTTP bind address (default `0.0.0.0`)
- `MCP_PORT` — HTTP port (default `8000`)
- `MCP_PATH` — Streamable HTTP endpoint path (default `/mcp`)
- `TDARR_URL` — Tdarr server URL (default `http://localhost:8265`)
- `TDARR_API_KEY` — optional API key
- `TDARR_API_KEY_HEADER` — API-key header (default `X-API-Key`)
- `TDARR_TIMEOUT` — HTTP timeout in seconds (default `30`)
- `TDARR_OPENAPI_PATH` — optional alternate specification path
