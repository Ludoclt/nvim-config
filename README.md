# nvim-config

My Neovim configuration, built on [LazyVim](https://github.com/LazyVim/LazyVim),
shared between my laptop (openSUSE Tumbleweed) and my desktop (Arch Linux).

- **Cheat sheet** for daily and advanced use, with a learning path
  ([docs/CHEATSHEET.md](docs/CHEATSHEET.md)).
- **AZERTY layer**: LazyVim's AltGr-heavy keys get direct aliases
  ([docs/AZERTY.md](docs/AZERTY.md)).
- **Same plugins everywhere**: `lazy-lock.json` pins every plugin; updates come
  as a weekly pull request, tested before they reach `main`.
- **Format on save, only where the project asks for it** (see below).

Language support (C/C++, embedded, Verilog/VHDL, Python, web, Java, C#, Rust)
is being added step by step.

## Install on a new machine

```bash
# Back up an existing config first
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak

git clone git@github.com:Ludoclt/nvim-config.git ~/.config/nvim
~/.config/nvim/scripts/bootstrap.sh            # report missing system packages
~/.config/nvim/scripts/bootstrap.sh --install  # install them (zypper or pacman)
nvim                                           # plugins install on first launch
```

The terminal needs a [Nerd Font](https://www.nerdfonts.com/) for icons.

## Keep machines in sync

Plugin versions live in `lazy-lock.json`, so do not run `:Lazy update`
locally: it would make the machines drift apart. Instead:

1. Every Monday, the `Update plugins` workflow updates all plugins, runs the
   smoke test and opens a pull request with the new lockfile and the result.
2. Merge it if the smoke test passed.
3. On each machine: `~/.config/nvim/scripts/sync.sh` (pull, then install the
   exact versions from the lockfile).

Language servers and tools are installed by Mason on first use (`:Mason`).

## Format on save

LazyVim formats every file on save. On other people's projects that rewrites
whole files and pollutes the diff, so here format on save only runs when the
project has a formatter config, found by walking up from the file:
`.clang-format`, `rustfmt.toml` or `Cargo.toml`, `ruff.toml` or a
`pyproject.toml` with `[tool.ruff]`/`[tool.black]`, a Prettier or Biome
config, `stylua.toml`, `.csharpierrc`. The full list is in
`lua/config/format.lua`.

- `<leader>cf` formats by hand, anywhere.
- `<leader>uF` toggles format on save for the current buffer (use it to turn
  it on in a project without a formatter config), `<leader>uf` globally.
- `:LazyFormatInfo` shows the state and the formatters for a buffer.

## Layout

```text
init.lua                 entry point
lazy-lock.json           pinned plugin versions
lazyvim.json             enabled LazyVim extras (:LazyExtras)
lua/config/              options, keymaps, autocmds, AZERTY layer, format rule
lua/plugins/             plugin specs, one file per area
scripts/bootstrap.sh     system packages (scripts/packages.txt)
scripts/sync.sh          pull + install locked plugin versions
scripts/smoke-test.sh    headless test, also run by CI
tests/smoke.lua          the checks
docs/                    cheat sheet, AZERTY layer reference
```

## Test

```bash
scripts/smoke-test.sh
```

Runs Neovim headless in isolated directories under `.tests/` (it never touches
the real `~/.local/share/nvim`), installs the locked plugins and parsers, then
checks startup errors, the AZERTY aliases, the keymaps listed in the cheat
sheet and the format rule. CI runs it on
every push to `main` and on every pull request.

## One-time GitHub setting

For the weekly pull request: Settings > Actions > General > Workflow
permissions > tick "Allow GitHub Actions to create and approve pull requests".
