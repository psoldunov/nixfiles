# Obsidian MCP Tools Reference

Both vaults expose identical tools. Replace `{vault}` with `obsidian-personal` or `obsidian-boundary`.

## Reading

### `{vault}:search_notes`
Search by content or frontmatter. Start here before reading individual notes.
- `query` (string, required) — search keywords
- `searchContent` (bool, default true) — search note body
- `searchFrontmatter` (bool, default false) — search YAML frontmatter
- `limit` (number, default 5, max 20)
- `caseSensitive` (bool, default false)

### `{vault}:read_note`
Read full content of a single note.
- `path` (string, required) — path relative to vault root, e.g. `People/Tyler Leonard.md`

### `{vault}:read_multiple_notes`
Batch read up to 10 notes.
- `paths` (string[], required)

### `{vault}:get_frontmatter`
Extract only frontmatter without loading content. Use for quick metadata checks.
- `path` (string, required)

### `{vault}:get_notes_info`
Get metadata (size, modified date) for multiple notes without reading content.
- `paths` (string[], required)

### `{vault}:get_vault_stats`
Vault-level stats: total notes, folders, size, recently modified files.
- `recentCount` (number, default 5, max 20)

### `{vault}:list_directory`
List files and subdirectories at a path.
- `path` (string, default "/")

### `{vault}:list_all_tags`
List all tags across the vault with occurrence counts. Use before creating new tags to maintain consistency.

## Writing

### `{vault}:write_note`
Create or overwrite a note. This is the primary write tool.
- `path` (string, required) — e.g. `People/Ned.md`
- `content` (string, required) — markdown body (do NOT include frontmatter here)
- `frontmatter` (object, optional) — YAML frontmatter as a JSON object
- `mode` (string, default "overwrite") — `overwrite`, `append`, or `prepend`

**Important:** Always pass frontmatter via the `frontmatter` parameter, not as YAML in the content string. This ensures proper formatting.

### `{vault}:update_frontmatter`
Update frontmatter without touching note content. Use for status changes, date bumps, adding relations.
- `path` (string, required)
- `frontmatter` (object, required) — fields to update
- `merge` (bool, default true) — merge with existing frontmatter (true) or replace entirely (false)

## Organizing

### `{vault}:manage_tags`
Add, remove, or list tags on a note.
- `path` (string, required)
- `operation` (string, required) — `add`, `remove`, or `list`
- `tags` (string[], required for add/remove)

### `{vault}:move_note`
Move or rename a note.
- `oldPath` (string, required)
- `newPath` (string, required)
- `overwrite` (bool, default false)

### `{vault}:delete_note`
Permanently delete a note. Requires confirmation.
- `path` (string, required)
- `confirmPath` (string, required) — must match `path` exactly