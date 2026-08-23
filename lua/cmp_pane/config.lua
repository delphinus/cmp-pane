---@class CmpPaneOptions
---@field all_tabs? boolean default: true
---@field all_windows? boolean default: true
---@field executable? string default: バックエンドごとの既定 (kitty なら "kitten"、WezTerm なら "wezterm")
---@field keyword_pattern? string default: [[\w\+]]
---@field trigger_characters? string[] default: { "." }

---@class CmpPaneRawConfig
---@field all_tabs boolean
---@field all_windows boolean
---@field executable string?
---@field keyword_pattern string
---@field trigger_characters string[]
local default_config = {
  all_tabs = true,
  all_windows = true,
  -- nil ならバックエンドの既定を使う。旧 cmp-wezterm では "wezterm" 固定だった。
  executable = nil,
  keyword_pattern = [[\w\+]],
  trigger_characters = { "." },
}

---@class CmpPaneConfig: CmpPaneRawConfig
local Config = {}

---@param extended table
local function apply(extended)
  vim.iter(pairs(extended)):each(function(k, v)
    Config[k] = v
  end)
  -- default_config で nil にしているキーは pairs に現れないので明示的に置く。
  if extended.executable == nil then
    Config.executable = nil
  end
end

-- nvim-cmp 側に書かれた option を読む。nvim-cmp が入っていない (blink だけ使って
-- いる等) 環境では既定値のままにする。
---@return nil
Config.set = function()
  local ok, cmp_config = pcall(require, "cmp.config")
  local cfg
  if ok then
    -- ソース名は "pane" が正。"wezterm" は旧名の互換。
    cfg = cmp_config.get_source_config "pane" or cmp_config.get_source_config "wezterm"
  end
  apply(vim.tbl_extend("force", default_config, (cfg or {}).option or {}))
end

---@param opts? CmpPaneOptions
---@return nil
Config.set_from_opts = function(opts)
  apply(vim.tbl_extend("force", default_config, opts or {}))
end

return Config
