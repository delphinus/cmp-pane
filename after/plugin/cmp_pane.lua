local ok, cmp = pcall(require, "cmp")
if ok then
  local source = require "cmp_pane"
  cmp.register_source("pane", source)
  -- 旧名。cmp-wezterm 時代の設定 ({ name = "wezterm" }) をそのまま動かす。
  cmp.register_source("wezterm", source)
end
