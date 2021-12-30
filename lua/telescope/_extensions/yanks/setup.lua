--- @module Yanks
--- Telescope Extension
local DB = require("telescope._extensions.yanks.db") --- @type DB
local u = require("telescope._extensions.yanks.utils") --- @type Utils

local M = {}

--- Setup function for telescope-yanks plugin
--- @param options DBOptions
--- Options :
---  - db_dir: path to an existing directory to store the yanks
---            defaults to `~/.local/nvim/yanks`
---  - maxsize: maximum number of yanks to store
---             defaults do 200
function M.setup(options)
    M.db = DB:new(options) --- @type DB

    _G.__pasteme_handle = function(event, uri)
        local winnr = vim.api.nvim_get_current_win()

        local regtype = event.regtype
        local regcontents = event.regcontents

        local pos = vim.api.nvim_win_get_cursor(winnr)
        local line = pos[1] or 0
        local col = pos[2] or 0

        local filetype = vim.bo.filetype

        local content = table.concat(regcontents, "\n")

        if string.len(content) > 4 then
            local path = uri .. "\t" .. line .. "\t" .. col
            M.db:add(content, regtype, path, filetype)
        end
    end

    u.nvim_create_augroups({
        PasteMe = {
            {
                'TextYankPost', '*',
                'call luaeval("__pasteme_handle(_A[1], _A[2])", [v:event, +expand(\'%:p\')])'
            }
        }
    })
end

--- @class YanksExtension
--- @field db DB
--- @field setup function

return M -- @type YanksExtension
