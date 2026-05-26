# Obsidian Setup Guide — N0.V4

## What Is a Vault

A vault is just a folder on your phone. Obsidian watches that folder
and treats every .md file inside it as a note. Nothing more.

Your vault location: `/storage/emulated/0/N0VA/`

This same folder is visible in:
- **Obsidian** — note editor
- **Markor** — markdown viewer/editor
- **Termux** — at `~/storage/shared/N0VA/`
- **GitHub** — after running the sync setup below
- **Claude Code** — can read/write notes directly

---

## First Time in Obsidian

1. Open Obsidian
2. Tap **Create new vault**
3. Vault name: `N0VA`
4. Storage: **Store in device storage**
5. Tap **Create**

---

## Making Notes

- **New note:** tap the pencil/+ icon
- **Open note:** tap folder icon → tap note name
- **Bold:** `**text**`
- **Heading:** `# My Heading`
- **Link to another note:** `[[note name]]`
- **Checkbox:** `- [ ] task`

---

## Recommended First Notes to Create

- `00 - Index.md` — your home page, links to everything
- `Projects/N0VA.md` — your AI workstation project
- `Daily/2026-05-26.md` — today's notes (use date format for daily notes)
- `Resources/Links.md` — useful links and references

---

## Useful Community Plugins (Settings → Community Plugins)

- **Obsidian Git** — auto-sync vault to GitHub
- **Dataview** — query your notes like a database
- **Calendar** — visual calendar for daily notes
- **Templater** — note templates with variables

To install: Settings → Community Plugins → Browse → search name → Install → Enable

---

## Git Sync Setup

Run this in Termux to turn your vault into a git repo:

```
bash ~/android-cowork/obsidian/vault_git_init.sh
```

This:
1. Initializes git in your vault folder
2. Creates a .gitignore for Obsidian cache files
3. Makes the first commit
4. Gives you the command to push to GitHub

---

## Claude Code + Obsidian

To have Claude Code work inside your vault:

```
cd ~/storage/shared/N0VA
claude
```

Claude can now read, create, and edit your notes directly.
Ask it things like:
- "Summarize all my project notes"
- "Create a note for today's session"
- "Find all notes that mention Vertex AI"
- "Move my Google Keep imports into organized folders"
