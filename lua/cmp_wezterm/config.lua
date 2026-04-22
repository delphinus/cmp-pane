---@class CmpWeztermOptions
---@field all_tabs? boolean default: true
---@field all_windows? boolean default: true
---@field executable? string default: "wezterm"
---@field keyword_pattern? string default: [[\w\+]]
---@field trigger_characters? string[] default: { "." }

---@class CmpWeztermRawConfig
---@field all_tabs boolean
---@field all_windows boolean
---@field executable string
---@field keyword_pattern string
---@field trigger_characters string[]
local default_config = {
  all_tabs = true,
  all_windows = true,
  executable = "wezterm",
  keyword_pattern = [[\w\+]],
  trigger_characters = { "." },
}

---@class CmpWeztermConfig: CmpWeztermRawConfig
local Config = {}

---@return nil
Config.set = function()
  local cfg = require("cmp.config").get_source_config "wezterm"
  local extended = vim.tbl_extend("force", default_config, (cfg or {}).option or {})
  vim.iter(pairs(extended)):each(function(k, v)
    Config[k] = v
  end)
end

---@param opts? CmpWeztermOptions
---@return nil
Config.set_from_opts = function(opts)
  local extended = vim.tbl_extend("force", default_config, opts or {})
  vim.iter(pairs(extended)):each(function(k, v)
    Config[k] = v
  end)
end

return Config
