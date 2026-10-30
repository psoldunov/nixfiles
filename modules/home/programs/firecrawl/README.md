# Firecrawl Alexandria

This module keeps Firecrawl's CLI and skills in the Nix configuration shared by
Claude Code, Codex, and Pi. It links the complete upstream skill directories
because Alexandria references sibling Firecrawl skills. All four clients use
one Firecrawl API key; the agent MCP clients use
`https://mcp.firecrawl.dev/v2/mcp`. Pi receives the Claude skill links through
`claude-bridge` and reads the MCP server from the shared `mcp.json`.

## Apply

The CLI is pinned to `1.26.24`. Update the tag and lock node with
`nix flake update firecrawl-cli`, then apply with the appropriate named host:

```sh
scripts/switch-host.sh BigMac
# or Whopper, BigTasty, or MacFlurry
```

Do not run Firecrawl's `init` or `setup`; those commands rewrite managed agent
configuration. The wrapper supplies Node 24 and can read the decrypted SOPS
secret at runtime when `FIRECRAWL_API_KEY` is not already exported. It does not
write the key to the Nix store. An explicit environment value always wins.

## API key

Create a free account at <https://www.firecrawl.dev/signin?view=signup>, then
create an API key at <https://www.firecrawl.dev/app/api-keys>. If a key was
posted in chat or another shared place, treat it as exposed: rotate or revoke
it there and use a new key.

Before activation, add the replacement key privately as the `FIRECRAWL_API_KEY`
entry in `secrets/shared.yaml`, using the repository's existing `sops-code` or
SOPS edit workflow. Do not add a placeholder value. Activation remains blocked
until that encrypted entry exists.

The Claude Code module exports this secret from the SOPS runtime path in fish,
zsh, and bash. Claude Code's MCP entry does not depend on that export: a
`headersHelper` script reads the SOPS file on every connect and prints the
`Authorization` header, so agents started by a long-running launcher such as
Concierge authenticate even when their environment predates the key. Codex and
Pi still read `FIRECRAWL_API_KEY` from their environment, so start or restart
them from a shell that has loaded the hooks. This source change does not alter
GUI environment inheritance or activate the configuration.

There is no per-agent OAuth login. The API key unlocks Firecrawl's full MCP
surface subject to the team's access; keyless access does not include
Alexandria. Load the installed Firecrawl skill before asking an agent to query
it, and check the team's entitlement, posted prices, and provider terms first.
Discovery is free (`firecrawl search alexandria '<query>'`), and listing a
provider contract is free (`firecrawl list <provider> <capability> --pretty`).
Scraping a provider or capability with `--options` uses credits. Do not accept
provider terms on the user's behalf. If a response includes `requiresAction.url`, show
that URL to the user for a human decision.

This module does not change the existing SearXNG defaults or generic web-search
routing.
