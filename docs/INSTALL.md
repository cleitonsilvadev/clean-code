**English** | [Português](INSTALL.pt-BR.md)

---

# 📦 Installation Guide — Clean Code Skill

This guide details all ways to install, update, and remove the **Clean Code Skill** for AI coding assistants such as **Claude Code**, **OpenCode**, and tools compatible with the **Agent Skills** specification.

---

## 📑 Table of Contents

- [⚡ 1. Quick Installation via `curl` or `npx` (Recommended)](#1-quick-installation-via-curl-or-npx)
- [🐙 2. Installation via `git clone`](#2-installation-via-git-clone)
- [🔗 3. Installation via Symlink (Developer Mode)](#3-installation-via-symlink)
- [📁 4. Per-Project Installation (Sharing with Your Team)](#4-per-project-installation)
- [🛠️ 5. Using the Local Script (`install.sh` or `Makefile`)](#5-using-the-local-script)
- [🪝 6. Claude Code Hooks (Auto-load on Every First Edit)](#6-claude-code-hooks)
- [🔄 How to Update](#how-to-update)
- [🗑️ How to Uninstall](#how-to-uninstall)

---

<a id="1-quick-installation-via-curl-or-npx"></a>
## ⚡ 1. Quick Installation via `curl` or `npx` (Recommended)

The fastest way to install without needing to manually clone a repository.

### Via `curl`:

**Global (Claude Code and OpenCode):**
```bash
curl -fsSL https://raw.githubusercontent.com/cleitonsilvadev/clean-code/main/install.sh | bash
```

**Per Project (current directory):**
```bash
curl -fsSL https://raw.githubusercontent.com/cleitonsilvadev/clean-code/main/install.sh | bash -s -- --project
```

### Via `npx`:

Run directly with Node.js / npm:

```bash
npx skill-clean-code
npx skill-clean-code --project
```

### Via `npx skills` (any agent)

The repository is compatible with the open [`skills`](https://github.com/vercel-labs/skills) CLI, which detects the agents installed on your machine (Claude Code, Codex, Cline, Pi, Warp, Zed, and many more) and installs the skill for each:

```bash
npx skills add cleitonsilvadev/clean-code            # in the current project
npx skills add cleitonsilvadev/clean-code -g         # global
npx skills add cleitonsilvadev/clean-code -a claude-code -a codex
```

> It copies the whole repository into the skill folder (docs, hooks, installer). Use `install.sh` if you want only `SKILL.md` and `reference.md`.

### Where `install.sh` puts the skill

The real copy goes to `~/.agents/skills/clean-code` (or `.agents/skills/` in a project) — the folder read by Codex, Cursor, Windsurf, Cline, Pi, Warp, Zed and others. Claude Code reads `.claude/skills/`, which holds a symlink to that copy (same layout as `npx skills`). OpenCode also reads `~/.claude/skills/`.

You can also specify a custom project path:

```bash
curl -fsSL https://raw.githubusercontent.com/cleitonsilvadev/clean-code/main/install.sh | bash -s -- --project /path/to/project
```

---

<a id="2-installation-via-git-clone"></a>
## 🐙 2. Installation via `git clone`

Ideal for keeping a manageable Git repository updated via `git pull`.

### For Claude Code & OpenCode:

```bash
git clone https://github.com/cleitonsilvadev/clean-code.git ~/.claude/skills/clean-code
```

> **Note:** OpenCode automatically discovers and loads skills located in `~/.claude/skills/`. A single installation serves both assistants!

### How to update via Git:

```bash
git -C ~/.claude/skills/clean-code pull
```

---

<a id="3-installation-via-symlink"></a>
## 🔗 3. Installation via Symlink (Developer Mode)

If you have cloned this repository on your machine (e.g., in `~/projects/clean-code`) and want to edit the skill or the reference guide with **immediate effect** without reinstalling:

```bash
mkdir -p ~/.claude/skills

# Symlink for Claude Code and OpenCode
ln -s ~/projects/clean-code ~/.claude/skills/clean-code
```

---

<a id="4-per-project-installation"></a>
## 📁 4. Per-Project Installation (Sharing with Your Team)

To ensure all developers and AI agents working on the same repository follow the exact same standards:

### As a standalone cloned folder:

```bash
git clone https://github.com/cleitonsilvadev/clean-code.git .claude/skills/clean-code
```

### As a Git Submodule:

```bash
git submodule add https://github.com/cleitonsilvadev/clean-code.git .claude/skills/clean-code
```

---

<a id="5-using-the-local-script"></a>
## 🛠️ 5. Using the Local Script (`install.sh` or `Makefile`)

If you have already cloned this repository locally:

### Using `install.sh`:

```bash
# Default global installation (copy files)
./install.sh

# Installation with symlink
./install.sh --symlink

# Installation in current project directory
./install.sh --project

# View all options
./install.sh --help
```

### Using the `Makefile`:

```bash
make install    # Global installation (copy)
make link       # Global installation via symlink
make project    # Install in current project
make uninstall  # Complete uninstallation
make help       # List all available commands
```

---

<a id="6-claude-code-hooks"></a>
## 🪝 6. Claude Code Hooks (Auto-load on Every First Edit)

Optional. Installs two Claude Code hooks so the agent never edits code without the skill in context:

- `PreToolUse` (`Edit|Write|MultiEdit|NotebookEdit`): on the **first code edit of each session** (and of each subagent) it injects `SKILL.md` into the context. Later edits pass silently; non-code files (`.md`, `.json`, …) are ignored.
- `SessionStart` (`compact|resume`): resets that state, since the context was summarized and the skill may be gone.

```bash
./install.sh --hooks              # global: ~/.claude/hooks + ~/.claude/settings.json
./install.sh --hooks .            # project: ./.claude/hooks + ./.claude/settings.json
curl -fsSL https://raw.githubusercontent.com/cleitonsilvadev/clean-code/main/install.sh | bash -s -- --hooks
```

Requirements and behavior:

- Needs `node` (it merges the entries into `settings.json` without touching your other hooks; running it twice does not duplicate anything).
- The hooks read the skill from the sibling `skills/clean-code/` folder, so install the skill in the **same scope** (`./install.sh` for global, `./install.sh --project` for project).
- Hooks apply to new sessions only. `./install.sh --uninstall` removes them along with the skill.

---

<a id="how-to-update"></a>
## 🔄 How to Update

- **If installed via `curl`:** Simply re-run the installation command via `curl`. Existing files will be overwritten with the latest versions.
- **If installed via `git clone`:** Run `git -C <skill_directory> pull`.
- **If installed via Symlink:** Your changes in the cloned repo are reflected in real time automatically.

---

<a id="how-to-uninstall"></a>
## 🗑️ How to Uninstall

To remove the skill from default directories:

```bash
# Using the installer
./install.sh --uninstall

# Or using make
make uninstall

# Or manually
rm -rf ~/.claude/skills/clean-code ~/.agents/skills/clean-code
rm -rf .claude/skills/clean-code .agents/skills/clean-code
```
