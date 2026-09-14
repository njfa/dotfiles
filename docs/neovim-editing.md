# Neovim Editing

The lockfile pins the modern `main` Treesitter APIs. Restart Neovim after applying
configuration changes. No plugin revisions are changed by these edits.
`<leader>` is Space.

## Syntax Keys

| Keys | Action | Modes |
| --- | --- | --- |
| `af` / `if` | Around / inside function | Visual, operator-pending |
| `ac` / `ic` | Around / inside class | Visual, operator-pending |
| `aP` / `iP` | Around / inside parameter or argument | Visual, operator-pending |
| `]r` / `[r` | Next / previous function start | Normal, visual, operator-pending |
| `]R` / `[R` | Next / previous function end | Normal, visual, operator-pending |
| `<leader>>` / `<leader><` | Swap parameter with next / previous | Normal |

`r` means routine. Examples: `vaf`, `dif`, `ciP`, `2]r`. Selections look ahead when
necessary, and movements add jumplist entries. Available objects and their exact
boundaries depend on the language's parser and textobject queries. Swaps use the
inner capture, leaving separators in place. No automatic import or reference updates
are performed by swaps.

The existing targets.vim `aa`/`ia`, paragraph `ap`/`ip`, filetype `[m`/`]m`, file
jumps `[f`/`]f`, and search-repeat `;`/`,` remain unchanged.

## Formatting

`m=` still formats the current buffer in normal mode or selection in visual mode.
Conform owns this action and automatic formatting; none-ls only registers diagnostics.
Mason continues installing the existing CLI tools, including formatters. Check
`:ConformInfo` for availability and `:Mason` for installation status.

| Filetypes | Formatter |
| --- | --- |
| Lua | StyLua, four spaces |
| `sh`, `bash` | shfmt with `-i 4`; includes ordinary `.sh` files |
| JavaScript, JSX, TypeScript, TSX, JSON, JSONC, YAML | Prettier |
| Python | Ruff format; otherwise Black, preceded by isort if available |
| Java | google-java-format |
| Go | Prefer LSP formatting (gopls) |
| Rust | rustfmt |
| Markdown | markdownlint |
| Terraform, Terraform variables, `*.tftest.hcl` | `terraform fmt` |

Without Ruff or Black, Python falls back to a formatting-capable LSP rather than
running isort alone. Other filetypes also use LSP fallback when no configured CLI
formatter is available. This is availability fallback, not a retry after a formatter
fails. Ruff formatting does not implicitly organize imports; use its code actions.

Save formatting remains Terraform-only, with a five-second timeout and no LSP
fallback. Conform replaces vim-terraform's automatic hook; the plugin's explicit
`:Terraform` / `:TerraformFmt` commands remain available. Other HCL files are not
automatically Terraform-formatted. VSCode mode does not enable this save hook.

## Project Navigation

Project actions use the nearest `.git` above the current normal file or directory
buffer. Both `.git` directories and worktree/submodule `.git` files are recognized.
An unnamed or special buffer searches from Neovim's effective cwd. With no Git marker,
the fallback is the effective cwd, including `:lcd` / `:tcd`, returned as an absolute
path. This does not change Neovim's working directory or language-specific LSP roots.

| Keys | Scope |
| --- | --- |
| `<leader>f` / `<leader>g` | Project files / grep, respecting ignore rules |
| `<leader>F` / `<leader>G` | Project files / grep, including ignored files |
| `<leader><leader>f` / `<leader><leader>gg` | Git files / Git grep at project root |
| `<leader><leader>gs` | Git status at project root |
| `<leader>E` | Yazi at project root |
| `<leader>e` | Yazi at the current file, unchanged |
| `<leader><leader>e` | Snacks explorer at project root |
| `<leader>na` | Run project tests through Neotest |

Hidden files remain searchable; normal file/grep searches respect `.gitignore` and
other finder ignore rules. All-files routes still exclude Git internals. Visual
file/grep searches also respect ignores. Explicit scopes, such as configuration-file
searches or a directory/files selected in Yazi, take precedence over the project root.
Recent-file history stays global. File and grep searches require ripgrep (already
managed by the tool configuration), avoiding a non-ignore-aware `find` fallback.

## Verification

Run from the repository root. No deployment or plugin installation is performed.

```sh
bash tests/nvim-editing.sh
nvim --headless -u NONE -i NONE -l tests/nvim-textobjects.lua
NVIM_TEST_PLUGINS=1 nvim --headless -u NONE -i NONE -l tests/nvim-formatting.lua
NVIM_TEST_PLUGINS=1 nvim --headless -u NONE -i NONE -l tests/nvim-project-root.lua
```

The shell wrapper runs dependency-free configuration tests on Neovim 0.11+ and is
included in `bash tests/run.sh`. Textobject integration needs the installed locked
plugins and Python parser. Optional real-plugin checks need Conform, Snacks, Mason,
mason-null-ls, none-ls, Plenary, installed markdownlint, shfmt, Prettier, Ruff, and
ripgrep; Terraform output is checked only when its CLI is executable.
