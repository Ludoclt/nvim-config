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

## Languages

| Language                | Language server, tools                                        | Status |
| ----------------------- | ------------------------------------------------------------- | ------ |
| C / C++                 | clangd, clang-format, codelldb; make and CMake tasks          | ready  |
| CMake                   | neocmakelsp, cmakelint, cmake-format                          | ready  |
| Embedded (Cortex-M...)  | clangd with cross compilers, OpenOCD, GDB remote debugging    | ready  |
| Verilog / SystemVerilog | verible (lint, format, navigation), Verilator lint            | ready  |
| VHDL                    | vhdl_ls (rust_hdl), VSG (format, style lint)                  | ready  |
| Python, web, Java, C#, Rust |                                                           | next   |

How to use them day to day: [docs/CHEATSHEET.md](docs/CHEATSHEET.md), section
"Build and debug".

### Project templates

`:Template {name}` copies starter files into the current directory, never
overwriting existing ones:

- `c`: a `.clang-format` (LLVM style, 4-space indent).
- `embedded`: `.clang-format`, a `.clangd` that drops GCC-only flags clangd
  rejects, and an `openocd.cfg` with ST-Link, Pico and ESP32 examples.
- `verilog`: `.rules.verible_lint` (lint rules), `.verible-format`
  (formatter flags, turns on format on save) and `verilator.f` (Verilator
  options for linting).
- `vhdl`: `vhdl_ls.toml` (libraries for the language server) and
  `vsg_config.yaml` (VSG style, turns on format on save).

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

`bootstrap.sh --without embedded` skips a package group (groups are the
first column of `scripts/packages.txt`).

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
project has a config for the formatter of that filetype, found by walking up
from the file: `.clang-format` for C/C++, `.cmake-format.*` for CMake,
`.verible-format` for Verilog, a VSG config for VHDL,
`rustfmt.toml` or `Cargo.toml` for Rust, `ruff.toml` or a `pyproject.toml`
with `[tool.ruff]`/`[tool.black]` for Python, a Prettier or Biome config for
web files, `stylua.toml` for Lua, `.csharpierrc` for C#. Other filetypes are
not formatted on save. The rules are in `lua/config/format.lua`.

- `<leader>cf` formats by hand, anywhere.
- `<leader>uF` toggles format on save for the current buffer (use it to turn
  it on in a project without a formatter config), `<leader>uf` globally.
- `:LazyFormatInfo` shows the state and the formatters for a buffer.

## Layout

```text
init.lua                 entry point
lazy-lock.json           pinned plugin versions
lazyvim.json             enabled LazyVim extras (:LazyExtras)
lua/config/              options, keymaps, autocmds, AZERTY layer, format rule,
                         :Template command
lua/plugins/             plugin specs, one file per area (cpp.lua, embedded.lua,
                         hdl.lua)
templates/               files copied by :Template
scripts/bootstrap.sh     system packages (scripts/packages.txt)
scripts/sync.sh          pull + install locked plugin versions
scripts/smoke-test.sh    headless test, also run by CI
tests/smoke.lua          test runner; checks in tests/suites/, sample projects
                         in tests/samples/
docs/                    cheat sheet, AZERTY layer reference
```

## Test

```bash
scripts/smoke-test.sh
```

Runs Neovim headless in isolated directories under `.tests/` (it never touches
the real `~/.local/share/nvim`), installs the locked plugins, parsers and
Mason packages, then runs the suites in `tests/suites/`: startup errors, the
AZERTY aliases, the keymaps listed in the cheat sheet, the format rule, and
per language the language servers, build tasks and debugging on sample
projects. CI runs it on every push to `main` and on every pull request.

`SMOKE_OFFLINE=1 scripts/smoke-test.sh` skips the downloads (parsers, Mason)
and the checks that need them.

## One-time GitHub setting

For the weekly pull request: Settings > Actions > General > Workflow
permissions > tick "Allow GitHub Actions to create and approve pull requests".
