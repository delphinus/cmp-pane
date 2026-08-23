-- 端末ごとの差分。ペインの一覧の取り方と、ペインの表示内容の取り方だけを持つ。
-- 単語の切り出し・キャンセル・補完ソースの組み立ては pane.lua が共通で行う。

---@class CmpPanePane
---@field id string ペイン (kitty ではウィンドウ) の id
---@field tab string タブの id
---@field win string OS ウィンドウの id

---@class CmpPaneCurrent
---@field tab? string
---@field win? string

---@class CmpPanePaneList
---@field panes CmpPanePane[] 自分以外のペイン
---@field current CmpPaneCurrent 自分の居場所

---@class CmpPaneBackend
---@field name string
---@field executable string 既定の実行ファイル名 (config.executable で上書き可)
---@field is_available fun(): boolean
---@field current fun(): string? 自分のペイン id。環境変数を読むのでメインコンテキストから呼ぶこと
---@field list_cmd fun(exe: string): string[] ペイン一覧を取るコマンド
---@field parse fun(stdout: string, current: string?): CmpPanePaneList?
---@field text_cmd fun(exe: string, id: string): string[] ペインの表示内容を取るコマンド
---
--- parse() は vim.system の on_exit から呼ばれる。そこは fast event context で
--- vim.env (getenv) を触れないため、自分のペイン id は current() でメイン
--- コンテキストのうちに拾っておいて引数で渡す。

---@type CmpPaneBackend
local kitty = {
  name = "kitty",
  executable = "kitten",

  is_available = function()
    return vim.env.KITTY_WINDOW_ID ~= nil
  end,

  current = function()
    return vim.env.KITTY_WINDOW_ID
  end,

  list_cmd = function(exe)
    return { exe, "@", "ls" }
  end,

  parse = function(stdout, current)
    local ok, os_windows = pcall(vim.json.decode, stdout)
    if not ok or type(os_windows) ~= "table" then
      return nil
    end
    local me = current
    ---@type CmpPanePaneList
    local result = { panes = {}, current = {} }
    for _, os_window in ipairs(os_windows) do
      for _, tab in ipairs(os_window.tabs or {}) do
        for _, window in ipairs(tab.windows or {}) do
          local id = tostring(window.id)
          local entry = { id = id, tab = tostring(tab.id), win = tostring(os_window.id) }
          if id == me then
            result.current.tab = entry.tab
            result.current.win = entry.win
          else
            table.insert(result.panes, entry)
          end
        end
      end
    end
    return result
  end,

  text_cmd = function(exe, id)
    return { exe, "@", "get-text", "--match", "id:" .. id }
  end,
}

---@type CmpPaneBackend
local wezterm = {
  name = "wezterm",
  executable = "wezterm",

  is_available = function()
    return vim.env.WEZTERM_PANE ~= nil
  end,

  current = function()
    return vim.env.WEZTERM_PANE
  end,

  list_cmd = function(exe)
    return { exe, "cli", "list" }
  end,

  parse = function(stdout, current)
    local me = current
    -- `wezterm cli list` の表形式。先頭 3 列が WINID TABID PANEID。
    return vim.iter(vim.gsplit(stdout, "\n", { plain = true })):fold(
      { panes = {}, current = {} },
      ---@param a CmpPanePaneList
      ---@param line string
      function(a, line)
        local win, tab, id = line:match "^%s*(%d+)%s+(%d+)%s+(%d+)"
        if win and tab and id then
          if id == me then
            a.current.tab = tab
            a.current.win = win
          else
            table.insert(a.panes, { id = id, win = win, tab = tab })
          end
        end
        return a
      end
    )
  end,

  text_cmd = function(exe, id)
    return { exe, "cli", "get-text", "--pane-id", id }
  end,
}

local M = { kitty = kitty, wezterm = wezterm }

-- kitty を先に見る。WezTerm のシェルから kitty を起動すると WEZTERM_* が継承されて
-- 両方立って見えることがあるため。
M.all = { kitty, wezterm }

---@return CmpPaneBackend?
function M.detect()
  for _, backend in ipairs(M.all) do
    if backend.is_available() then
      return backend
    end
  end
  return nil
end

return M
