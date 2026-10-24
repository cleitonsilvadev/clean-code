#!/usr/bin/env bash

set -e

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SKILL_NAME="clean-code"
REPO_RAW_URL="https://raw.githubusercontent.com/cleitonsilvadev/clean-code/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" 2>/dev/null && pwd || echo "")"
HOOK_FILES=(clean-code-inject.mjs clean-code-reset.mjs clean-code-session.mjs)
CONFIGURE_SCRIPT="configure-settings.mjs"
# Literais de propósito: o shell que roda o hook expande $HOME e $CLAUDE_PROJECT_DIR.
# shellcheck disable=SC2016
GLOBAL_HOOKS_COMMAND_DIR='$HOME/.claude/hooks'
# shellcheck disable=SC2016
PROJECT_HOOKS_COMMAND_DIR='$CLAUDE_PROJECT_DIR/.claude/hooks'

print_banner() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}     Clean Code Skill - Instalador     ${NC}"
  echo -e "${BLUE}========================================${NC}"
}

show_help() {
  echo "Uso: ./install.sh [opções] ou curl ... | bash -s -- [opções]"
  echo ""
  echo "Opções:"
  echo "  -g, --global       Instala globalmente em ~/.agents/skills, com link em ~/.claude/skills"
  echo "                     (Claude Code, OpenCode, Codex, Cursor, Windsurf, Cline, Pi, Warp, Zed...)"
  echo "  -p, --project      Instala no projeto em .agents/skills, com link em .claude/skills"
  echo "      --hooks [dir]  Instala os hooks do Claude Code que injetam a skill na 1ª edição de código"
  echo "                     (sem dir: global em ~/.claude; com dir: em <dir>/.claude; requer node)"
  echo "  -s, --symlink      Cria links simbólicos (requer repositório local)"
  echo "  -u, --uninstall    Remove a skill dos destinos configurados"
  echo "  -h, --help         Exibe esta mensagem de ajuda"
  echo ""
  echo "Exemplos:"
  echo "  ./install.sh                 # Global (~/.agents/skills + ~/.claude/skills)"
  echo "  ./install.sh --project       # No projeto atual (.agents/skills + .claude/skills)"
  echo "  ./install.sh --hooks         # Hooks globais (~/.claude)"
  echo "  ./install.sh --hooks .       # Hooks no projeto atual (.claude)"
}

# Parse argumentos
MODE="global"
USE_SYMLINK=false
UNINSTALL=false
TARGET_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--global)
      MODE="global"
      shift
      ;;
    -p|--project)
      MODE="project"
      if [[ -n "$2" && "$2" != -* ]]; then
        TARGET_DIR="$2"
        shift
      else
        TARGET_DIR="."
      fi
      shift
      ;;
    --hooks)
      MODE="hooks"
      TARGET_DIR=""
      if [[ -n "$2" && "$2" != -* ]]; then
        TARGET_DIR="$2"
        shift
      fi
      shift
      ;;
    -s|--symlink)
      USE_SYMLINK=true
      shift
      ;;
    -u|--uninstall)
      UNINSTALL=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED}Opção inválida: $1${NC}"
      show_help
      exit 1
      ;;
  esac
done

fetch_repo_file() {
  local repo_path="$1"
  local dest_file="$2"

  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/${repo_path}" ]; then
    cp "$SCRIPT_DIR/${repo_path}" "$dest_file"
    return
  fi

  curl -fsSL "${REPO_RAW_URL}/${repo_path}" -o "$dest_file"
}

require_node() {
  if command -v node > /dev/null 2>&1; then
    return
  fi

  echo -e "  ${RED}✗${NC} Os hooks precisam do node (https://nodejs.org) para editar o settings.json."
  exit 1
}

run_configure_settings() {
  local action="$1"
  local settings_file="$2"
  local command_dir="${3:-}"
  local helper_dir
  local status=0

  helper_dir="$(mktemp -d)"
  fetch_repo_file "hooks/${CONFIGURE_SCRIPT}" "${helper_dir}/${CONFIGURE_SCRIPT}"
  node "${helper_dir}/${CONFIGURE_SCRIPT}" "$action" "$settings_file" "$command_dir" || status=$?
  rm -rf "$helper_dir"

  return "$status"
}

install_hooks() {
  local claude_dir="$1"
  local command_dir="$2"
  local hooks_dir="${claude_dir}/hooks"
  local hook_file

  require_node
  mkdir -p "$hooks_dir"

  for hook_file in "${HOOK_FILES[@]}"; do
    fetch_repo_file "hooks/${hook_file}" "${hooks_dir}/${hook_file}"
  done

  run_configure_settings install "${claude_dir}/settings.json" "$command_dir"
  echo -e "  ${GREEN}✓${NC} Hooks instalados em: ${hooks_dir} (registrados em ${claude_dir}/settings.json)"
  echo -e "  ${BLUE}Nota:${NC} os hooks leem a skill de ${claude_dir}/skills/clean-code; instale-a no mesmo escopo."
}

uninstall_hooks() {
  local claude_dir="$1"
  local settings_file="${claude_dir}/settings.json"
  local hook_file

  for hook_file in "${HOOK_FILES[@]}"; do
    rm -f "${claude_dir}/hooks/${hook_file}"
  done

  if [ ! -f "$settings_file" ]; then
    return
  fi

  if ! command -v node > /dev/null 2>&1; then
    echo -e "  ${YELLOW}!${NC} node não encontrado: remova os hooks clean-code de ${settings_file} manualmente."
    return
  fi

  run_configure_settings uninstall "$settings_file"
  echo -e "  ${YELLOW}✓${NC} Hooks removidos de: ${claude_dir}"
}

install_to_path() {
  local base_dir="$1"
  local dest_dir="${base_dir}/${SKILL_NAME}"

  mkdir -p "$base_dir"

  if [ -e "$dest_dir" ] || [ -L "$dest_dir" ]; then
    rm -rf "$dest_dir"
  fi

  if [ "$USE_SYMLINK" = true ]; then
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/SKILL.md" ]; then
      ln -s "$SCRIPT_DIR" "$dest_dir"
      echo -e "  ${GREEN}✓${NC} Symlink criado em: ${dest_dir} -> ${SCRIPT_DIR}"
    else
      echo -e "  ${RED}✗${NC} Modo symlink requer execução a partir do repositório local."
      exit 1
    fi
  else
    mkdir -p "$dest_dir"
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/SKILL.md" ]; then
      cp "$SCRIPT_DIR/SKILL.md" "$dest_dir/"
      cp "$SCRIPT_DIR/reference.md" "$dest_dir/"
    else
      echo -e "  ${BLUE}Baixando arquivos da skill...${NC}"
      curl -fsSL "${REPO_RAW_URL}/SKILL.md" -o "${dest_dir}/SKILL.md"
      curl -fsSL "${REPO_RAW_URL}/reference.md" -o "${dest_dir}/reference.md"
    fi
    echo -e "  ${GREEN}✓${NC} Instalado com sucesso em: ${dest_dir}"
  fi
}

# A cópia real fica em <raiz>/.agents/skills (lida por Codex, Cline, Pi, Warp, Zed...);
# o Claude Code lê <raiz>/.claude/skills, que só aponta para ela (mesmo layout do `npx skills`).
install_skill() {
  local root="$1"
  local claude_skills_dir="${root}/.claude/skills"

  install_to_path "${root}/.agents/skills"

  mkdir -p "$claude_skills_dir"
  rm -rf "${claude_skills_dir:?}/${SKILL_NAME}"
  ln -s "../../.agents/skills/${SKILL_NAME}" "${claude_skills_dir}/${SKILL_NAME}"
  echo -e "  ${GREEN}✓${NC} Link para o Claude Code: ${claude_skills_dir}/${SKILL_NAME}"
}

uninstall_from_path() {
  local base_dir="$1"
  local dest_dir="${base_dir}/${SKILL_NAME}"

  if [ -e "$dest_dir" ] || [ -L "$dest_dir" ]; then
    rm -rf "$dest_dir"
    echo -e "  ${YELLOW}✓${NC} Removido de: ${dest_dir}"
  fi
}

print_banner

if [ "$UNINSTALL" = true ]; then
  echo -e "${YELLOW}Removendo Clean Code Skill...${NC}"
  uninstall_from_path "$HOME/.claude/skills"
  uninstall_from_path "$HOME/.agents/skills"
  uninstall_from_path "$HOME/.config/opencode/skills"
  uninstall_from_path "./.claude/skills"
  uninstall_from_path "./.agents/skills"
  uninstall_from_path "./.opencode/skills"
  uninstall_hooks "$HOME/.claude"
  uninstall_hooks "./.claude"
  echo -e "${GREEN}Desinstalação concluída com sucesso!${NC}"
  exit 0
fi

if [ "$MODE" = "global" ]; then
  echo -e "${BLUE}Instalando globalmente em ~/.agents/skills, com link em ~/.claude/skills...${NC}"
  install_skill "$HOME"
elif [ "$MODE" = "project" ]; then
  echo -e "${BLUE}Instalando no projeto (${TARGET_DIR}/.agents/skills, com link em .claude/skills)...${NC}"
  install_skill "$TARGET_DIR"
elif [ "$MODE" = "hooks" ] && [ -z "$TARGET_DIR" ]; then
  echo -e "${BLUE}Instalando hooks globalmente em ~/.claude...${NC}"
  install_hooks "$HOME/.claude" "$GLOBAL_HOOKS_COMMAND_DIR"
elif [ "$MODE" = "hooks" ]; then
  echo -e "${BLUE}Instalando hooks no projeto (${TARGET_DIR}/.claude)...${NC}"
  install_hooks "${TARGET_DIR}/.claude" "$PROJECT_HOOKS_COMMAND_DIR"
fi

echo ""
echo -e "${GREEN}🎉 Clean Code Skill instalada com sucesso!${NC}"
if [ "$USE_SYMLINK" = true ]; then
  echo -e "${BLUE}Nota:${NC} As alterações feitas no repositório serão refletidas imediatamente na skill."
fi
