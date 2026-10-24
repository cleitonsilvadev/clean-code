// Estado compartilhado dos hooks do clean-code: payload do hook e marcadores de
// "skill já injetada", um por sessão e por agente (subagentes não herdam contexto).
import { readFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

const STDIN_FD = 0
const MARKERS_ROOT = join(tmpdir(), 'clean-code-hook')
const MAIN_AGENT_ID = 'main'

export const readPayload = () => JSON.parse(readFileSync(STDIN_FD, 'utf8'))

export const sessionMarkersDir = (payload) => join(MARKERS_ROOT, payload.session_id)

export const agentMarkerPath = (payload) =>
  join(sessionMarkersDir(payload), payload.agent_id ?? MAIN_AGENT_ID)
