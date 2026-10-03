# Fully Nix-managed Neovim

Status: planned; configuration has been inspected, implementation has not started.
Audience: coding agent picking up this migration.

## Goal and settled decisions

Manage the existing Neovim configuration, plugins, Tree-sitter parsers, and
editor-support executables through this repository's Home Manager configuration.
After deployment, opening Neovim on a fresh Ubuntu agent VM must not download
plugins/parsers or compile anything. Preserve the current Mac editor experience.

- Use plain Home Manager `programs.neovim`, **not NixVim**.
- Keep editor settings, keybindings, and plugin setup as ordinary Lua.
- Replace `vim.pack` installation/update behavior with Nix dependencies.
- Replace runtime Tree-sitter installation with Nix-built parsers and queries.
- Keep writable editor state separate from immutable configuration.
- Package acquisition/builds may require network during Nix deployment; editor
  startup and local editing must not require installation-time network access.
- Do not introduce Mason, another runtime package manager, or a compiler/PATH
  workaround for runtime parser installation.

## Repository context

Read `AGENTS.md` before implementation. Relevant existing files:

- `flake.nix`: locked nixpkgs unstable + Home Manager inputs.
- `profiles/base.nix`: shared editor/shell configuration; import the new module here.
- `profiles/dev.nix` and `profiles/agent.nix`: both import base and common packages.
- `modules/common/packages.nix`: currently installs plain `neovim`; remove that
  entry when the module owns the wrapped Neovim. `clojure-lsp` is currently in
  the Darwin-only package list; the editor must have it on Linux too.
- `modules/common/env.nix`: already sets `EDITOR` and `VISUAL` to `nvim`.
  Preserve this behavior and avoid conflicting default-editor declarations.
- `modules/programs/helix.nix`: example of a focused Home Manager editor module.
- `assets/`: existing location for linked configuration assets.
- `plans/agent-vms.md`: Ubuntu + standalone Home Manager deployment details.
- `Makefile`: `make fmt`, `make lint`, `make build`, `make check`, `make switch`.

Targets currently exposed by the flake:

| Home configuration | System |
| --- | --- |
| `mitkuijp` | `aarch64-darwin` |
| `exedev` | `x86_64-linux` |
| `exedev-arm` | `aarch64-linux` |
| `shellbox` | `x86_64-linux` |

Build Linux closures on Linux, not by assuming the Mac can cross-build them.

## Source configuration and inventory

The source currently lives **outside this repo** at
`/Users/mitkuijp/.config/nvim` (`~/.config/nvim` on the owner's Mac).
This plan does not snapshot it. If picking this up on another machine, obtain
that directory from the owner before implementing; do not recreate it from
this inventory or silently substitute a starter configuration.

The active setup is MiniMax/mini.nvim with built-in `vim.pack`, **not LazyVim**.
Old LazyVim artifacts coexist with the active files. Reinspect the live source
before copying because it may have changed since this plan was written.

Active files observed:

```text
init.lua
plugin/10_options.lua
plugin/20_keymaps.lua
plugin/30_mini.lua
plugin/40_plugins.lua
after/ftplugin/markdown.lua
after/lsp/clojure_lsp.lua
after/lsp/lua_ls.lua
after/snippets/lua.json
snippets/global.json
```

Inspect any `lua/` files for actual references before including them. Preserve
applicable upstream license/attribution. Do not blindly import `MiniMax-backup/`,
old LazyVim configuration/locks, `nvim-pack-lock.json`, caches, or mutable spell
files. Read the current pack lock as migration/version evidence first.

### Plugins observed (13)

| Upstream | Purpose |
| --- | --- |
| `nvim-mini/mini.nvim` | Core UI/editing modules and scheduling helpers |
| `nvim-treesitter/nvim-treesitter` | Queries and Tree-sitter support |
| `nvim-treesitter/nvim-treesitter-textobjects` | Textobject queries |
| `neovim/nvim-lspconfig` | Server configurations |
| `stevearc/conform.nvim` | Formatting; currently LSP fallback |
| `rafamadriz/friendly-snippets` | Snippet collection |
| `catppuccin/nvim` | Theme (`catppuccin-macchiato`) |
| `julienvincent/nvim-paredit` | Structural editing |
| `nvim-lua/plenary.nvim` | Shared plugin dependency |
| `esmuellert/codediff.nvim` | Diff UI; inspect native-library requirements |
| `NeogitOrg/neogit` | Git UI |
| `Olical/conjure` | REPL integration |
| `nickjvandyke/opencode.nvim` | OpenCode integration |

Do not assume nixpkgs attribute names, availability, or versions from upstream
names. Resolve them against the repository's locked nixpkgs revision.

### Tree-sitter and language tooling observed

- Configured parsers: `lua`, `vimdoc`, `markdown`, `clojure`, `typescript`,
  `javascript`, `json`, `json5`, `toml`, `yaml`, `nix`.
- Consider companion grammars such as `markdown_inline` and `tsx` where needed
  by queries or filetypes; add them deliberately, not all available grammars.
- Enabled LSP configurations: `clojure_lsp`, `vtsls`, `jsonls`.
- A `lua_ls` configuration exists but the server is not currently enabled.
  Do not enable new servers silently.
- Conform currently has `lsp_format = 'fallback'` and no explicit formatter map.
  Preserve that rather than adding formatting rules as part of migration.
- `init.lua` installs mini.nvim before requiring `mini.misc`. It defines
  `Config.now`, `Config.later`, `Config.now_if_args`, event helpers, and
  `Config.on_packchanged`.
- `plugin/40_plugins.lua` registers a `TSUpdate` pack hook, adds plugins, and
  invokes `require('nvim-treesitter').install(...)` for missing parsers.
- Keymaps include shortcuts to edit files under `stdpath('config')`; mini.files
  also has config/plugin-directory bookmarks. Review these for Nix store paths.

## Implementation phases

### 1. Audit compatibility before choosing packages

- Record source plugin revisions from the current pack lock and inspect the
  installed Neovim version. Establish which versions/APIs the config needs.
- Check the locked nixpkgs Neovim and plugin packages. The config uses modern
  `vim.lsp.enable()`/`vim.lsp.config()` and mini.nvim modules such as
  `mini.cmdline`/`mini.keymap`; older packages may not suffice.
- Check the Tree-sitter branch/API packaged by nixpkgs. Match the plugin,
  parser definitions, and textobject queries; do not casually combine current
  upstream queries with unrelated parser revisions.
- Prefer existing nixpkgs packages. If unavailable or incompatible, use a
  small pinned override/custom derivation with explicit revision and hash.
  Avoid an unrelated whole-flake update or global overlay unless necessary.
- Inspect CodeDiff's native dependency and auto-download behavior. Supply the
  matching native artifact through Nix and configure its lookup, or use an
  existing derivation that already does so. This is a compatibility gate,
  not a detail to leave to first launch. Report blockers instead of dropping it.

### 2. Snapshot Lua and add the Home Manager module

- Copy audited active files into `assets/nvim/`.
- Create `modules/programs/neovim.nix` with `programs.neovim.enable`, a plugin
  list, and `extraPackages` for editor-support executables.
- Link the Lua config using Home Manager's XDG file facilities. Keep the
  directory writable where necessary, e.g. recursive/per-file links rather
  than accidentally freezing all of `~/.config/nvim`.
- Verify the locked Home Manager module's initialization/loading behavior.
  Preserve the existing `init.lua` + `plugin/*.lua` ordering and ensure Nix
  plugins are on the runtime path when `init.lua` requires `mini.misc`.
  Do not install a second competing init file or run config twice.
- Import the module from `profiles/base.nix`; remove plain `neovim` from
  common packages. Leave aliases/editor environment settings unchanged.
- New Nix files AND config assets must be visible to the Git-based flake
  before evaluation (stage the new files; do not commit without being asked).

### 3. Remove runtime dependency management, retain setup

- Remove the mini.nvim bootstrap and all active `vim.pack.add()` calls.
- Remove unused pack-change hooks/helpers and package-manager update docs.
- Preserve plugin `setup()` calls, colorscheme, keybindings, and scheduling
  helpers (`Config.now`, `later`, etc.) where useful.
- Start with Nix-managed plugins available through the normal runtime path.
  Do not add a lazy-loading framework just to reproduce pack installation.
- Remove parser install calls and the `TSUpdate` hook. Use the locked
  nixpkgs Tree-sitter packaging API (e.g. `withPlugins`, where supported)
  to provide the selected parser binaries and matching queries.
- Retain highlighting activation and mini.ai/textobject behavior. Check that
  startup with no arguments, with a file, and opening a file later all work.
- Review package-manager-specific plugin bookmarks and shortcuts that edit
  immutable config. Point config-edit shortcuts at the repo source where
  reliably available, or document a portable alternative; do not hardcode
  the owner's Mac path or assume all VMs have the repo in the same location.

### 4. Supply external tools and isolate mutable state

- Package `clojure-lsp`, the executable required by `vtsls`, and the executable
  required by `jsonls` via `extraPackages`, using verified nixpkgs packages.
  Include required runtimes and check actual server commands, not only names.
- Audit supporting executables used by the configuration/plugins (Git,
  ripgrep, fd, OpenCode integration, etc.). Existing profile packages can
  satisfy them; avoid introducing conflicting standalone Neovim packages.
- Do not add formatters that the config does not use. Optional improvements
  such as enabling LuaLS belong in a separate change.
- Keep sessions, visits/history, caches, undo/shada, and personal spell files
  in writable XDG state/data/cache locations. Audit implicit downloads such
  as spell dictionaries if enabled; provide required static assets via Nix.
- A Conjure REPL, project dependencies, and OpenCode/provider authentication
  remain runtime services/project setup, not guaranteed by editor packaging.
  Ensure an absent service does not trigger installation or break startup.

### 5. Validate without relying on the owner's existing plugin cache

Run repository checks:

```sh
make fmt
make lint
make build
make check
```

Evaluate activation derivations for all four home configurations. Build the
Mac closure on the Mac and Linux closures on suitable Linux builders/VMs;
record which architectures were actually tested and which only evaluated.
For example:

```sh
nix eval --raw .#homeConfigurations.exedev.activationPackage.drvPath
nix eval --raw .#homeConfigurations.exedev-arm.activationPackage.drvPath
nix eval --raw .#homeConfigurations.shellbox.activationPackage.drvPath
# On the matching Linux system:
make build PROFILE=exedev-arm
```

Create an isolated test home/XDG environment with the migrated config installed
and empty data/cache/state directories. Use the **Nix-wrapped Neovim binary**,
not an unrelated `nvim` from PATH. Do not test with `-u NONE`/`--clean`, which
would bypass the configuration under test. If HOME is changed, explicitly
provide the managed test config as well.

Test both headless smoke checks (allow deferred callbacks to run) and an
interactive session. Disconnect/deny network AFTER building the closure to
prove first launch has no install-time requests.

- Start with no arguments and with a file; open another file after startup.
- Open representative Lua, Markdown, Clojure/EDN, JS/TS/TSX, JSON, Nix, and
  YAML files. Assert parser availability from the Nix runtime path, not
  merely that Neovim returned exit code zero.
- Verify highlighting and textobject queries, snippets, theme, and keymaps.
- Check LSP executable availability and attachment in small representative
  projects, preserving the current Clojure root-marker behavior.
- Exercise Neogit and CodeDiff in a disposable Git repository; verify the
  native diff library loads on both Darwin and Linux without downloading.
- Check configured formatting fallback, and behavior when no LSP is attached.
- Run relevant health checks and classify any expected external-service warnings.
- Confirm no plugins/parsers/native binaries appeared as downloaded payloads
  in the fresh data directory and no startup errors were masked by scheduling.
- Confirm writable state works and no operation tries to write into `/nix/store`.

Do not claim offline readiness based only on flake evaluation or warm-cache tests.

### 6. Document and perform a safe cutover

- Add concise README guidance: config location, adding plugins/parsers/tools,
  updating through Nix, and the distinction between deployment downloads and
  offline editor startup. Point to VM deployment instructions where useful.
- Before activation, make a full recoverable backup of the owner's current
  `~/.config/nvim`; retain old plugin data until rollback is no longer needed.
- Check Home Manager target collisions. `make switch` uses backup suffixes,
  but inspect existing backups and do not assume that replaces a full backup.
- Do not run `make switch` or bootstrap/update remote machines without user
  approval. Present validation results and cutover instructions first.
- After approved activation, ensure old vim.pack packages are not shadowing
  Nix-managed versions. Move stale package directories aside only after
  identifying them and obtaining approval; never indiscriminately delete data.
- Document rollback to the prior Home Manager generation plus restoration of
  the original config if needed.

## Acceptance criteria

- [ ] Shared base profile enables the full editor on Mac and Ubuntu targets.
- [ ] Existing Lua configuration, plugins, theme, and keybindings are preserved.
- [ ] All plugin code, Tree-sitter parsers/queries, and required native libraries
      are pinned Nix dependencies; runtime package installers/hooks are gone.
- [ ] Enabled language-server executables are available on both Mac and Linux.
- [ ] Fresh-cache startup and representative editing work with network denied,
      without runtime compilation or a globally installed compiler.
- [ ] Mutable state remains writable; existing config is backed up for cutover.
- [ ] Repository checks and platform validation are recorded with limitations.
- [ ] README describes the new update workflow; no NixVim or unrelated changes.

## Handoff notes

No nixpkgs plugin attributes, native CodeDiff packaging, or platform builds have
been verified yet. Treat these as implementation work, not completed research.
The main risks are package-version compatibility, Tree-sitter query/parser
alignment, and CodeDiff's native dependency. Keep fixes scoped to this migration.

Follow the active environment's tooling/sandbox instructions. A sandbox-denied
build or switch is not a code failure; diagnose it and report the required grant
rather than trying to bypass it. Leave unrelated worktree files untouched.
