---@class Options
---@field notes_dir string

---@class Notes
---@field toggle fun()
---@field search_notes fun()
---@field grep_notes fun(search_term?: string)
---@field is_open fun(): boolean
---@field setup fun(options?: Options)
local M = {}

---@type Options
local config = {
	notes_dir = vim.fn.stdpath("data") .. "/notes",
}

M.is_open = function()
	local buffer_name = os.date("%Y-%m-%d") .. ".md"

	-- Get a list of all buffers
	local buffers = vim.api.nvim_list_bufs()

	for _, buf in ipairs(buffers) do
		-- Check if the buffer is loaded to avoid errors with unloaded buffers
		if vim.api.nvim_buf_is_loaded(buf) then
			local full_path = vim.api.nvim_buf_get_name(buf)
			-- Extract the filename from the full path
			local name = full_path:match("^.+/(.+)$") or full_path
			-- Perform a case-insensitive search for buffer_name within the filename
			if name:lower():find(buffer_name:lower(), 1, true) then
				return true
			end
		end
	end

	return false
end

M.toggle = function()
	if M.is_open() then
		-- Check if the buffer has been modified, if not just close it, if so, save it
		if not vim.api.nvim_buf_get_option(0, "modified") then
			vim.cmd("bdelete")
		else
			vim.cmd("w")
			vim.cmd("bdelete")
		end
	else
		-- Open a new buffer in the notes_dir in a vertical split, the name is today's date
		vim.cmd("vnew " .. config.notes_dir .. "/" .. os.date("%Y-%m-%d") .. ".md")
	end
end

M.search_notes = function()
	require("telescope.builtin").find_files({
		cwd = config.notes_dir,
	})
end

M.grep_notes = function(search_term)
	if not search_term then
		require("telescope.builtin").live_grep({
			cwd = config.notes_dir,
		})
		return
	end

	require("telescope.builtin").grep_string({
		search = search_term,
		cwd = config.notes_dir,
	})
end

M.setup = function(opts)
	if not opts then
		opts = {}
	end

	if opts.notes_dir then
		config.notes_dir = opts.notes_dir
	end

	if not vim.loop.fs_stat(config.notes_dir) then
		vim.fn.system({ "mkdir", "-p", config.notes_dir })
	end
end

return M
