--- @classmod Utils
--- @class Utils
local Utils = {}
local api = vim.api

--- Reverses a list in place
--- @generic T
--- @param t T[]
--- @return T[]
function Utils.reverse(t)
    local n = #t
    local i = 1
    while i < n do
        t[i], t[n] = t[n], t[i]
        i = i + 1
        n = n - 1
    end
end

--- Split a string using a separator
--- @param str string
--- @param sep string
--- @return string[]
function Utils.split(str, sep)
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

--- Slices a table in two, returns the part after `start`
--- @generic N
--- @param t N[]
--- @param start number
--- @return N[]
function Utils.slice(t, start)
    local r = {}

    for i, item in ipairs(t) do if i > start then table.insert(r, item) end end

    return r
end

--- Tells if a table contains an element (`needle`)
--- As this is not a by reference thing, elements in `tbl` and `needle`
--- should have a unique `id` property
--- to identify them.
--- @generic T
--- @param tbl T[]
--- @param needle T
--- @param comp fun(a: T, b: T): boolean
--- @return boolean
function Utils.contains(tbl, needle, comp)
    for _, item in ipairs(tbl) do if comp(item, needle) then return true end end

    return false
end

--- Return `true` if `str` starts with `start`
--- @param str string
--- @param start string
--- @return boolean value
function Utils.starts_with(str, start)
    return str:sub(1, #start) == start
end

--- Splits a yank content and removes the tab padding
--- @param content string[]
--- @return string[]
function Utils.read_lines(content)
    local lines = {}
    Utils.split(content, "\n")
    for _, line in ipairs(Utils.split(content, "\n")) do
        table.insert(lines, string.sub(line, 2))
    end
    return lines
end

--- Gets the first of an array of strings
--- @param value string[]
--- @return string
--- @raise table is empty
function Utils.first(value)
    local candidate
    if #value > 0 then
        local c = 0
        candidate = value[c]

        while candidate == nil or candidate == "" do
            c = c + 1
            candidate = value[c]

            if candidate ~= nil then return candidate end
        end
    end

    error("table is empty")
end

--- Creates augroups
--- @param definitions table<string, string[][]>
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

--- @exports
return Utils --- @type Utils
