# Milestone 2: Log Readers

**Goal**: Fully implement `ClaudeCodeLogReader` and `CodexLogReader` so they can discover sessions, parse log files, and emit structured `AgentActivity` events. Every behavior is tested against fixture files from Milestone 1.

**Human involvement needed at end**: Run the app on their machine to verify it discovers real Claude Code sessions in `~/.claude/projects/`. Confirm parsed activities match actual terminal output.

**Depends on**: Milestone 1 (test infra, fixtures, fixture loader)

---

## Tasks

### 2.1 Implement ClaudeCodeLogReader.discoverSessions()
- **What**: Scan `~/.claude/projects/` for session directories. Each subdirectory under a project hash contains a `sessions/` folder with `.jsonl` files.
- **Behavior**:
  - Returns a dictionary mapping session ID (UUID from filename) → file path
  - Ignores non-`.jsonl` files
  - Returns empty dict if `~/.claude/` doesn't exist (no crash)
  - Handles permission errors gracefully (skip inaccessible dirs)
- **Test**: Use fixture loader to create a temp directory mimicking `~/.claude/projects/<hash>/sessions/`, place fixture `.jsonl` files in it. Verify discovery returns correct session IDs and paths.

### 2.2 Implement ClaudeCodeLogReader.readActivities()
- **What**: Read a `.jsonl` file from a given byte offset, parse new lines, return `[AgentActivity]` and the new offset.
- **Behavior**:
  - Reads from `afterOffset` to end of file
  - Parses each JSONL line independently (one bad line doesn't break the whole read)
  - Returns new offset = end of last successfully read line
  - Returns empty array if offset is at end of file (no new data)
- **Test**: Load `simple-session.jsonl` fixture. Read from offset 0, verify activities returned. Read again from returned offset, verify empty (no new data).

### 2.3 Implement ClaudeCodeLogReader.parseLogEntry() — tool_use detection
- **What**: Parse a single JSONL line and extract tool_use events from `message.content` array.
- **Behavior**:
  - Detects `type: "tool_use"` content blocks
  - Extracts `name` (tool name) and `input` (tool arguments)
  - Maps tool name to `ActivityType`: Read/Glob/Grep → `.read`, Write/Edit → `.write`, Bash → `.bash`, WebSearch/WebFetch → `.webSearch`
  - Unknown tools → `.thinking`
- **Test**: Parse the `multi-tool-session.jsonl` fixture line by line. Verify each tool_use produces the correct `ActivityType`.

### 2.4 Implement ClaudeCodeLogReader.parseLogEntry() — text and metadata extraction
- **What**: Extract non-tool data from JSONL lines.
- **Behavior**:
  - Lines with `type: "text"` content blocks (no tool_use) → `ActivityType.thinking`
  - Extract `timestamp` field and parse to `Date`
  - Extract `message.usage.input_tokens` and `output_tokens`
  - Extract `message.stop_reason` — `"end_turn"` → `.finished` activity
  - Extract `message.model` field
  - Extract `sessionId` field
- **Test**: Parse `simple-session.jsonl`. Verify timestamps are parsed, token counts are non-zero, stop_reason "end_turn" produces a `.finished` activity.

### 2.5 Implement ClaudeCodeLogReader.parseLogEntry() — error detection
- **What**: Detect error conditions in log entries.
- **Behavior**:
  - `type: "result"` lines with error content → `ActivityType.error`
  - Tool results with `is_error: true` → `ActivityType.error`
  - Include error message in `AgentActivity.summary`
- **Test**: Parse `error-session.jsonl`. Verify at least one activity has type `.error` and a non-empty summary.

### 2.6 Implement ClaudeCodeLogReader — file path extraction for thought bubbles
- **What**: Extract the primary file path or command from tool_use inputs for display in thought bubbles.
- **Behavior**:
  - Read tool → extract `file_path` from input → summary: "Reading src/auth/middleware.ts"
  - Write/Edit tool → extract `file_path` → summary: "Writing src/models/User.ts"
  - Bash tool → extract `command` → summary: "Running npm test" (truncate long commands)
  - Grep tool → extract `pattern` → summary: "Searching for 'handleAuth'"
  - Glob tool → extract `pattern` → summary: "Searching for '**/*.ts'"
  - Thinking → summary: "Thinking..."
- **Test**: Parse `multi-tool-session.jsonl`. Verify each activity has a human-readable `summary` matching the patterns above.

### 2.7 Implement CodexLogReader.discoverSessions()
- **What**: Scan `~/.codex/history/` for `.json` files.
- **Behavior**:
  - Returns dictionary mapping session ID → file path
  - Session ID derived from filename (timestamp-based)
  - Returns empty dict if `~/.codex/` doesn't exist
  - Ignores non-`.json` files
- **Test**: Create temp directory mimicking `~/.codex/history/`, place Codex fixture files. Verify discovery.

### 2.8 Implement CodexLogReader.readActivities()
- **What**: Parse a Codex session JSON file and extract activities from the `items` array.
- **Behavior**:
  - Reads entire file (Codex files are complete JSON, not streaming JSONL)
  - Parses `items` array, iterates through `functionCalls` on assistant items
  - Maps function names: `file_read` → `.read`, `file_write`/`file_edit` → `.write`, `shell` → `.bash`
  - Extracts timestamps from `startTime`/`endTime`
  - Returns activities sorted by order in items array
- **Test**: Load `simple-session.json` and `multi-tool-session.json` fixtures. Verify correct ActivityType mapping and activity count.

### 2.9 Implement CodexLogReader — error detection
- **What**: Detect errors in Codex sessions.
- **Behavior**:
  - Shell commands with non-zero exit codes → `ActivityType.error`
  - Function calls with error output → `ActivityType.error`
- **Test**: Load `error-session.json`. Verify error activities are detected.

### 2.10 Implement CodexLogReader — summary extraction
- **What**: Extract human-readable summaries for thought bubbles.
- **Behavior**:
  - `file_read` → "Reading <path>"
  - `file_write`/`file_edit` → "Writing <path>"
  - `shell` → "Running <command>" (join command array, truncate at 40 chars)
  - Assistant text without function calls → "Thinking..."
- **Test**: Verify summaries from multi-tool fixture match expected patterns.

### 2.11 Test incremental reading of growing Claude Code log files
- **What**: Simulate a log file that grows over time (appending new lines).
- **Test behavior**:
  - Create a temp `.jsonl` file with 3 lines
  - Read activities from offset 0 → get 3 activities, note new offset
  - Append 2 more lines to the file
  - Read activities from previous offset → get exactly 2 new activities
  - Append 0 lines → read returns empty
- **Why this matters**: This is how real log files work — Claude Code appends lines as the agent works.

### 2.12 Test malformed log data resilience
- **What**: Verify readers don't crash on bad data.
- **Test behavior**:
  - JSONL file with an invalid JSON line in the middle → other lines still parse
  - JSONL file with missing `type` field → line is skipped
  - Codex JSON file with missing `items` array → returns empty activities
  - Empty files → return empty activities
  - Files with only whitespace → return empty activities

### 2.13 Test session ID extraction and uniqueness
- **What**: Verify session IDs are correctly extracted and unique across readers.
- **Test behavior**:
  - Claude Code: session ID matches the UUID filename (without .jsonl extension)
  - Codex: session ID is derived from the filename
  - Two different sessions never produce the same ID

### 2.14 Verify log readers compile and integrate
- **What**: Run `swift build && swift test`. All log reader tests pass. No regressions in Milestone 1 tests.
- **Milestone gate**: Do not proceed until all tests pass.

---

## Parallelism

The following tasks can be done in parallel:
- **[2.1–2.6]** (Claude Code reader) and **[2.7–2.10]** (Codex reader) are fully independent
- **[2.11, 2.12, 2.13]** are independent integration tests (but depend on 2.1–2.10 being done)
- **2.14** depends on everything above
