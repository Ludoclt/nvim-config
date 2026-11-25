# Neovim cheat sheet

Daily and advanced use of this configuration: Neovim, LazyVim and the AZERTY
layer. Keys are written in Vim notation:

| Notation    | Means                                                       |
| ----------- | ----------------------------------------------------------- |
| `<leader>`  | Space                                                       |
| `<C-x>`     | Ctrl+x                                                      |
| `<S-x>`     | Shift+x                                                     |
| `<A-x>`     | Alt+x                                                       |
| `<CR>`      | Enter                                                       |
| `{motion}`  | any motion (`w`, `$`, `)f`...) or text object (`iw`, `a(`...) |

AZERTY aliases from [AZERTY.md](AZERTY.md): type `(` `)` for `[` `]`, `ù` for
`%`, `à` for `0`, `é` for the local leader, `<C-ù>` for `<C-/>`. Tables below
show the stock key first and the AZERTY way when it differs.

## Finding things yourself

You do not need to memorise this file. These always work:

| Keys          | Does                                                          |
| ------------- | ------------------------------------------------------------- |
| `<leader>`    | wait half a second: which-key shows every key that follows    |
| `(` `)` `g` `z` | same: wait to see what can follow                           |
| `<leader>sk`  | search all keymaps by name, e.g. "rename"                     |
| `<leader>?`   | keymaps of the current buffer (language-specific ones too)    |
| `<leader>sh`  | search Neovim help pages                                      |
| `:Tutor`      | interactive 30-minute tutorial, start here                    |
| `:help {x}`   | help on anything: `:help ciw`, `:help registers`              |
| `<leader>L`   | LazyVim changelog                                             |
| `:checkhealth` | what is broken and why                                       |

## 1. Modes

| Keys                | Does                                                    |
| ------------------- | ------------------------------------------------------- |
| `<Esc>`             | back to Normal mode (and clear search highlight)        |
| `i` / `a`           | insert before / after the cursor                        |
| `I` / `A`           | insert at start / end of line                           |
| `o` / `O`           | open a line below / above                               |
| `v` / `V` / `<C-v>` | visual: characters / lines / block                      |
| `:`                 | command line                                            |
| `R`                 | replace mode (overwrite)                                |

Normal mode is the default: you spend most time there, and only enter Insert
mode to type text.

## 2. Moving

| Keys                  | AZERTY      | Moves to                                       |
| --------------------- | ----------- | ---------------------------------------------- |
| `h` `j` `k` `l`       |             | left, down, up, right                          |
| `w` / `b` / `e`       |             | next word / previous word / end of word        |
| `W` / `B` / `E`       |             | same, words separated by spaces only           |
| `0` / `^` / `$`       | `à` / `_` / `$` | line start / first non-blank / line end    |
| `gg` / `G`            |             | first / last line (`42G`: line 42)             |
| `<C-d>` / `<C-u>`     |             | half a page down / up                          |
| `zz` / `zt` / `zb`    |             | scroll: cursor line to middle / top / bottom   |
| `f{c}` / `t{c}`       |             | to / just before the next `{c}` on the line    |
| `F{c}` / `T{c}`       |             | same, backwards                                |
| `f` `t` again         |             | repeat (flash.nvim), `;` `,` also work         |
| `%`                   | `ù`         | matching bracket                               |
| `s{c}{c}`             |             | flash: type 2 chars, then the label shown      |
| `S`                   |             | flash treesitter: select a code node by label  |
| `]f` / `[f`           | `)f` / `(f` | next / previous function                       |
| `]c` / `[c`           | `)c` / `(c` | next / previous class                          |
| `]a` / `[a`           | `)a` / `(a` | next / previous parameter                      |
| `]i` / `[i`           | `)i` / `(i` | bottom / top of the current scope (indent)     |
| `]]` / `[[`           | `<A-n>` / `<A-p>` | next / previous use of the symbol under cursor |

Counts multiply motions: `5j`, `3w`. On AZERTY digits need Shift.

## 3. Editing: verb + noun

Most editing is an operator (verb) followed by a motion or a text object
(noun). Learn the grammar once and every combination works.

| Operator | Does                                     | Doubled = whole line |
| -------- | ---------------------------------------- | -------------------- |
| `d`      | delete (into a register, like cut)       | `dd`                 |
| `c`      | change: delete, then Insert mode         | `cc`                 |
| `y`      | yank (copy)                              | `yy`                 |
| `>` `<`  | indent / unindent                        | `>>` `<<`            |
| `=`      | re-indent                                | `==`                 |
| `gU` `gu` | uppercase / lowercase                   | `gUU` `guu`          |
| `gc`     | toggle comment                           | `gcc`                |
| `gq`     | format with the language formatter       | `gqq`                |
| `gw`     | wrap text (comments, prose) to the width | `gww`                |

Text objects: `i` = inside, `a` = around (includes delimiters or spaces).

| Object               | Selects                                         |
| -------------------- | ----------------------------------------------- |
| `iw` `aw`            | word                                            |
| `is` `ip`            | sentence, paragraph                             |
| `i"` `i'` `` i` ``   | inside quotes (`iq`: nearest quote of any kind) |
| `i(` `i[` `i{` `i<`  | inside brackets (`ib`: nearest bracket)         |
| `it`                 | inside an HTML/XML tag                          |
| `if` `af`            | function body / whole function                  |
| `ic` `ac`            | class                                           |
| `io` `ao`            | block, conditional or loop                      |
| `ia` `aa`            | function argument                               |
| `iu` `au`            | function call                                   |
| `ii` `ai`            | indentation scope                               |
| `ie`                 | part of a camelCase or snake_case word          |
| `id`                 | number                                          |
| `ig`                 | whole buffer                                    |
| `ih`                 | git hunk                                        |

Add `n` or `l` to target the next or last one: `cin"` changes inside the next
quotes even when the cursor is not in them yet.

Examples: `ciw` change word, `di(` empty the parentheses, `yaf` copy the whole
function, `dap` delete the paragraph, `gcip` comment the paragraph, `=if`
re-indent the function body, `>i{` indent a block.

| Keys                | Does                                                  |
| ------------------- | ----------------------------------------------------- |
| `x`                 | delete the character under the cursor                 |
| `r{c}`              | replace one character with `{c}`                      |
| `p` / `P`           | paste after / before                                  |
| `u` / `<C-r>`       | undo / redo                                           |
| `.`                 | repeat the last change: the most useful key in Vim    |
| `J`                 | join the line below                                   |
| `<A-j>` / `<A-k>`   | move the line (or selection) down / up                |
| `<C-a>` / `<C-x>`   | increment / decrement the number under the cursor     |
| `gco` / `gcO`       | add a comment below / above                           |
| `<leader>su`        | undo tree: browse every past state of the file        |

In Insert mode: `<C-w>` delete the previous word, `<C-u>` delete to line
start, `<C-r>{reg}` paste a register, `<C-o>{cmd}` run one Normal command.

Completion menu (Insert mode): `<C-n>` / `<C-p>` or arrows select, `<CR>`
accepts, `<C-e>` closes, `<C-space>` opens it, `<Tab>` / `<S-Tab>` jump
between snippet fields, `<C-k>` shows the function signature.

## 4. Search and replace

| Keys                 | Does                                                   |
| -------------------- | ------------------------------------------------------ |
| `/text` `<CR>`       | search forward (`?text` backward)                      |
| `n` / `N`            | next / previous match                                  |
| `*` / `#`            | search the word under the cursor forward / backward    |
| `:%s/old/new/g`      | replace in the whole file (`gc` asks at each match)    |
| `:'<,'>s/old/new/g`  | replace in the selection (type `:` in Visual mode)     |
| `<leader>/`          | grep the project                                       |
| `<leader>sw`         | grep the word under the cursor (or the selection)      |
| `<leader>sb`         | search lines of the current buffer                     |
| `<leader>sr`         | search and replace across the project (grug-far)       |
| `<leader>sR`         | reopen the last picker where you left it               |

In any picker: type to filter, `<C-j>` / `<C-k>` move, `<CR>` opens,
`<C-v>` / `<C-s>` open in a vertical / horizontal split, `<C-q>` sends all
results to the quickfix list, `<Esc>` closes.

## 5. Files, buffers, windows

A buffer is an open file, a window shows a buffer, a tab holds windows.

<!-- check: global -->
| Keys                 | Does                                               |
| -------------------- | -------------------------------------------------- |
| `<leader><space>`    | find files in the project                          |
| `<leader>fr`         | recent files                                       |
| `<leader>fc`         | find a file of this Neovim config                  |
| `<leader>e`          | file explorer (`?` inside for its keys)            |
| `<leader>,`          | switch buffer                                      |
| `H` / `L`            | previous / next buffer                             |
| `<leader>bb`         | the other buffer (last one used)                   |
| `<leader>bd`         | close the buffer                                   |
| `<leader>bo`         | close all other buffers                            |
| `<C-s>`              | save                                               |
| `<leader>qq`         | quit everything                                    |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | go to the window left / below / above / right |
| `<leader>-`          | split below                                        |
| `<leader>wd`         | close the window                                   |
| `<leader>wm`         | zoom the window (toggle)                           |
| `<leader>fn`         | new file                                           |

`<C-w>v` splits right (`<leader>|` needs AltGr on AZERTY). Resize windows
with `<C-Up>` `<C-Down>` `<C-Left>` `<C-Right>`.

## 6. Code (language server)

These work once a language server is attached to the buffer (`<leader>cl`
shows which ones).

| Keys           | Does                                                     |
| -------------- | -------------------------------------------------------- |
| `gd`           | go to definition                                         |
| `gr`           | references                                               |
| `gI`           | go to implementation                                     |
| `gy`           | go to type definition                                    |
| `gD`           | go to declaration                                        |
| `K`            | documentation under the cursor (`K` again to enter it)   |
| `gK`           | function signature                                       |
| `<leader>ca`   | code actions (quick fixes, imports...)                   |
| `<leader>cr`   | rename the symbol everywhere                             |
| `<leader>cR`   | rename the file (and update imports)                     |
| `<leader>ss`   | symbols of the file                                      |
| `<leader>cf`   | format the file or the selection                         |
| `<leader>cl`   | language server info                                     |
| `<leader>cm`   | Mason: install or update servers and tools               |
| `<C-o>`        | jump back after `gd` (see Advanced)                      |

## 7. Diagnostics and lists

| Keys               | AZERTY      | Does                                        |
| ------------------ | ----------- | ------------------------------------------- |
| `]d` / `[d`        | `)d` / `(d` | next / previous diagnostic                  |
| `]e` / `[e`        | `)e` / `(e` | next / previous error                       |
| `]w` / `[w`        | `)w` / `(w` | next / previous warning                     |
| `<leader>cd`       |             | diagnostic of the current line              |
| `<leader>xx`       |             | all diagnostics (Trouble panel)             |
| `<leader>xX`       |             | diagnostics of this buffer only             |
| `<leader>sd`       |             | diagnostics picker                          |
| `]q` / `[q`        | `)q` / `(q` | next / previous quickfix entry              |
| `<leader>xq`       |             | quickfix list                               |
| `]t` / `[t`        | `)t` / `(t` | next / previous TODO / FIXME comment        |
| `<leader>st`       |             | search all TODOs                            |

## 8. Git

| Keys               | AZERTY      | Does                                        |
| ------------------ | ----------- | ------------------------------------------- |
| `<leader>gg`       |             | lazygit (`?` inside for its keys)           |
| `]h` / `[h`        | `)h` / `(h` | next / previous changed hunk                |
| `<leader>ghp`      |             | preview the hunk                            |
| `<leader>ghs`      |             | stage the hunk (or the selected lines)      |
| `<leader>ghr`      |             | reset the hunk                              |
| `<leader>ghu`      |             | undo the last stage                         |
| `<leader>ghb`      |             | blame the line                              |
| `<leader>ghd`      |             | diff the file against the index             |
| `<leader>gs`       |             | git status picker                           |
| `<leader>gl`       |             | git log                                     |
| `<leader>gf`       |             | history of the current file                 |
| `<leader>gB`       |             | open the line on GitHub                     |

## 9. Build and debug

Build keys work the same in CMake projects (cmake-tools) and Makefile
projects. Both run as overseer tasks, and compile errors land in the
quickfix list, which opens when a build fails: walk the errors with `)q` /
`(q`.

<!-- check: global -->
| Keys           | Does                                                         |
| -------------- | ------------------------------------------------------------ |
| `<leader>mm`   | build: CMake target `all` (or the one picked with `<leader>mT`), or `make -j` |
| `<leader>mc`   | clean                                                        |
| `<leader>mr`   | run the CMake launch target, or pick a task                  |
| `<leader>mg`   | CMake: configure (writes `compile_commands.json`)            |
| `<leader>mt`   | CMake: build type (Debug, Release...)                        |
| `<leader>mT`   | CMake: build target                                          |
| `<leader>ml`   | CMake: launch target                                         |
| `<leader>md`   | CMake: debug the launch target                               |
| `<leader>mb`   | Makefile: `bear -- make`, writes `compile_commands.json`     |
| `<leader>mo`   | embedded: start the OpenOCD GDB server                       |
| `<leader>mf`   | embedded: flash an ELF with OpenOCD                          |
| `<leader>oo`   | run any task (make targets, npm scripts, VS Code tasks.json) |
| `<leader>ow`   | task list: output, restart, stop                             |

clangd needs `compile_commands.json` to understand a project: CMake writes
it on configure, `bear -- make` does it for Makefiles. `<leader>ch` switches
between a source file and its header.

<!-- check: global -->
| Keys           | Does                                                         |
| -------------- | ------------------------------------------------------------ |
| `<leader>db`   | toggle a breakpoint (`<leader>dB`: with a condition)         |
| `<leader>dc`   | start or continue (asks which configuration)                 |
| `<leader>dO`   | step over                                                    |
| `<leader>di`   | step into                                                    |
| `<leader>do`   | step out                                                     |
| `<leader>dC`   | run to the cursor                                            |
| `<leader>dP`   | pause                                                        |
| `<leader>dt`   | terminate                                                    |
| `<leader>du`   | toggle the debugger UI (variables, stack, watches)           |
| `<leader>de`   | evaluate the expression under the cursor or the selection    |
| `<leader>dr`   | toggle the REPL                                              |

In the REPL of a GDB session, GDB commands work as they are:
`monitor reset halt`, `load`, `x/8xw 0x20000000`, `info registers`.

### Embedded workflow

1. `:Template embedded` in the project root: `openocd.cfg`, `.clangd`
   (drops GCC-only flags clangd rejects) and `.clang-format`. Edit
   `openocd.cfg` for your probe and chip.
2. Build (`<leader>mm`), then `<leader>mb` or CMake configure for
   `compile_commands.json`.
3. `<leader>mf` flashes, then `<leader>mo` starts the GDB server. Only one
   OpenOCD can hold the probe: while the server runs, reflash from the
   debugger REPL with `load` instead.
4. `<leader>dc` > "Embedded: attach to OpenOCD": breakpoints, stepping and
   variables, as on a PC.

## 10. Terminal, sessions, toggles

<!-- check: global -->
| Keys               | Does                                                  |
| ------------------ | ----------------------------------------------------- |
| `<C-/>`            | floating terminal, toggle (AZERTY: `<C-ù>`)           |
| `<C-ù>`            | same                                                  |
| `<leader>ft`       | terminal in the project root                          |
| `<leader>qs`       | restore the session of this directory                 |
| `<leader>ql`       | restore the last session                              |
| `<leader>uf`       | toggle format on save, globally                       |
| `<leader>uF`       | toggle format on save, this buffer only               |
| `<leader>uw`       | toggle line wrap                                      |
| `<leader>ud`       | toggle diagnostics                                    |
| `<leader>uh`       | toggle inlay hints                                    |
| `<leader>us`       | toggle spell checking                                 |
| `<leader>uz`       | zen mode                                              |
| `<leader>uC`       | pick a colorscheme                                    |
| `<leader>.`        | scratch buffer, for notes                             |
| `<leader>n`        | notification history                                  |
| `<leader>l`        | plugin manager (look only: updates come from the CI)  |

In the terminal, press `<Esc>` twice to get Normal mode (to scroll or copy).

## 11. Advanced

### Repeat and jump back

| Keys             | Does                                                     |
| ---------------- | -------------------------------------------------------- |
| `.`              | repeat the last change                                   |
| `<C-o>` / `<C-i>` | back / forward in the jump list (across files)          |
| `g;` / `g,`      | back / forward through the places you edited             |
| `''`             | back to the line before the last jump                    |
| `gi`             | resume Insert mode where you last left it                |
| `gv`             | reselect the last selection                              |

### Several edits without multiple cursors

- `*` on a word, then `cgn`, type the new text, `<Esc>`. Now `.` changes the
  next occurrence, `n` skips one.
- `<C-v>`, select lines, `I` (or `$A` for line ends), type, `<Esc>`: the text
  goes on every line.
- `:%s/\<name\>/new_name/gc` replaces whole words only, asking each time. For
  code symbols, `<leader>cr` is safer.

### Registers

| Keys        | Does                                                          |
| ----------- | ------------------------------------------------------------- |
| `"ayy`      | yank the line into register `a` (`"ap` pastes it)             |
| `"0p`       | paste the last yank, even after deleting something since      |
| `"_d{motion}` | delete without overwriting what you yanked                  |
| `"+y`       | system clipboard (here `y` already uses it)                   |
| `<leader>s"` | browse all registers                                         |

### Macros

| Keys           | Does                                                     |
| -------------- | -------------------------------------------------------- |
| `qa`           | start recording into register `a`, `q` stops            |
| `@a`           | play it, `@@` plays the last one again, `10@a` ten times |
| `:'<,'>norm @a` | play it on every selected line                          |

Record a macro that ends on the next item (e.g. with `j0`), then repeat it.

### Marks

| Keys        | Does                                                          |
| ----------- | ------------------------------------------------------------- |
| `ma`        | set mark `a` in this file (`mA`: global mark, across files)   |
| `'a`        | go to the line of mark `a`                                    |
| `<leader>sm` | browse marks                                                 |

### Command line power tools

| Command                   | Does                                                |
| ------------------------- | --------------------------------------------------- |
| `:g/pattern/d`            | delete every line matching (`:v/pattern/d`: not matching) |
| `:g/pattern/norm A;`      | run Normal keys on every matching line             |
| `:'<,'>sort`              | sort the selected lines (`:sort u`: unique)         |
| `:'<,'>!cmd`              | filter the selection through a shell command        |
| `:r !cmd`                 | insert the output of a shell command                |
| `:cdo s/a/b/g \| update`  | replace in every quickfix entry, e.g. after `<leader>/` and `<C-q>` |

### Folds, case, spelling

| Keys                | AZERTY      | Does                                           |
| ------------------- | ----------- | ---------------------------------------------- |
| `za`                |             | toggle the fold under the cursor               |
| `zR` / `zM`         |             | open / close all folds                         |
| `g~{motion}`        |             | toggle case (`~` alone needs AltGr on AZERTY)  |
| `]s` / `[s`         | `)s` / `(s` | next / previous spelling mistake               |
| `z=`                |             | spelling suggestions                           |
| `zg`                |             | add the word to the dictionary                 |

## Learning path

1. **Day 1**: `:Tutor`. Then code with `<leader><space>`, `<leader>e`,
   `i` / `<Esc>`, `:w`, `u`. Leave the mouse and arrow keys alone.
2. **Week 1**: words (`w` `b` `e`), line ends (`à` `$`), `dd` `yy` `p`, `o`,
   `.`, and `<leader>/` to grep.
3. **Week 2**: the verb + noun grammar: `ciw`, `di(`, `yaf`, `dap`, plus `f`
   `t` and flash (`s`). Use counts.
4. **Week 3**: code navigation (`gd`, `gr`, `K`, `<C-o>`), `<leader>ca`,
   `<leader>cr`, diagnostics (`)d`), git hunks (`)h`, `<leader>gg`).
5. **Then**: registers, macros, `cgn`, `:g`, the quickfix list.

Rule of thumb: when you press the same key many times (`jjjjjj`, `xxxx`),
there is a better motion. Look it up with `<leader>sk` or `:help`.
