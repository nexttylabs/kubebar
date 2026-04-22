# Quick Task 260422-fk1: 修复kubectl no such file or directory问题，kubectl使用brew安装 - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Task Boundary

修复 Kubebar app 内执行 `kubectl` 时出现 `no such file or directory` 的问题。`kubectl` 已通过 Homebrew 安装。

</domain>

<decisions>
## Implementation Decisions

### Executable lookup
- Treat this as an app runtime PATH issue. The app should be able to find Homebrew-installed `kubectl` when launched from Finder or Login Items, without requiring a shell-launched environment.

### Homebrew compatibility
- Include both Apple Silicon and Intel Homebrew bin directories in the command runner search path: `/opt/homebrew/bin` and `/usr/local/bin`.

### Product behavior
- Keep existing stale and failure handling. If `kubectl` still fails, Kubebar should keep reporting a safe failure reason instead of showing stale data as healthy.

### Agent discretion
- Keep the change at the injectable command boundary and cover it with focused tests.

</decisions>

<specifics>
## Specific Ideas

- Preserve the existing `CommandRequest(executable: "kubectl", ...)` call sites.
- Ensure subprocesses inherit a PATH that includes the existing environment plus Homebrew and system defaults.

</specifics>

<canonical_refs>
## Canonical References

- `AGENTS.md`
- `docs/architecture/runtime-invariants.md`
- `docs/architecture/system-overview.md`

</canonical_refs>
