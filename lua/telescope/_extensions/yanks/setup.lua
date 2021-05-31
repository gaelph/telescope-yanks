local DB = require("telescope._extensions.yanks.db")
local u = require("telescope._extensions.yanks.utils")

local M = {db = nil}

---Setup function for telescope-yanks plugin
-- @table options
-- Options :
--  - db_dir: path to a directory to store the yanks (must exist)
--            defaults to `~/.local/nvim/yanks`
--  - maxsize: maximum number of yanks to store
--             defaults do 200
function M.setup(options)
    M.db = DB:new(options)

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
        PasteMe = {{'TextYankPost', '*', 'call luaeval("__pasteme_handle(_A[1], _A[2])", [v:event, +expand(\'%:p\')])'}}
    })
end

return M
