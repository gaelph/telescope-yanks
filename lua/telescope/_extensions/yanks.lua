local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
	error("This plugins requires nvim-telescope/telescope.nvim")
end

local u = require("telescope._extensions.yanks.utils") --- @type Utils
local Yanks = require("telescope._extensions.yanks.setup") --- @type YanksExtension

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")

--- Fetches yanks from file, and sorts them by last time they were used
--- so that the most recently used entries show up first
--- @return HistoryItem[]
local function yank_finder()
	local items = Yanks.db:load()

	table.sort(items, function(one, other)
		local otu = other.timeused
		local stu = one.timeused

		if type(otu) == "string" then
			otu = tonumber(otu, 10)
		end
		if type(stu) == "string" then
			stu = tonumber(stu, 10)
		end

		return stu > otu
	end)

	return items
end

-- default displayer
local displayer = entry_display.create({
	separator = " ",
	items = {
		{ width = conf.layout_config.horizontal.width * vim.o.columns },
		{ remaining = true },
	},
})

--- Presents yank in the search results list
--- replaces tabs with double spaces to show more content
--- @param entry Entry
--- @return function
local function make_display(entry)
	return displayer({ entry.name:gsub("%\t", "  ") })
end

--- Sets up the preview buffer for an entry
--- @param entry Entry
--- @param bufnr number
local function preview_entry(entry, bufnr)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, entry.value)
	vim.api.nvim_buf_set_option(bufnr, "ft", entry.filetype)
end

--- @class Entry
--- @field display fun(entry: Entry): function
--- @field name string
--- @field value string[]
--- @field ordinal string
--- @field regtype '"v"'|'"V"'
--- @field filetype string
--- @field preview_command fun(entry: Entry, bufnr: number)
--- @field id string

--- Makes entries out off finder results
--- @param yank HistoryItem
--- @return Entry
local function yank_entry_maker(yank)
	local value = u.read_lines(yank.content)
	local name = u.first(value)

	return {
		display = make_display,
		name = name,
		value = value,
		ordinal = name,
		regtype = yank.regtype,
		filetype = yank.filetype,
		preview_command = preview_entry,
		id = yank.id,
	}
end

--- Yank Telescope picker
local function yanks(opts)
	local buf = vim.api.nvim_get_current_buf()

	pickers
		.new(opts, {
			prompt_title = "Search Yanks",
			results_title = "Yanks",
			preview_title = "Preview",

			finder = finders.new_dynamic({
				fn = yank_finder,
				entry_maker = yank_entry_maker,
			}),

			sorter = conf.generic_sorter(opts),
			sorting_strategy = "descending",

			previewer = previewers.display_content.new(opts),

			attach_mappings = function()
				actions.select_default:replace(function(prompt_bufnr)
					--- @type Entry
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					-- Infer how to paste from how it was yanked
					-- "v" -> "c" : character-wise
					-- "V" -> "l" : line-wise
					local type = "c" --- @type '"c"'|'"l"'
					if selection.regtype == "V" then
						type = "l"
					end

					-- ensure we are on the same buffer
					-- than when we opened Telescope yank
					vim.api.nvim_set_current_buf(buf)
					-- paste
					vim.api.nvim_put(
						selection.value,
						type,
						true, --[[ after the cursor ]]
						true --[[end with cusor after the text]]
					)

					Yanks.db:update_timeused(selection.id)
				end)

				return true
			end,
		})
		:find()
end

return telescope.register_extension({
	exports = { yanks = yanks, setup = Yanks.setup },
})
