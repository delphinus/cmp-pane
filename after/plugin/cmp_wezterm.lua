local ok, cmp = pcall(require, "cmp")
if ok then
  cmp.register_source("wezterm", require "cmp_wezterm")
end
