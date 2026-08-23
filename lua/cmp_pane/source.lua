local config = require "cmp_pane.config"
local pane = require "cmp_pane.pane"

---@class CmpPane
local source = {}

---@return CmpPane
source.new = function()
  config.set()
  return setmetatable({}, { __index = source })
end

---@return string
source.get_debug_name = function()
  return "pane"
end

---@return boolean
source.is_available = function()
  return pane.is_available()
end

---@return string
function source:get_keyword_pattern()
  return config.keyword_pattern
end

---@return string[]
function source:get_trigger_characters()
  return config.trigger_characters
end

---@param request { context: cmp.Context, offset: integer }
---@param callback fun(items?: vim.CompletedItem[]): nil
---@return nil
function source:complete(request, callback)
  local word = request.context.cursor_before_line:sub(request.offset)
  pane.start(word, function(words)
    callback(words and vim
      .iter(words)
      ---@param w string
      ---@param p CmpPanePane
      :map(function(w, p)
        return { word = w, label = w, labelDetails = { detail = ("%s:%s:%s"):format(p.win, p.tab, p.id) } }
      end)
      :totable())
  end)
end

return source
