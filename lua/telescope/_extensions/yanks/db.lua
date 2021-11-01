DATA_PATH = vim.fn.stdpath('data')

local md5 = require('md5')
local json = require('json')

local default_db_dir = DATA_PATH .. "/yanks"
os.execute("mkdir -p " .. default_db_dir)

--- Counts elements in a table
-- @table tbl
-- @treturn number
local function count(tbl)
    local c = 0

    for _, _ in ipairs(tbl) do c = c + 1 end

    return c
end

--- Slices a table in two, returns the part after `start`
-- @number t
-- @table tbl
-- @treturn tbl
local function slice(t, start)
    local r = {}

    for i, item in ipairs(t) do if i > start then table.insert(r, item) end end

    return r
end

--- Splits a string on every occurence of `sep`
-- @string str
-- @string sep
-- @treturn tbl
local function split(str, sep)
    local arr = {}
    local sub = ""
    for i = 1, #str do
        local c = str:sub(i, i)
        if c ~= sep then
            sub = sub .. c
        else
            table.insert(arr, sub)
            sub = ""
        end
    end

    if sub ~= "" then
        table.insert(arr, sub)
        sub = ""
    end

    return arr
end

--- Tells if a table contains an element (`needle`)
-- As this is not a by reference thing, elements in `tbl` and `needle`
-- should have a unique `id` property
-- to identify them.
-- @table tbl
-- @table needle
-- @treturn boolean
local function contains(tbl, needle)
    for _, item in ipairs(tbl) do
        if item.id == needle.id then return true end
    end

    return false
end

--- Return `true` if `str` starts with `start`
-- @string str
-- @string start
-- @return a boolean value
local function starts_with(str, start)
    return str:sub(1, #start) == start
end

---
---@class HistoryItem
local HistoryItem = {
    id = "",
    content = {},
    regtype = "",
    path = "",
    filetype = "",
    timeused = ""
}

---
---@param params table
---@return HistoryItem
function HistoryItem:new(params)
    setmetatable(params, self)
    self.__index = self

    return params
end

---The DB class reads from, and writes to the db file
---@class DB
-- @property {string} file      path to database file
-- @property {number} maxsize   maximum number of yanks stored
local DB = {file = default_db_dir .. "/yanks.json", maxsize = 200}

---Constructor
-- The `options` object has two optional porporties:
--  - db_dir: string, path of an existing directory into which store the `yanks.json` file,
--            defaults do `~/.local/share/nvim/yanks/`
--  - maxsize: number, maximum number of yanks to store
--             defaults to 200
-- @table options
---@return DB
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
    return (str:gsub('.', function(c)
        return string.format('%02X', string.byte(c))
    end))
end

---comment
---@param content string[]
---@param filepath string
---@param regtype string
---@param filetype string
---@treturn HistoryItem
function DB:build_item(content, filepath, regtype, filetype)
    local id = string.tohex(md5.sum(content))
    local timeused = os.time(os.date("!*t"))

    return HistoryItem:new({
        id = id,
        content = content,
        regtype = regtype,
        filetype = filetype,
        path = filepath,
        timeused = timeused
    })
end

---comment
---@param rawItems HistoryItem[]
function DB:write(rawItems)
    local lines = {}
    local items = rawItems

    local itemCount = count(items)

    if itemCount > self.maxsize then
        items = slice(items, itemCount - self.maxsize);
    end

    for _, item in ipairs(items) do
        local parts = split(item.path, '\t')
        local filepath = parts[1] or "0"
        local lnum = parts[2] or 1
        local col = parts[3] or 0
        local regtype = item.regtype or "V"
        local filetype = item.filetype or "text"
        local timeused = item.timeused or os.time(os.date("!*t"))

        local line = item.id .. "|" .. filepath .. "|" .. lnum .. "|" .. col ..
                         "|" .. regtype .. "|" .. filetype .. "|" .. timeused

        table.insert(lines, line)
        table.insert(lines, item.content)
    end

    local fileContents = table.concat(lines, "\n") .. "\n"
    local file = io.open(self.file, "w")
    file:write(fileContents)
    file:close()
end

---comment
---@return HistoryItem[]
function DB:load()
    local items = {}

    local lines = {}
    local item = nil

    for line in io.lines(self.file) do
        if starts_with(line, "\t") then
            line = string.sub(line, 1)
            table.insert(lines, line)
        else
            if item ~= nil then
                item.content = table.concat(lines, '\n')
                if string.len(item.content) > 4 then
                    table.insert(items, HistoryItem:new(item))
                end
                lines = {}
                item = nil
            end
            local parts = split(line or "", "|")
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
                content = {}
            }
        end
    end

    if item ~= nil then
        item.content = table.concat(lines, '\n')
        table.insert(items, HistoryItem:new(item))
    end

    return items
end

local function tab_it(content)
    local l = split(content, '\n')
    local tabbed = {}

    for _, li in ipairs(l) do table.insert(tabbed, "\t" .. li) end

    local tabbed_content = table.concat(tabbed, '\n')

    if not starts_with(tabbed_content, "\t") then
        tabbed_content = "\t" .. tabbed_content
    end

    return tabbed_content
end

function DB:add(content, regtype, filepath, filetype)
    local tabbed_content = tab_it(content)

    local item = self:build_item(tabbed_content, filepath, regtype, filetype)
    local items = self:load()

    if contains(items, item) then return end

    table.insert(items, item)
    self:write(items)
end

function DB:delete(id)
    local items = self:load()
    local filtered = {}

    for _, item in ipairs(items) do
        if item.id ~= id then table.insert(filtered, item) end
    end

    self:write(items)
end

function DB:update_timeused(id)
    local items = self:load()
    local updated = {}

    for _, item in ipairs(items) do
        if item.id == id then item.timeused = os.time(os.date("!*t")) end
        table.insert(updated, item)
    end

    self:write(updated)
end

function DB:_convert_json(json_file)
    local file = io.open(json_file, "r")
    local content = file:read()
    local raw_items = json.decode(content)

    local items = {}
    for _, r in ipairs(raw_items) do
        local item = self:build_item({
            content = r.content,
            filepath = r.filepath,
            regtype = r.regtype,
            filetype = r.filetype
        })
        table.insert(items, item)
    end

    self:write(items)
end

return DB
