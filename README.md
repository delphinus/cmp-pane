# cmp-wezterm

[WezTerm](https://wezfurlong.org/wezterm/index.html) source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) and [blink.cmp](https://github.com/Saghen/blink.cmp).

## Features

A completion source that gathers candidates from contents of any other WezTerm pane.

- Gather completion candidates from other WezTerm panes via `wezterm cli`
- Filter by current tab / current window (`all_tabs`, `all_windows` options)
- Cancellation support — in-flight `wezterm cli` subprocesses are SIGTERM'd when the completion list is destroyed (used by blink.cmp; nvim-cmp users get the same protection if they call the cancel fn)
- Pane location (`win:tab:id`) shown in `labelDetails`
- Works with both [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) and [blink.cmp](https://github.com/Saghen/blink.cmp)

## Requirements

* Neovim v0.10.0
* nvim-cmp or blink.cmp
* WezTerm

## Installation

### With nvim-cmp

```lua
{ "delphinus/cmp-wezterm" },
```

```lua
require("cmp").setup {
  sources = {
    { name = "wezterm" },
  },
}
```

### With blink.cmp

```lua
{
  "saghen/blink.cmp",
  dependencies = { "delphinus/cmp-wezterm" },
  opts = {
    sources = {
      default = { "wezterm" },
      providers = {
        wezterm = { name = "wezterm", module = "blink-cmp-wezterm" },
      },
    },
  },
}
```

## More info

See detail in [doc](doc/cmp-wezterm.txt).

## TODO

* [x] doc
* [x] Capture only the current tab / window.
* [ ] Capture history
* [ ] Capture workspaces
* [ ] Capture clients
