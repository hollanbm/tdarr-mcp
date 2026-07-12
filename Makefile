TDARR_DOCS_URL ?= $(TDARR_URL)/api/v2/public/api-docs/json
OPENAPI_FILE ?= tdarr.openapi.json
SWAGGER2OPENAPI_VERSION ?= 7.0.8
FASTMCP_VERSION ?= >=3,<4
FASTMCP_SERVER ?= src/tdarr_mcp/server.py:mcp

.PHONY: openapi validate run

# Fetch Tdarr's Swagger 2 document, convert it to OpenAPI 3, remove generated
# source metadata and the invalid empty externalDocs object, then validate it.
openapi:
	npx --yes -p swagger2openapi@$(SWAGGER2OPENAPI_VERSION) \
		swagger2openapi --patch --outfile "$(OPENAPI_FILE)" "$(TDARR_DOCS_URL)"
	jq 'del(."x-origin") | del(.externalDocs | select(. == {}))' \
		"$(OPENAPI_FILE)" > "$(OPENAPI_FILE).tmp"
	mv "$(OPENAPI_FILE).tmp" "$(OPENAPI_FILE)"
	$(MAKE) validate

validate:
	TDARR_OPENAPI_PATH="$(OPENAPI_FILE)" uv tool run \
		--from 'fastmcp-slim[server]$(FASTMCP_VERSION)' fastmcp inspect \
		--project . "$(FASTMCP_SERVER)"

run:
	TDARR_URL="$(TDARR_URL)" uv run tdarr-mcp
