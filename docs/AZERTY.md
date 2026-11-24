# AZERTY layer

LazyVim's keymaps assume a US QWERTY keyboard. On a French AZERTY keyboard,
several of its most used keys need AltGr or Shift. `lua/config/azerty.lua`
adds aliases on direct keys. The stock keys keep working.

Disable the layer with `vim.g.azerty = false` in `lua/config/options.lua`.

## Aliases

| Stock key | On AZERTY       | Used for                                               | Alias        |
| --------- | --------------- | ------------------------------------------------------ | ------------ |
| `[` `]`   | AltGr+5, AltGr+° | every previous/next motion (see below)                | `(` `)`      |
| `%`       | Shift+ù         | jump to the matching bracket                           | `ù`          |
| `0`       | Shift+à         | start of line                                          | `à`          |
| `^`       | dead key        | first non-blank character                              | `_` (native) |
| `\`       | AltGr+8         | `<localleader>`, filetype-specific mappings            | `é`          |
| `<C-/>`   | Ctrl+Shift+:    | floating terminal (toggle)                             | `<C-ù>`      |

`(` and `)` replace Vim's sentence motions, which are of little use in code.
Counts are unaffected by `à`: digits already need Shift on AZERTY, so `10j`
is still typed with Shift held.

## Previous / next motions

With the aliases, every `[x` / `]x` motion is typed `(x` / `)x`:

| Keys        | Moves to                         |
| ----------- | -------------------------------- |
| `(d` `)d`   | previous / next diagnostic       |
| `(e` `)e`   | previous / next error            |
| `(w` `)w`   | previous / next warning          |
| `(h` `)h`   | previous / next git hunk         |
| `(f` `)f`   | previous / next function start   |
| `(c` `)c`   | previous / next class start      |
| `(a` `)a`   | previous / next parameter        |
| `(b` `)b`   | previous / next buffer           |
| `(q` `)q`   | previous / next quickfix entry   |
| `(t` `)t`   | previous / next TODO comment     |

Press `(` or `)` and wait: which-key lists everything available.

## Keys left as they are

- `{` `}` (previous / next paragraph): rarely needed in code; `(f` `)f` or
  flash (`s`) usually get there faster.
- `` ` `` (exact mark position): `'` jumps to the mark's line and is a direct key.
- `~` (toggle case), `#` (search word backwards), `|` (column): rare enough.
- `<leader>|` (split right): use `<leader>wv` instead.

Free direct keys left for later: `è`, `ç`, `²`.
