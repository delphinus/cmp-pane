# cmp-pane

Terminal pane source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) and [blink.cmp](https://github.com/Saghen/blink.cmp). Supports [kitty](https://sw.kovidgoyal.net/kitty/) and [WezTerm](https://wezfurlong.org/wezterm/index.html).

> [!NOTE]
> This plugin used to be called **cmp-wezterm**. GitHub redirects the old repository URL, and the old module and source names still work as shims, so existing configs keep running. See [Migration](#migration).

## Features

Pulls the visible text of the terminal's other panes and offers the words it finds — file paths from `ls`, identifiers from a `git log`, URLs in `curl` output, etc. — as completions in your buffer.

- Gather completion candidates from other panes of kitty or WezTerm
- Terminal detected automatically from the environment
- Filter by current tab / current window (`all_tabs`, `all_windows` options)
- Cancellation support — in-flight subprocesses are SIGTERM'd when the completion list is destroyed (used by blink.cmp; nvim-cmp users get the same protection if they call the cancel fn)
- Pane location (`win:tab:id`) shown in `labelDetails`
- Works with both [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) and [blink.cmp](https://github.com/Saghen/blink.cmp)

## Requirements

* Neovim v0.10.0
* nvim-cmp or blink.cmp
* kitty or WezTerm

### kitty

Pane contents are read over kitty's remote control, so it has to be enabled:

```conf
allow_remote_control yes
listen_on unix:/tmp/kitty-{kitty_pid}
```

### Terminal detection

The terminal is detected from the environment, kitty first:

| Terminal | Detected by | Commands used |
| --- | --- | --- |
| kitty | `$KITTY_WINDOW_ID` | `kitten @ ls`, `kitten @ get-text` |
| WezTerm | `$WEZTERM_PANE` | `wezterm cli list`, `wezterm cli get-text` |

kitty is probed first because launching kitty from a WezTerm shell leaks `WEZTERM_*` into it, which would otherwise make both look available.

## Installation

### With nvim-cmp

```lua
{ "delphinus/cmp-pane" },
```

```lua
require("cmp").setup {
  sources = {
    { name = "pane" },
  },
}
```

### With blink.cmp

```lua
{
  "saghen/blink.cmp",
  dependencies = { "delphinus/cmp-pane" },
  opts = {
    sources = {
      default = { "pane" },
      providers = {
        pane = {
          name = "pane",
          module = "blink-cmp-pane",
          -- Listing the panes plus the per-pane text fetches can take tens of
          -- milliseconds. Mark the provider async so blink.cmp shows results
          -- from cheaper sources (buffer, snippets, etc.) immediately and
          -- merges pane candidates in as they arrive.
          async = true,
        },
      },
    },
  },
}
```

## Migration

Everything below keeps working; the shims will be removed in the next major version.

| old | new |
| --- | --- |
| `{ "delphinus/cmp-wezterm" }` | `{ "delphinus/cmp-pane" }` |
| `{ name = "wezterm" }` | `{ name = "pane" }` |
| `module = "blink-cmp-wezterm"` | `module = "blink-cmp-pane"` |
| `require "cmp_wezterm"` | `require "cmp_pane"` |
| `:h cmp-wezterm` | `:h cmp-pane` |

One behaviour change: the `executable` option no longer defaults to `"wezterm"`. Leave it unset to get the right default for whichever terminal is detected (`kitten` / `wezterm`), or set it to a full path.

## More info

See detail in [doc](doc/cmp-pane.txt).

## TODO

* [x] doc
* [x] Capture only the current tab / window.
* [x] Support kitty
* [ ] Capture history
* [ ] Capture workspaces
* [ ] Capture clients
