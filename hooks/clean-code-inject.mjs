#!/usr/bin/env node
// Hook PreToolUse (Edit|Write|MultiEdit|NotebookEdit): na primeira edição de código
// da sessão (por agente), injeta o SKILL.md do clean-code no contexto. As edições
// seguintes passam em silêncio; o hook clean-code-reset.mjs libera nova injeção
// depois de compact/resume. Arquivo que não é código passa sem injetar.
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, extname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { agentMarkerPath, readPayload } from './clean-code-session.mjs'

// A pasta hooks/ é irmã de skills/ tanto em ~/.claude quanto em <projeto>/.claude.
const SKILL_PATH = join(dirname(fileURLToPath(import.meta.url)), '..', 'skills', 'clean-code', 'SKILL.md')
const FRONTMATTER = /^---\n[\s\S]*?\n---\n/
const CODE_EXTENSIONS = new Set([
  '.js', '.mjs', '.cjs', '.jsx', '.ts', '.mts', '.cts', '.tsx',
  '.py', '.go', '.rs', '.java', '.kt', '.scala', '.rb', '.php', '.cs', '.swift',
  '.c', '.cc', '.cpp', '.h', '.hpp', '.dart', '.lua', '.ex', '.exs', '.zig',
  '.sh', '.sql', '.vue', '.svelte', '.ipynb'
])
const FALLBACK_REMINDER =
  'Lembrete (CLAUDE.md global): invoque a skill clean-code via Skill antes de editar código.'

const readTargetPath = (payload) =>
  payload.tool_input?.file_path ?? payload.tool_input?.notebook_path ?? ''

const isCodeFile = (filePath) => CODE_EXTENSIONS.has(extname(filePath).toLowerCase())

/** Cria o marcador de forma atômica; false quando outra chamada já o criou. */
const claimMarker = (markerPath) => {
  mkdirSync(dirname(markerPath), { recursive: true })

  try {
    writeFileSync(markerPath, '', { flag: 'wx' })

    return true
  } catch (error) {
    if (error.code === 'EEXIST') return false

    throw error
  }
}

const buildContext = () => {
  try {
    const skillBody = readFileSync(SKILL_PATH, 'utf8').replace(FRONTMATTER, '')

    return (
      'Skill clean-code injetada pelo hook antes da primeira edição de código ' +
      `desta sessão (não precisa invocá-la de novo):\n\n${skillBody}`
    )
  } catch {
    // Sem o SKILL.md instalado, o lembrete ainda é melhor que silêncio.
    return FALLBACK_REMINDER
  }
}

const main = () => {
  const payload = readPayload()

  if (!isCodeFile(readTargetPath(payload))) return
  if (!claimMarker(agentMarkerPath(payload))) return

  const output = {
    hookSpecificOutput: { hookEventName: 'PreToolUse', additionalContext: buildContext() }
  }

  process.stdout.write(JSON.stringify(output))
}

try {
  main()
} catch (error) {
  // Falha do hook não pode travar a edição: sai com 1 (não bloqueia) e diz o motivo.
  console.error(`[clean-code-inject] ${error.message}`)
  process.exit(1)
}
