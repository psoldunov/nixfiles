/** Loops whose context holds the humanizer skill: `main`, or a subagent's id. */
export type LoadedLoops = string[]

declare module 'claude-code' {
  interface PluginState {
    'humanizer-gate': { loaded: LoadedLoops }
  }
}
