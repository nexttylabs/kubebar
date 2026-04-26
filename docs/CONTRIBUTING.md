# Contributing

## Pull Request Notes

Every pull request should describe the user impact first. If a change is
user-facing, include a changelog fragment in `changelog.d/` and paste the same
release-note-ready sentence into the PR template.

Internal-only changes can skip a fragment when the PR explains why.

## Codex Prompt for Pull Requests

```text
Please create a pull request for the current branch.

Requirements:
1. Read git diff, git status, recent commits, and .github/pull_request_template.md first.
2. Use a Conventional Commits title, such as:
   feat(scope): add ...
   fix(scope): correct ...
   docs(scope): update ...
3. Fill out the full PR template. Do not leave placeholder comments.
4. In Summary, put the user-visible result first, then important internal context.
5. In User Impact, state what users will notice. If nothing user-visible changes, write None.
6. In Changelog, choose exactly one:
   - User-facing change: mention the changelog.d fragment and include one sentence suitable for CHANGELOG.md.
   - Not user-facing: mark changelog as not needed and explain why.
7. In Validation, check only what was actually run.
8. In Security Impact, write None or the concrete impact.
9. In Blast Radius, name what parts of Kubebar could be affected.
10. In Rollback Plan, explain how to undo the change.
11. Before creating the PR, confirm no unrelated files are included.
12. After creating the PR, return the PR link.
```
