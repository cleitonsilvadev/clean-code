.PHONY: install link project hooks uninstall help

help:
	@echo "Clean Code Skill - Comandos disponíveis:"
	@echo "  make install    - Instala globalmente (cópia dos arquivos)"
	@echo "  make link       - Instala globalmente com symlink (desenvolvimento)"
	@echo "  make project    - Instala no diretório atual (.agents/skills + link em .claude/skills)"
	@echo "  make hooks      - Instala os hooks do Claude Code (global)"
	@echo "  make uninstall  - Remove a skill e os hooks, global e localmente"

install:
	@chmod +x install.sh
	@./install.sh --global

link:
	@chmod +x install.sh
	@./install.sh --global --symlink

project:
	@chmod +x install.sh
	@./install.sh --project

hooks:
	@chmod +x install.sh
	@./install.sh --hooks

uninstall:
	@chmod +x install.sh
	@./install.sh --uninstall
