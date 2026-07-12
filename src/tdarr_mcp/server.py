"""Expose the Tdarr HTTP API as FastMCP tools."""

from __future__ import annotations

import json
import os
from pathlib import Path

import httpx
from fastmcp import FastMCP

SPEC_PATH = Path(__file__).with_name("tdarr.openapi.json")


def create_server() -> FastMCP:
    spec_path = Path(os.getenv("TDARR_OPENAPI_PATH", SPEC_PATH))
    spec = json.loads(spec_path.read_text())
    headers: dict[str, str] = {}
    if api_key := os.getenv("TDARR_API_KEY"):
        headers[os.getenv("TDARR_API_KEY_HEADER", "X-API-Key")] = api_key
    client = httpx.AsyncClient(
        base_url=os.getenv("TDARR_URL", "http://localhost:8265"),
        headers=headers,
        timeout=float(os.getenv("TDARR_TIMEOUT", "30")),
    )
    return FastMCP.from_openapi(openapi_spec=spec, client=client, name="Tdarr API")


mcp = create_server()


def main() -> None:
    mcp.run(
        transport="streamable-http",
        host=os.getenv("MCP_HOST", "0.0.0.0"),
        port=int(os.getenv("MCP_PORT", "8000")),
        path=os.getenv("MCP_PATH", "/mcp"),
    )


if __name__ == "__main__":
    main()
