# Changelog Fragments

Use this directory to capture release-note-ready text during PR work.

## When to add a fragment

Add a fragment for user-facing changes:

- New behavior or visible improvements
- Bug fixes users can notice
- Documentation changes users or contributors rely on
- Security or permission-related changes

Skip fragments for internal-only changes when the PR template explains why.

## File naming

Name fragments with this format:

```text
<short-description>.<type>.md
```

Supported types:

- `added`
- `changed`
- `deprecated`
- `removed`
- `fixed`
- `security`
- `documentation`

Examples:

```text
k9s-handoff.added.md
release-note-validation.fixed.md
permission-guide.documentation.md
```

## Content

Write one or more user-facing bullet lines:

```markdown
- Validate release notes before publishing GitHub Releases.
```

Plain lines are also accepted and will be converted to bullets during release
preparation.

After release preparation, merged fragments are removed and the finalized notes
live in `CHANGELOG.md`.
