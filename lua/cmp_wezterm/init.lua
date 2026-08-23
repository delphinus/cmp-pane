-- 旧名の互換シム。cmp-wezterm から cmp-pane へのリネーム前の設定
-- (`require "cmp_wezterm"` / `{ name = "wezterm" }`) をそのまま動かす。
--
-- ソース名 "wezterm" は after/plugin/cmp_pane.lua が登録している。
-- 新しい名前は "pane" / `require "cmp_pane"`。次のメジャーでこのシムは外す。
return require "cmp_pane"
