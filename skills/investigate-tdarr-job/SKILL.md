---
name: investigate-tdarr-job
description: Diagnose why a Tdarr transcode job failed from its job report. Use when the user asks why a particular Tdarr job or transcode failed, supplies a Tdarr JobId, or wants to inspect current failed transcodes and choose one to investigate.
---

# Investigate a Tdarr Job

Keep the investigation read-only. Do not requeue jobs, change flows, delete reports, or modify Tdarr configuration unless the user explicitly asks.

## Verify the Tdarr MCP server

Complete this preflight before selecting or fetching a job:

1. Inspect the tools available to the current agent. Resolve tools by their HTTP method and path or operation name; do not depend on a host-specific namespace prefix such as `mcp__tdarr__`.

2. Confirm these operations are available before proceeding:

   - Always: `GET /api/v2/status` and `GET /api/v2/job-reports/{jobId}`.
   - When the user did not supply a JobId: `POST /api/v2/client/{clientType}` and `POST /api/v2/crud/db`.
   - Optional report fallback: `GET /api/v2/job-reports/{jobId}/download`.

3. If a required operation is unavailable, stop and list the missing operation or operations. Tell the user that the agent needs access to an active tdarr-mcp server exposing those tools.

4. Call the read-only status operation. For agents that expose the server-qualified generated tool name, the call is:

   ```text
   mcp__tdarr__GET_apiv2status()
   ```

5. Proceed only when the call succeeds. If the MCP endpoint cannot be reached, stop and report that the tdarr-mcp server is inactive or unreachable. If the MCP call reaches the server but the Tdarr API request fails, stop and report that the MCP server's Tdarr connection or credentials need attention. Preserve the concrete error in either case.

## Select the job

If the user supplies one or more JobIds, investigate them directly.

If no JobId is supplied:

1. Query the Tdarr UI failed-transcode table:

   ```text
   mcp__tdarr__POST_apiv2clientclientType({
     clientType: "<verified Tdarr client type>",
     data: {
       start: 0,
       pageSize: 100,
       filters: [],
       sorts: [],
       opts: { table: "table3" }
     }
   })
   ```

2. Obtain the exact `clientType` from the server/API implementation or a known working UI request. Never invent it.

3. Paginate by increasing `start` when more than `pageSize` rows exist.

4. Extract JobIds from the rows when available. If rows contain only file IDs or paths, call the read-only fallback:

   ```text
   mcp__tdarr__POST_apiv2cruddb({
     data: { collection: "JobsJSONDB", mode: "getAll" }
   })
   ```

5. Match records whose status is `Transcode error` by file ID or path, and use each record's `_id` as its JobId. Avoid `getAll` when the table already provides JobIds.

6. Present the failed files with their JobIds and ask the user which one or ones to investigate. Stop before fetching job reports until they choose. If no failures are present, say so.

## Fetch the report

For each selected JobId, call:

```text
mcp__tdarr__GET_apiv2job_reportsjobId({ jobId: "<job-id>" })
```

Independent report calls may run in parallel. Accept typed data from `structuredContent` or JSON serialized inside a `content` text item.

Use `mcp__tdarr__GET_apiv2job_reportsjobIddownload` only if the normal response is unavailable or the raw report must be saved. Do not call `POST /api/v2/read_job_file` when the report endpoint returns complete text.

## Diagnose the failure

1. Confirm `jobReportExists`. Capture the file, status, node names, duration, worker, and flow from `jobRecord` and report metadata.
2. Read the report chronologically. Treat a final Enhanced Fail Flow or other controlled-failure plugin as flow termination, not automatically as the root cause.
3. Locate the earliest decisive upstream error. Search for signals including `Conversion failed`, `Running FFmpeg failed`, `Invalid data`, `Decode error rate`, `Error mapping an input resource`, `Task finished with error code`, `HandBrakeCLI exited with code`, `Duration validation FAILED`, `Size validation FAILED`, `No space left`, `Permission denied`, and `out of memory`.
4. Distinguish processing failures from policy failures:
   - Nonzero FFmpeg/HandBrake exits, decoder or GPU errors, and I/O errors are processing failures.
   - A successful encoder followed by duration or size validation failure is a flow-policy failure.
5. For multiple reports, compare signatures. Repeated decoder or GPU errors across related files may indicate hardware-decoding incompatibility rather than separate corrupt files.

## Report findings

For each job, provide:

- JobId and media file
- Immediate failure
- Root cause, or the strongest evidence-based hypothesis clearly labeled as an inference
- A targeted next action

Quote only decisive log lines. Preserve exact evidence such as exit codes, decode-error percentages, duration differences, and size thresholds.
