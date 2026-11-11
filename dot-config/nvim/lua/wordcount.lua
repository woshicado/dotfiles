--[[ g<C-g>, but as a float at the cursor. Works on the selection in visual mode. ]]

local M = {}

local ns = vim.api.nvim_create_namespace("wordcount")
local win = nil

--- 12345 -> "12,345"
local function sep(n)
	return (tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

---@return string title, { [1]: string, [2]: integer, [3]: integer? }[] rows
local function collect()
	local wc = vim.fn.wordcount()
	local mode = vim.fn.mode()
	local total_lines = vim.api.nvim_buf_line_count(0)

	if mode == "v" or mode == "V" or mode == "\22" then
		local rows = {
			{ "Lines", math.abs(vim.fn.line("v") - vim.fn.line(".")) + 1, total_lines },
			{ "Words", wc.visual_words, wc.words },
			{ "Chars", wc.visual_chars, wc.chars },
			{ "Bytes", wc.visual_bytes, wc.bytes },
		}
		if mode == "\22" then
			table.insert(rows, 1, { "Cols", math.abs(vim.fn.virtcol("v") - vim.fn.virtcol(".")) + 1 })
		end
		return "Selection", rows
	end

	local line_len = vim.fn.charcol("$") - 1
	return "Cursor",
		{
			{ "Line", vim.fn.line("."), total_lines },
			{ "Col", line_len == 0 and 0 or vim.fn.charcol("."), line_len },
			{ "Word", wc.cursor_words, wc.words },
			{ "Char", wc.cursor_chars, wc.chars },
			{ "Byte", wc.cursor_bytes, wc.bytes },
		}
end

local function close()
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
	win = nil
end

function M.show()
	close()
	local title, rows = collect()

	local lw, cw, tw = 0, 0, 0
	for _, r in ipairs(rows) do
		r[4], r[5] = sep(r[2]), r[3] and sep(r[3]) or ""
		lw, cw, tw = math.max(lw, #r[1]), math.max(cw, #r[4]), math.max(tw, #r[5])
	end

	local lines, hls = {}, {}
	for i, r in ipairs(rows) do
		local label = (" %-" .. lw .. "s  "):format(r[1])
		local cur = ("%" .. cw .. "s"):format(r[4])
		local total, p = (" %" .. tw + 2 .. "s"):format(""), "       "
		if r[3] then
			total = (" / %" .. tw .. "s"):format(r[5])
			p = ("  %3d%% "):format(r[3] > 0 and math.floor(r[2] / r[3] * 100 + 0.5) or 0)
		end
		lines[i] = label .. cur .. total .. p

		local c = 0
		for _, seg in ipairs({ { label, "Label" }, { cur, "Number" }, { total, "Comment" }, { p, "Special" } }) do
			table.insert(hls, { i - 1, c, c + #seg[1], seg[2] })
			c = c + #seg[1]
		end
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	for _, h in ipairs(hls) do
		vim.api.nvim_buf_set_extmark(buf, ns, h[1], h[2], { end_col = h[3], hl_group = h[4] })
	end
	vim.bo[buf].bufhidden = "wipe"

	win = vim.api.nvim_open_win(buf, false, {
		relative = "cursor",
		row = 1,
		col = 0,
		width = vim.fn.strdisplaywidth(lines[1]),
		height = #lines,
		style = "minimal",
		border = "rounded",
		title = " " .. title .. " ",
		title_pos = "center",
		focusable = false,
		noautocmd = true,
	})

	vim.api.nvim_create_autocmd({ "CursorMoved", "ModeChanged", "BufLeave" }, {
		once = true,
		callback = close,
	})
end

return M
