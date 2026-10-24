#!/usr/bin/env node
// Registra (install) ou remove (uninstall) os hooks do clean-code em um settings.json
// do Claude Code, preservando todo o resto. Idempotente: instalar duas vezes não duplica.
//
// Uso: node configure-settings.mjs <install|uninstall> <settings.json> [hooksDirNoComando]
//   hooksDirNoComando: como o settings.json referencia a pasta dos hooks (ex.:
//   '$HOME/.claude/hooks'); o shell do hook expande a variável em tempo de execução.
import { existsSync, readFileSync, renameSync, writeFileSync } from 'node:fs'

const SETTINGS_INDENT = 2
const HOOK_TIMEOUT_SECONDS = 5
const OWNED_COMMAND = /clean-code-(inject|reset)\.mjs/
const HOOK_DEFINITIONS = [
  { event: 'PreToolUse', matcher: 'Edit|Write|MultiEdit|NotebookEdit', script: 'clean-code-inject.mjs' },
  { event: 'SessionStart', matcher: 'compact|resume', script: 'clean-code-reset.mjs' }
]

const readSettings = (settingsPath) => {
  if (!existsSync(settingsPath)) return {}

  try {
    return JSON.parse(readFileSync(settingsPath, 'utf8'))
  } catch (error) {
    throw new Error(`${settingsPath} não é um JSON válido (nada foi alterado): ${error.message}`, {
      cause: error
    })
  }
}

const writeSettings = (settingsPath, settings) => {
  const temporaryPath = `${settingsPath}.clean-code.tmp`

  writeFileSync(temporaryPath, `${JSON.stringify(settings, null, SETTINGS_INDENT)}\n`)
  renameSync(temporaryPath, settingsPath)
}

const withoutOwnedHooks = (matcherGroup) => ({
  ...matcherGroup,
  hooks: (matcherGroup.hooks ?? []).filter((hook) => !OWNED_COMMAND.test(hook.command ?? ''))
})

const removeOwnedHooks = (settings) => {
  const cleanedEvents = Object.entries(settings.hooks ?? {})
    .map(([event, matcherGroups]) => [
      event,
      matcherGroups.map(withoutOwnedHooks).filter((group) => group.hooks.length > 0)
    ])
    .filter(([, matcherGroups]) => matcherGroups.length > 0)

  const { hooks: _previousHooks, ...otherSettings } = settings

  if (cleanedEvents.length === 0) return otherSettings

  return { ...otherSettings, hooks: Object.fromEntries(cleanedEvents) }
}

const addOwnedHooks = (settings, hooksDir) => {
  const hooks = { ...settings.hooks }

  for (const { event, matcher, script } of HOOK_DEFINITIONS) {
    const command = `node "${hooksDir}/${script}"`
    const matcherGroup = { matcher, hooks: [{ type: 'command', command, timeout: HOOK_TIMEOUT_SECONDS }] }

    hooks[event] = [...(hooks[event] ?? []), matcherGroup]
  }

  return { ...settings, hooks }
}

const main = () => {
  const [action, settingsPath, hooksDir] = process.argv.slice(2)

  if (action === 'uninstall' && settingsPath) {
    if (!existsSync(settingsPath)) return

    return writeSettings(settingsPath, removeOwnedHooks(readSettings(settingsPath)))
  }

  if (action === 'install' && settingsPath && hooksDir) {
    const settings = removeOwnedHooks(readSettings(settingsPath))

    return writeSettings(settingsPath, addOwnedHooks(settings, hooksDir))
  }

  throw new Error('uso: configure-settings.mjs <install|uninstall> <settings.json> [hooksDir]')
}

try {
  main()
} catch (error) {
  console.error(`[configure-settings] ${error.message}`)
  process.exit(1)
}
