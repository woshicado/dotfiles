require("complicated_mappings")

-- <C-hjkl>: nvim windows, falling through to zellij/tmux panes at the edge
require("muxnav").setup()

local map = vim.keymap.set

map("i", "<C-b>", "<ESC>^i", { desc = "move beginning of line" })
map("i", "<C-e>", "<End>", { desc = "move end of line" })
map("i", "<C-h>", "<Left>", { desc = "move left" })
map("i", "<C-l>", "<Right>", { desc = "move right" })
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })
map("x", "<C-c>", '"+ygv', { desc = "general copy selection" })

map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })

map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })
map("n", "<tab>", "<cmd>bnext<CR>", { desc = "buffer goto next" })
map("n", "<S-tab>", "<cmd>bprevious<CR>", { desc = "buffer goto prev" })

map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-- map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })

-- stylua: ignore
map({ "n", "t" }, "<M-i>", function() require("floatterm").toggle() end,
	{ desc = "terminal toggle floating term" })
map({ "n", "x" }, "g<C-g>", function() require("wordcount").show() end,
	{ desc = "buffer/selection word count float" })

map({ "i", "v", "n" }, "<Up>", "<Nop>")
map({ "i", "v", "n" }, "<Down>", "<Nop>")
map({ "i", "v", "n" }, "<Left>", "<Nop>")
map({ "i", "v", "n" }, "<Right>", "<Nop>")

map("n", "<leader>v", "^vg_", { desc = "Select non-whitespace line", noremap = true })

-- Save keybind
map("n", "<leader>w", "<cmd>w<cr>", { noremap = true, desc = "Save File" })

-- Exit keybinds
map("n", "<leader>qq", "<cmd>:q!<CR>", { desc = "Close window without saving", noremap = true })
map({ "n", "i", "v" }, "<M-q>", "<cmd> :qa! <CR>", { desc = "Close session without saving", noremap = true })

-- Misc Meta
map({ "n", "v" }, "<leader><C-w>", "<cmd> :set wrap!<CR>", { desc = "Toggle word wrap", noremap = true }) -- Toogle word wrap
-- stylua: ignore
map({ "n", "v" }, "<leader>lr", "<cmd> :set invrelativenumber<CR>",
	{ desc = "Toggle absolute/relative surrounding line numbers.", noremap = true })

-- Buffer navigation
map({ "n", "v" }, "<leader><Left>", "<cmd>bp!<CR>", { desc = "Switch to previous buffer", noremap = true })
map({ "n", "v" }, "<leader><Right>", "<cmd>bn!<CR>", { desc = "Switch to next buffer", noremap = true })
map({ "n", "v" }, "<C-S-o>", "<C-i>", { desc = "Forward", noremap = true })

-- stylua: ignore
-- map("n", "<leader>sh", function() require("lsp_signature").toggle_float_win() end,
-- 	{ desc = "Toggle signature help", noremap = true })

-- map("n", "K", function()
-- 	if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/hover" }) > 0 then
-- 		vim.lsp.buf.hover()
-- 		return
-- 	end
-- 	local kp = vim.bo.keywordprg
-- 	if kp == "" or kp == ":Man" then
-- 		vim.cmd("normal! K") -- builtin K, i.e. 'keywordprg'
-- 	else
-- 		vim.notify("No hover-capable LSP attached (yet)", vim.log.levels.WARN)
-- 	end
-- end, { desc = "Hover docs (falls back to keywordprg)", noremap = true })
--
map({ "n", "x" }, "<leader>sw", function()
	local ve = vim.o.virtualedit -- returns a string, e.g. "", "all", "block,onemore"
	if ve:find("all") then
		vim.opt.virtualedit = ""
		vim.notify("virtualedit disabled")
	else
		vim.opt.virtualedit = "all"
		vim.notify("virtualedit = all")
	end
end, { desc = "Toggle virtualedit=all" })

-- German umlauts
map({ "i", "t" }, "<M-o>", "ö", { desc = "ö" })
map({ "i", "t" }, "<M-u>", "ü", { desc = "ü" })
map({ "i", "t" }, "<M-a>", "ä", { desc = "ä" })
map({ "i", "t" }, "<M-S-o>", "Ö", { desc = "Ö" })
map({ "i", "t" }, "<M-S-u>", "Ü", { desc = "Ü" })
map({ "i", "t" }, "<M-S-a>", "Ä", { desc = "Ä" })

-- Terminal mappings
map("t", "<c-x>", "<C-\\><C-n>", { noremap = true, desc = "Defocus terminal" })

-- Center screen on navigation with ctrl-u/d
map("n", "<C-u>", "<C-u>zz", { desc = "Center screen on navigation" })
map("n", "<C-d>", "<C-d>zz", { desc = "Center screen on navigation" })
map("n", "<C-f>", "<C-f>zz", { desc = "Center screen on navigation" })
map("n", "<C-b>", "<C-b>zz", { desc = "Center screen on navigation" })
-- Center screen on navigation with n/N
map("n", "n", "nzzzv", { desc = "Center screen on navigation with n" })
map("n", "N", "Nzzzv", { desc = "Center screen on navigation with N" })
-- Top screen on [[ and ]] and [m and ]m
map("n", "[[", "[[zt", { noremap = true, desc = "Top screen on [[" })
map("n", "]]", "]]zt", { noremap = true, desc = "Top screen on ]]" })
map("n", "[m", "[mzt", { noremap = true, desc = "Top screen [m" })
map("n", "]m", "]mzt", { noremap = true, desc = "Top screen ]m" })
-- Cetner screen on navigation with { and }
map("n", "{", "{zz", { desc = "Center screen on {" })
map("n", "}", "}zz", { desc = "Center screen on }" })

---- Text manipulation
-- Swap lines
map("n", "<A-Up>", ":m .-2<cr>==", { desc = "Move line up", noremap = true })
map("n", "<A-k>", ":m .-2<cr>==", { desc = "Move line up", noremap = true })
map("n", "<A-Down>", ":m .+1<cr>==", { desc = "Move line down", noremap = true })
map("n", "<A-j>", ":m .+1<cr>==", { desc = "Move line down", noremap = true })

map("v", "<A-Up>", ":m '<-2<cr>gv=gv", { desc = "Move line up", noremap = true })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move line up", noremap = true })
map("v", "<A-Down>", ":m '>+1<cr>gv=gv", { desc = "Move line down", noremap = true })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move line down", noremap = true })

map("i", "<A-Up>", "<Esc>:m .-2<cr>==gi", { desc = "Move line up", noremap = true })
map("i", "<A-k>", "<Esc>:m .-2<cr>==gi", { desc = "Move line up", noremap = true })
map("i", "<A-Down>", "<Esc>:m .+1<cr>==gi", { desc = "Move line down", noremap = true })
map("i", "<A-j>", "<Esc>:m .+1<cr>==gi", { desc = "Move line down", noremap = true })

-- Toggle comment s
map("n", "<M-/>", "<leader>/==", { desc = "Toggle comment", remap = true })
map("v", "<M-/>", "<leader>/gv=gv", { desc = "Toggle comment", remap = true })
map("i", "<M-/>", "<C-o><leader>/", { desc = "Toggle comment", remap = true })

-- Code format
map("n", "<leader>cs", "<cmd>Shades<CR>", { desc = "Shadify", noremap = true })
map("n", "<leader>ch", "<cmd>Huefy<CR>", { desc = "Shadify", noremap = true })

-- Indentations
map("v", ">", ">gv", { desc = "Keep selection after indent", noremap = true })
map("v", "<", "<gv", { desc = "Keep selection after indent", noremap = true })

-- Paste/Delete/Substitute without yanking to clipboard
map("x", "p", [["_dP]])
map("x", "x", [["_x]])
map("x", "s", [["_s]])

-- Smart home/end keys; Cmd for home and end
-- stylua: ignore start
map( "n", "<Home>", [[col('.') == matchend(getline('.'), '^\\s*')+1 ? '0' : '^']],
	{ expr = true, noremap = true, desc = "Smart Home key" })
map( "n", "<End>", [[col('.') == match(getline('.'), '\s*$') ? '$' : 'g_']],
	{ expr = true, noremap = true, desc = "Smart End key" })
map( "v", "<End>", [[col('.') == match(getline('.'), '\s*$') ? '$h' : 'g_']],
	{ expr = true, noremap = true, desc = "Smart End key in visual mode" })
map("i", "<Home>", "<C-o><Home>", { noremap = true, desc = "Home key in insert mode" })
map("i", "<End>", "<C-o><End>", { noremap = true, desc = "End key in insert mode" })

-- quickfix keybinds
-- Preferably use the default [q, ]q mappings etc.
map("n", "<leader>qc", ":copen<CR>", { noremap = true, silent = true })
map("n", "<leader>ql", ":lopen<CR>", { noremap = true, silent = true })
map("n", "<leader>qp", ":colder<CR>", { noremap = true, silent = true })
map("n", "<leader>qn", ":cnewer<CR>", { noremap = true, silent = true })
-- map("n", "<leader>qq", ":cclose<CR>", { noremap = true, silent = true })
map("n", "<leader>q[", ":cprev<CR>", { noremap = true, silent = true })
map("n", "<leader>q]", ":cnext<CR>", { noremap = true, silent = true })
map("n", "<leader>qP", ":cpf<CR>", { noremap = true, silent = true })
map("n", "<leader>qN", ":cnf<CR>", { noremap = true, silent = true })
map("n", "<leader>q{", ":colder<CR>", { noremap = true, silent = true })
map("n", "<leader>q}", ":cnewer<CR>", { noremap = true, silent = true })
map("n", "[<S-q>", ":colder<CR>", { noremap = true, silent = true })
map("n", "]<S-q>", ":cnewer<CR>", { noremap = true, silent = true })

-- harper_ls is opt-in; too many false positives
map("n", "<leader>th", "<cmd>HarperToggle<CR>", { desc = "Toggle harper_ls grammar checks" })

-- Toggle light/dark for nvim, kitty and lsd together
map("n", "<leader>tt", function()
	require("theme").toggle()
end, { desc = "Toggle light/dark theme" })

-- Toggle transparency on <leader>to; useless atm
map("n", "<leader>to", function()
	local kanagawa = require("kanagawa")
	kanagawa.setup({ transparent = not kanagawa.config.transparent })
	vim.cmd.colorscheme("kanagawa")
end, { desc = "Toggle transparency" })

-- Obsidian keybinds
map("n", "<leader>oo", ":cd $O_VAULT_DIR<CR>", { desc = "Open Obsidian notes" })
map("n", "<leader>of", ":s/\\(# \\)[^_]*_/\\1/ | s/-/ /g<cr>", { desc = "Strip date from title" })
map("n", "<leader>ok", ":!mv '%:p' $O_VAULT_DIR/zettelkasten<cr>:bd<cr>", { desc = "Move file to zettelkasten" })
map("n", "<leader>or", ":!rm '%:p'<cr>:bd<cr>", { desc = "Remove file" })

-- Yank buffer path/name/dir to clipboard
local function yank_path(expr, desc, oil_fn)
  return function()
    local result
    if vim.bo.filetype == "oil" then
      result = oil_fn()
    else
      result = vim.fn.expand(expr)
    end
    if result and result ~= "" then
      vim.fn.setreg("+", result)
      vim.notify(desc .. ": " .. result)
    else
      vim.notify(desc .. ": nothing to yank", vim.log.levels.WARN)
    end
  end
end

local function oil_entry_path()
  local oil = require("oil")
  local entry = oil.get_cursor_entry()
  if entry then
    local dir = oil.get_current_dir()
    return dir and (dir .. entry.name) or entry.name
  end
  return oil.get_current_dir()
end

map("n", "<leader>yp", yank_path("%:p", "Yanked abs. path", function()
  return oil_entry_path()
end), { desc = "Yank abs path (buffer)" })

map("n", "<leader>yP", yank_path("%", "Yanked rel. path", function()
  local abs = oil_entry_path()
  if abs then
    local cwd = vim.fn.getcwd() .. "/"
    if abs:sub(1, #cwd) == cwd then
      return abs:sub(#cwd + 1)
    end
  end
  return abs
end), { desc = "Yank rel path (buffer)" })

map("n", "<leader>yd", yank_path("%:p:h", "Yanked abs. directory", function()
  return (require("oil").get_current_dir() or ""):gsub("/$", "")
end), { desc = "Yank abs path (directory)" })

map("n", "<leader>yD", yank_path("%:h", "Yanked rel. directory", function()
  local abs = (require("oil").get_current_dir() or ""):gsub("/$", "")
  local cwd = vim.fn.getcwd()
  if abs:sub(1, #cwd) == cwd then
    local rel = abs:sub(#cwd + 2)
    return rel ~= "" and rel or "."
  end
  return abs
end), { desc = "Yank rel path (directory)" })

map("n", "<leader>yn", yank_path("%:t", "Yanked file name", function()
  local entry = require("oil").get_cursor_entry()
  return entry and entry.name or nil
end), { desc = "Yank filename (buffer)" })

-- open definition in split view
local bufopts = { noremap = true, silent = true }
map("n", "<leader>gv", function() vim.cmd("vsplit") vim.lsp.buf.definition() end, bufopts)
map("n", "<leader>gh", function() vim.cmd("split") vim.lsp.buf.definition() end, bufopts)

map("n", "gp", "`[v`]", { desc = "Visual pasted" })
map("n", "gP", "`]v`[", { desc = "Visual pasted" })

-- Paste from number registers conveniently
for i = 0, 9 do
	vim.keymap.set("n", "<leader>" .. i, '"' .. i .. "p", { desc = "Paste from register " .. i })
	-- yank into number registers; not sure whether that helpful yet since nvim cycles through them automatically...
	vim.keymap.set("n", "<leader>y" .. i, '"' .. i .. "y", { desc = "Yank into register " .. i })
	vim.keymap.set("v", "<leader>y" .. i, '"' .. i .. "y", { desc = "Yank into register " .. i })
end
vim.keymap.set("n", "<leader>-", '"-p', { desc = "Paste from small delete register" })

-- Move lines
map("v", "<C-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
map("v", "<C-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })

map("n", "<CR>", function()
	if vim.bo.buftype ~= "" then -- quickfix, help, ...: keep the default
		return vim.api.nvim_feedkeys(vim.keycode("<CR>"), "n", false)
	end
	require("incsel").start()
end, { desc = "Select treesitter node under cursor" })
map("x", "<CR>", function() require("incsel").expand() end, { desc = "Expand selection to parent node" })
map("x", "<BS>", function() require("incsel").shrink() end, { desc = "Shrink selection to previous node" })
-- stylua: ignore end
