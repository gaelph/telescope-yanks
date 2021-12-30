--- @classmod DB
DATA_PATH = vim.fn.stdpath("data")

local md5 = require("telescope._extensions.yanks.md5")
local u = require("telescope._extensions.yanks.utils") --- @type Utils

local default_db_dir = DATA_PATH .. "/yanks"
os.execute("mkdir -p " .. default_db_dir)

--- @class HistoryItemParams
--- @field id string
--- @field content string
--- @field regtype '"v"'|'"V"'
--- @field path string
--- @field filetype string
--- @field timeused string

---
--- @class HistoryItem
--- @field id string
--- @field content string[]
--- @field regtype '"v"'|'"V"'
--- @field path string
--- @field filetype string
--- @field timeused string
local HistoryItem = {
	id = "",
	content = {},
	regtype = "V",
	path = "",
	filetype = "",
	timeused = "",
}

---
--- @param params HistoryItemParams
--- @return HistoryItem
function HistoryItem:new(params)
	setmetatable(params, self)
	self.__index = self

	return params
end

--- The DB class reads from, and writes to the db file
--- @class DB
--- @field file string|'"~.local/nvim/yanks"'     path to database file
--- @field maxsize number|"200"   maximum number of yanks stored
--
--- @field new function
--- @field add function
--- @field delete function
local DB = { file = default_db_dir .. "/yanks.json", maxsize = 200 } --- @type DB

--- @class DBOptions
--- @field db_dir string|'"~.local/nvim/yanks"'
--- @field maxsize number|"200"

--- Constructor
--- The `options` object has two optional porporties:
---  - db_dir: path to an existing directory to store the yanks
---            defaults to `~/.local/nvim/yanks`
---  - maxsize: maximum number of yanks to store
---             defaults do 200
--- @param options DBOptions
--- @return DB
function DB:new(options)
	local instance = {}
	setmetatable(instance, self)
	self.__index = self

	options = options or {}

	if options.db_dir then
		instance.file = options.db_dir .. "/yanks.json"
	else
		instance.file = DB.file
	end

	-- create the file if it doesn’t exists
	os.execute("touch " .. instance.file)

	instance.maxsize = options.maxsize or DB.maxsize

	return instance
end

function string.tohex(str)
	return (str:gsub(".", function(c)
		return string.format("%02X", string.byte(c))
	end))
end

--- Creates a new HistoryItem
--- @param content string[]
--- @param filepath string
--- @param regtype string
--- @param filetype string
--- @return HistoryItem
function DB:build_item(content, filepath, regtype, filetype)
	local id = string.tohex(md5.sum(content))
	local timeused = os.time(os.date("!*t"))

	return HistoryItem:new({
		id = id,
		content = content,
		regtype = regtype,
		filetype = filetype,
		path = filepath,
		timeused = timeused,
	})
end

--- Writes the DB file
--- @param rawItems HistoryItem[]
function DB:write(rawItems)
	local lines = {}
	local items = rawItems

	local itemCount = #items

	if itemCount > self.maxsize then
		items = u.slice(items, itemCount - self.maxsize)
	end

	for _, item in ipairs(items) do
		local parts = u.split(item.path, "\t")
		local filepath = parts[1] or "0"
		local lnum = parts[2] or 1
		local col = parts[3] or 0
		local regtype = item.regtype or "V"
		local filetype = item.filetype or "text"
		local timeused = item.timeused or os.time(os.date("!*t"))

		local line = item.id
			.. "|"
			.. filepath
			.. "|"
			.. lnum
			.. "|"
			.. col
			.. "|"
			.. regtype
			.. "|"
			.. filetype
			.. "|"
			.. timeused

		table.insert(lines, line)
		table.insert(lines, item.content)
	end

	local fileContents = table.concat(lines, "\n") .. "\n"
	local file = io.open(self.file, "w")
	file:write(fileContents)
	file:close()
end

--- Loads the DB file
--- @return HistoryItem[]
function DB:load()
	local items = {}

	local lines = {}
	local item = nil

	for line in io.lines(self.file) do
		if u.starts_with(line, "\t") then
			line = string.sub(line, 1)
			table.insert(lines, line)
		else
			if item ~= nil then
				item.content = table.concat(lines, "\n")
				if string.len(item.content) > 4 then
					table.insert(items, HistoryItem:new(item))
				end
				lines = {}
				item = nil
			end
			local parts = u.split(line or "", "|")
			local p = parts[2] or "0"
			local ln = parts[3] or 1
			local c = parts[4] or 0
			local path = p .. "\t" .. ln .. "\t" .. c
			local timeused = parts[7] or os.time(os.date("!*t"))

			item = {
				id = parts[1],
				path = path,
				regtype = parts[5],
				filetype = parts[6],
				timeused = timeused,
				content = {},
			}
		end
	end

	if item ~= nil then
		item.content = table.concat(lines, "\n")
		table.insert(items, HistoryItem:new(item))
	end

	return items
end

--- Appends a tab at the start of every line
--- @param content string[]
--- @return string[]
local function tab_it(content)
	local l = u.split(content, "\n")
	local tabbed = {}

	for _, li in ipairs(l) do
		table.insert(tabbed, "\t" .. li)
	end

	local tabbed_content = table.concat(tabbed, "\n")

	if not u.starts_with(tabbed_content, "\t") then
		tabbed_content = "\t" .. tabbed_content
	end

	return tabbed_content
end

--- Tells if a table contains an element (`needle`)
--- As this is not a by reference thing, elements in `tbl` and `needle`
--- should have a unique `id` property
--- to identify them.
--- @param items HistoryItem[]
--- @param needle HistoryItem
--- @return boolean
function DB.contains(items, needle)
	return u.contains(items, needle, function(a, b)
		return a.id == b.id
	end)
end

--- Adds a element to the database
--- @param content string[]
--- @param regtype string
--- @param filepath string
--- @param filetype string
function DB:add(content, regtype, filepath, filetype)
	local tabbed_content = tab_it(content)

	local item = self:build_item(tabbed_content, filepath, regtype, filetype)
	local items = self:load()

	if self:contains(items, item) then
		return
	end

	table.insert(items, item)
	self:write(items)
end

--- Removes an element from the database
--- @param id string
function DB:delete(id)
	local items = self:load()
	local filtered = {}

	for _, item in ipairs(items) do
		if item.id ~= id then
			table.insert(filtered, item)
		end
	end

	self:write(items)
end

--- Update the last time the time was used (for sorting)
--- @param id string
function DB:update_timeused(id)
	local items = self:load()
	local updated = {}

	for _, item in ipairs(items) do
		if item.id == id then
			item.timeused = os.time(os.date("!*t"))
		end
		table.insert(updated, item)
	end

	self:write(updated)
end

--- @export
return DB --- @type DB
