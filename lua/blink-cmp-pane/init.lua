local config = require "cmp_pane.config"
local pane = require "cmp_pane.pane"

---@class BlinkCmpPane
local M = {}

---@param opts? CmpPaneOptions
---@return BlinkCmpPane
function M.new(opts)
  config.set_from_opts(opts or {})
  return setmetatable({}, { __index = M })
end

---@return boolean
function M:enabled()
  return pane.is_available()
end

---@return string[]
function M:get_trigger_characters()
  return config.trigger_characters
end

---@param ctx blink.cmp.Context
---@param callback fun(response?: blink.cmp.CompletionResponse): nil
---@return fun(): nil cancel
function M:get_completions(ctx, callback)
  local word = ctx.line:sub(ctx.bounds.start_col, ctx.cursor[2])
  return pane.start(word, function(words)
    if not words then
      return callback()
    end
    ---@type blink.cmp.CompletionItem[]
    local items = vim.iter(words):fold(
      {},
      ---@param a blink.cmp.CompletionItem[]
      ---@param word string
      ---@param p CmpPanePane
      function(a, word, p)
        table.insert(a, {
          label = word,
          insertText = word,
          labelDetails = { detail = ("%s:%s:%s"):format(p.win, p.tab, p.id) },
        })
        return a
      end
    )
    callback {
      is_incomplete_forward = false,
      is_incomplete_backward = false,
      items = items,
    }
  end)
end

return M
