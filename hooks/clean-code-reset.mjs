#!/usr/bin/env node
// Hook SessionStart (compact|resume): apaga os marcadores da sessão para que a
// próxima edição de código injete o clean-code de novo, já que o contexto foi resumido.
import { rmSync } from 'node:fs'
import { readPayload, sessionMarkersDir } from './clean-code-session.mjs'

try {
  rmSync(sessionMarkersDir(readPayload()), { recursive: true, force: true })
} catch (error) {
  console.error(`[clean-code-reset] ${error.message}`)
  process.exit(1)
}
