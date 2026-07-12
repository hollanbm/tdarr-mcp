ARG UV_VERSION=0.11.28
ARG RUNTIME_IMAGE=dhi.io/debian-base:trixie

FROM ghcr.io/astral-sh/uv:${UV_VERSION}-debian AS builder

# https://docs.astral.sh/uv/reference/environment/
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_PREFERENCE=only-managed \
    UV_NO_DEV=1 \
    UV_NO_EDITABLE=1 \
    UV_FROZEN=1

# Keep the managed Python installation separate so it can be copied cleanly.
ENV UV_PYTHON_INSTALL_DIR=/python

WORKDIR /tdarr-mcp

# Install dependencies separately to maximize Docker layer caching.
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --no-install-project

COPY README.md tdarr.openapi.json pyproject.toml uv.lock /tdarr-mcp/
COPY src /tdarr-mcp/src
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync

FROM ${RUNTIME_IMAGE} AS runtime

COPY --from=builder --chown=nonroot:nonroot /python /python
COPY --from=builder --chown=nonroot:nonroot /tdarr-mcp /tdarr-mcp

WORKDIR /tdarr-mcp
USER nonroot

ENV PATH="/tdarr-mcp/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1

EXPOSE 8000

ENTRYPOINT ["tdarr-mcp"]
