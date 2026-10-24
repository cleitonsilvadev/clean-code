[English](INSTALL.md) | **Português**

---

# 📦 Guia de Instalação — Clean Code Skill

Este guia detalha todas as formas de instalar, atualizar e remover a **Clean Code Skill** para assistentes de IA como **Claude Code**, **OpenCode** e ferramentas compatíveis com o padrão **Agent Skills**.

---

## 📑 Índice

- [⚡ 1. Instalação Rápida via `curl` ou `npx` (Recomendado)](#1-instalacao-rapida-via-curl-ou-npx)
- [🐙 2. Instalação via `git clone`](#2-instalacao-via-git-clone)
- [🔗 3. Instalação via Symlink (Modo Desenvolvedor)](#3-instalacao-via-symlink)
- [📁 4. Instalação por Projeto (Compartilhamento com a Equipe)](#4-instalacao-por-projeto)
- [🛠️ 5. Usando o Script Local (`install.sh` ou `Makefile`)](#5-usando-o-script-local)
- [🪝 6. Hooks do Claude Code (Carga Automática na Primeira Edição)](#6-hooks-do-claude-code)
- [🔄 Como Atualizar](#como-atualizar)
- [🗑️ Como Desinstalar](#como-desinstalar)

---

<a id="1-instalacao-rapida-via-curl-ou-npx"></a>
## ⚡ 1. Instalação Rápida via `curl` ou `npx` (Recomendado)

A forma mais rápida de instalar sem precisar clonar repositório manualmente.

### Via `curl`:

**Global (Claude Code e OpenCode):**
```bash
curl -fsSL https://raw.githubusercontent.com/cleitonsilvadev/clean-code/main/install.sh | bash
```

**Por Projeto (diretório atual):**
```bash
curl -fsSL https://raw.githubusercontent.com/cleitonsilvadev/clean-code/main/install.sh | bash -s -- --project
```

### Via `npx`:

Execute diretamente via Node.js / npm:

```bash
npx skill-clean-code
npx skill-clean-code --project
```

### Via `npx skills` (qualquer agente)

O repositório é compatível com a CLI aberta [`skills`](https://github.com/vercel-labs/skills), que detecta os agentes instalados na sua máquina (Claude Code, Codex, Cline, Pi, Warp, Zed e vários outros) e instala a skill em cada um:

```bash
npx skills add cleitonsilvadev/clean-code            # no projeto atual
npx skills add cleitonsilvadev/clean-code -g         # global
npx skills add cleitonsilvadev/clean-code -a claude-code -a codex
```

> Ela copia o repositório inteiro para a pasta da skill (docs, hooks, instalador). Use o `install.sh` se quiser só o `SKILL.md` e o `reference.md`.

### Onde o `install.sh` coloca a skill

A cópia real vai para `~/.agents/skills/clean-code` (ou `.agents/skills/` no projeto) — a pasta lida por Codex, Cursor, Windsurf, Cline, Pi, Warp, Zed e outros. O Claude Code lê `.claude/skills/`, que guarda um symlink para essa cópia (mesmo layout do `npx skills`). O OpenCode também lê `~/.claude/skills/`.

Você também pode especificar um caminho de projeto personalizado:

```bash
curl -fsSL https://raw.githubusercontent.com/cleitonsilvadev/clean-code/main/install.sh | bash -s -- --project /caminho/do/projeto
```

---

<a id="2-instalacao-via-git-clone"></a>
## 🐙 2. Instalação via `git clone`

Ideal para manter um repositório git gerenciável e atualizável via `git pull`.

### Para Claude Code & OpenCode:

```bash
git clone https://github.com/cleitonsilvadev/clean-code.git ~/.claude/skills/clean-code
```

> **Nota:** O OpenCode descobre e carrega automaticamente as skills localizadas em `~/.claude/skills/`. Uma única instalação atende a ambos os assistentes!

### Como atualizar via Git:

```bash
git -C ~/.claude/skills/clean-code pull
```

---

<a id="3-instalacao-via-symlink"></a>
## 🔗 3. Instalação via Symlink (Modo Desenvolvedor)

Se você clonou este repositório em sua máquina (por exemplo, em `~/projects/clean-code`) e deseja fazer alterações na skill ou no guia de referência que tenham **efeito imediato** sem precisar reinstalar:

```bash
mkdir -p ~/.claude/skills

# Symlink para Claude Code e OpenCode
ln -s ~/projects/clean-code ~/.claude/skills/clean-code
```

---

<a id="4-instalacao-por-projeto"></a>
## 📁 4. Instalação por Projeto (Compartilhamento com a Equipe)

Para garantir que todos os desenvolvedores e agentes trabalhando no mesmo repositório sigam as mesmas diretrizes:

### Como pasta direta:

```bash
git clone https://github.com/cleitonsilvadev/clean-code.git .claude/skills/clean-code
```

### Como Git Submodule:

```bash
git submodule add https://github.com/cleitonsilvadev/clean-code.git .claude/skills/clean-code
```

---

<a id="5-usando-o-script-local"></a>
## 🛠️ 5. Usando o Script Local (`install.sh` ou `Makefile`)

Se você já clonou este repositório localmente:

### Usando o `install.sh`:

```bash
# Instalação global padrão (cópia)
./install.sh

# Instalação com symlink
./install.sh --symlink

# Instalação no diretório do projeto atual
./install.sh --project

# Ver todas as opções
./install.sh --help
```

### Usando o `Makefile`:

```bash
make install    # Instalação global (cópia)
make link       # Instalação global via symlink
make project    # Instalação no projeto atual
make uninstall  # Desinstalação completa
make help       # Lista todos os comandos disponíveis
```

---

<a id="6-hooks-do-claude-code"></a>
## 🪝 6. Hooks do Claude Code (Carga Automática na Primeira Edição)

Opcional. Instala dois hooks do Claude Code para que o agente nunca edite código sem a skill no contexto:

- `PreToolUse` (`Edit|Write|MultiEdit|NotebookEdit`): na **primeira edição de código de cada sessão** (e de cada subagente), injeta o `SKILL.md` no contexto. As edições seguintes passam em silêncio; arquivos que não são código (`.md`, `.json`, …) são ignorados.
- `SessionStart` (`compact|resume`): zera esse estado, porque o contexto foi resumido e a skill pode ter se perdido.

```bash
./install.sh --hooks              # global: ~/.claude/hooks + ~/.claude/settings.json
./install.sh --hooks .            # projeto: ./.claude/hooks + ./.claude/settings.json
curl -fsSL https://raw.githubusercontent.com/cleitonsilvadev/clean-code/main/install.sh | bash -s -- --hooks
```

Requisitos e comportamento:

- Precisa de `node` (ele mescla as entradas no `settings.json` sem tocar nos seus outros hooks; rodar duas vezes não duplica nada).
- Os hooks leem a skill da pasta irmã `skills/clean-code/`, então instale a skill no **mesmo escopo** (`./install.sh` para global, `./install.sh --project` para projeto).
- Os hooks valem só para sessões novas. `./install.sh --uninstall` remove os hooks junto com a skill.

---

<a id="como-atualizar"></a>
## 🔄 Como Atualizar

- **Se instalou via `curl`:** Basta rodar novamente o comando de instalação via `curl`. Os arquivos existentes serão sobrescritos com as versões mais recentes.
- **Se instalou via `git clone`:** Execute `git -C <pasta_da_skill> pull`.
- **Se instalou via Symlink:** Suas alterações no repositório já estão sincronizadas em tempo real.

---

<a id="como-desinstalar"></a>
## 🗑️ Como Desinstalar

Para remover a skill dos diretórios padrão:

```bash
# Usando o instalador
./install.sh --uninstall

# Ou via make
make uninstall

# Ou manualmente
rm -rf ~/.claude/skills/clean-code ~/.agents/skills/clean-code
rm -rf .claude/skills/clean-code .agents/skills/clean-code
```
