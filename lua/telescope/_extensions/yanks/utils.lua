local Utils = {}
local api = vim.api

---Reverses a list in place
---@table t
function Utils.reverse(t)
    local n = #t
    local i = 1
    while i < n do
        t[i], t[n] = t[n], t[i]
        i = i + 1
        n = n - 1
    end
end

---Split a string using a separator
---@string string
---@string sep
---@treturn Array(string)
function Utils.split(string, sep)
    local t = {}

    for token in string.gmatch(string, "[^%" .. sep .. "]+") do table.insert(t, token) end

    return t
end

---Counts how many items in a table
---@table table
---@treturn number
function Utils.count(tbl)
    local c = 0

    for _, _ in ipairs(tbl) do c = c + 1 end

    return c
end

---Splits a yank content and removes the tab padding
---@string content
---@treturn Array(string)
function Utils.read_lines(content)
    local lines = {}
    Utils.split(content, "\n")
    for _, line in ipairs(Utils.split(content, "\n")) do table.insert(lines, string.sub(line, 2)) end
    return lines
end

---Gets the first of an array of strings
---@table value
---@treturn string
function Utils.first(value)
    local candidate
    if Utils.count(value) > 0 then
        local c = 0
        candidate = value[c]

        while candidate == nil or candidate == "" do
            c = c + 1
            candidate = value[c]

            if candidate ~= nil then return candidate end
        end
    end

    return "ERROR"
end

---Creates augroups
-- @table definitions
function Utils.nvim_create_augroups(definitions)
    for group_name, definition in pairs(definitions) do
        api.nvim_command('augroup ' .. group_name)
        api.nvim_command('autocmd!')
        for _, def in ipairs(definition) do
            local command = table.concat(vim.tbl_flatten {'autocmd', def}, ' ')
            api.nvim_command(command)
        end
        api.nvim_command('augroup END')
    end
end

return Utils
