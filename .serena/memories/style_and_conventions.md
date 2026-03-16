# Style and conventions
- Swift code uses explicit access control, doc comments on many public APIs, and `// MARK:` sections to organize large files.
- Scene logic favors small private helpers on `OfficeScene` and stateful sprite classes like `AgentSprite`.
- Tests use the `Testing` package with `@Test` and `#expect`/`#require`.
- Naming is descriptive and camelCase; scene node names use stable string prefixes like `desk_`, `monitor_`, `agent_` for lookup in tests and runtime logic.
