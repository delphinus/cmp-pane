local config = require "cmp_wezterm.config"

---@param msg string
local function log(msg)
  local ok, debug = pcall(require, "cmp.utils.debug")
  if ok then
    debug.log(msg)
  end
end

---@class CmpWeztermWezterm
---@field callback fun(result?: table<string, CmpWeztermPane>): nil
---@field word string
---@field cancelled boolean
---@field _handles vim.SystemObj[]
local Wezterm = {}

---@param word string
---@param callback fun(result?: table<string, CmpWeztermPane>): nil
---@return CmpWeztermWezterm
Wezterm.new = function(word, callback)
  return setmetatable({
    word = word:lower(),
    callback = callback,
    cancelled = false,
    _handles = {},
  }, { __index = Wezterm })
end

---@return nil
function Wezterm:cancel()
  self.cancelled = true
  ---@param handle vim.SystemObj
  vim.iter(self._handles):each(function(handle)
    pcall(function()
      handle:kill(15)
    end)
  end)
  self._handles = {}
end

---@class CmpWeztermPane
---@field id string
---@field tab string
---@field win string

---@class CmpWeztermPaneList
---@field panes CmpWeztermPane
---@field current { tab?: string, win?: string }

---@return nil
function Wezterm:gather()
  if self.cancelled then
    return self.callback()
  end
  local current_pane = vim.env.WEZTERM_PANE
  if not current_pane then
    return self.callback()
  end
  self:system({ "cli", "list" }, function(result)
    if self.cancelled then
      return
    end
    ---@type CmpWeztermPaneList
    local pane_list = vim.iter(vim.gsplit(result, "\n", { plain = true })):fold(
      { panes = {}, current = {} },
      ---@param a CmpWeztermPaneList
      ---@param b string
      function(a, b)
        local win, tab, id = b:match "^%s*(%d+)%s+(%d+)%s+(%d+)"
        if win and tab and id then
          if id == current_pane then
            a.current.tab = tab
            a.current.win = win
          else
            table.insert(a.panes, { id = id, win = win, tab = tab })
          end
        end
        return a
      end
    )
    local panes = vim
      .iter(pane_list.panes)
      ---@param pane CmpWeztermPane
      :filter(function(pane)
        return (config.all_windows or pane.win == pane_list.current.win)
          and (config.all_tabs or pane.tab == pane_list.current.tab)
      end)
      :totable()
    self:fetch_panes(panes)
  end)
end

---@private
---@param panes CmpWeztermPane[]
---@return nil
function Wezterm:fetch_panes(panes)
  if self.cancelled then
    return self.callback()
  end
  if #panes == 0 then
    return self.callback()
  end
  local count = 0
  ---@type table<string, CmpWeztermPane>
  local word_map = {}
  ---@param pane CmpWeztermPane
  vim.iter(panes):each(function(pane)
    self:system({ "cli", "get-text", "--pane-id", pane.id }, function(content)
      if self.cancelled then
        return
      end
      self:parse_pane(pane, word_map, content)
      count = count + 1
      if count == #panes then
        self.callback(word_map)
      end
    end)
  end)
end

---@private
---@param pane CmpWeztermPane
---@param word_map table<string, CmpWeztermPane>
---@param content string
---@return nil
function Wezterm:parse_pane(pane, word_map, content)
  ---@param word string
  vim.iter(content:gmatch "[%w%d_:/.%-~]+"):each(function(word)
    if not word:lower():match(self.word) then
      return
    end
    local cleaned = word:gsub("[:.]+$", "")
    if #cleaned == 0 then
      return
    end
    word_map[cleaned] = pane
    ---@param w string
    vim.iter(word:gmatch "[%w%d]+"):each(function(w)
      word_map[w] = pane
    end)
  end)
end

---@private
---@param cmd string[]
---@param cb fun(result: string): nil
function Wezterm:system(cmd, cb)
  table.insert(cmd, 1, config.executable)
  local handle
  local ok, err = pcall(function()
    handle = vim.system(cmd, { text = true }, function(obj)
      if self.cancelled then
        return
      end
      if obj.code == 0 then
        cb(obj.stdout)
      else
        log(("[cmp_wezterm] code: %d, stderr: %s"):format(obj.code, obj.stderr))
        self.callback()
      end
    end)
  end)
  if ok and handle then
    table.insert(self._handles, handle)
  end
  if not ok then
    log(("[cmp_wezterm] failed to spawn: %s"):format(err))
    self.callback()
  end
end

return {
  is_available = vim.env.TERM_PROGRAM == "WezTerm",

  ---@param word string
  ---@param callback fun(words?: table<string, CmpWeztermPane>): nil
  ---@return fun(): nil cancel
  start = function(word, callback)
    local w = Wezterm.new(word, callback)
    w:gather()
    return function()
      w:cancel()
    end
  end,
}
