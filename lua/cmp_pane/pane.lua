local backend = require "cmp_pane.backend"
local config = require "cmp_pane.config"

---@param msg string
local function log(msg)
  local ok, debug = pcall(require, "cmp.utils.debug")
  if ok then
    debug.log(msg)
  end
end

---@class CmpPaneGatherer
---@field backend CmpPaneBackend
---@field current string? 自分のペイン id
---@field callback fun(result?: table<string, CmpPanePane>): nil
---@field word string
---@field cancelled boolean
---@field _handles vim.SystemObj[]
local Pane = {}

---@param word string
---@param callback fun(result?: table<string, CmpPanePane>): nil
---@return CmpPaneGatherer
Pane.new = function(word, callback)
  local b = backend.detect()
  return setmetatable({
    backend = b,
    -- 環境変数はここ (メインコンテキスト) で拾う。vim.system の on_exit は
    -- fast event context で、vim.env を触ると E5560 になる。
    current = b and b.current() or nil,
    word = word:lower(),
    callback = callback,
    cancelled = false,
    _handles = {},
  }, { __index = Pane })
end

---@return nil
function Pane:cancel()
  self.cancelled = true
  ---@param handle vim.SystemObj
  vim.iter(self._handles):each(function(handle)
    pcall(function()
      handle:kill(15)
    end)
  end)
  self._handles = {}
end

---@private
---@return string
function Pane:executable()
  return config.executable or self.backend.executable
end

---@return nil
function Pane:gather()
  if self.cancelled or not self.backend then
    return self.callback()
  end
  self:system(self.backend.list_cmd(self:executable()), function(result)
    if self.cancelled then
      return
    end
    local pane_list = self.backend.parse(result, self.current)
    if not pane_list then
      return self.callback()
    end
    local panes = vim
      .iter(pane_list.panes)
      ---@param pane CmpPanePane
      :filter(function(pane)
        return (config.all_windows or pane.win == pane_list.current.win)
          and (config.all_tabs or pane.tab == pane_list.current.tab)
      end)
      :totable()
    self:fetch_panes(panes)
  end)
end

---@private
---@param panes CmpPanePane[]
---@return nil
function Pane:fetch_panes(panes)
  if self.cancelled then
    return self.callback()
  end
  if #panes == 0 then
    return self.callback()
  end
  local count = 0
  ---@type table<string, CmpPanePane>
  local word_map = {}
  ---@param pane CmpPanePane
  vim.iter(panes):each(function(pane)
    self:system(self.backend.text_cmd(self:executable(), pane.id), function(content)
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
---@param pane CmpPanePane
---@param word_map table<string, CmpPanePane>
---@param content string
---@return nil
function Pane:parse_pane(pane, word_map, content)
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
function Pane:system(cmd, cb)
  local handle
  local ok, err = pcall(function()
    handle = vim.system(cmd, { text = true }, function(obj)
      if self.cancelled then
        return
      end
      if obj.code == 0 then
        cb(obj.stdout)
      else
        log(("[cmp_pane] code: %d, stderr: %s"):format(obj.code, obj.stderr))
        self.callback()
      end
    end)
  end)
  if ok and handle then
    table.insert(self._handles, handle)
  end
  if not ok then
    log(("[cmp_pane] failed to spawn: %s"):format(err))
    self.callback()
  end
end

return {
  ---@return boolean
  is_available = function()
    return backend.detect() ~= nil
  end,

  ---@param word string
  ---@param callback fun(words?: table<string, CmpPanePane>): nil
  ---@return fun(): nil cancel
  start = function(word, callback)
    local p = Pane.new(word, callback)
    p:gather()
    return function()
      p:cancel()
    end
  end,
}
