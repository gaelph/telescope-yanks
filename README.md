# Telescope-yanks

A Yank extensions for [Telescope](https://github.com/nvim-telescope/telescope.nvim).

This a partial reimplementation of [coc-yank](https://github.com/neoclide/coc-yank), but rewrote in lua.

> *Note:* This still a very early release 

## Install

With packer:
```lua
use {"gaelph/telescope-yanks", rocks = {"md5", "luajson"}}
```

If you don’t use `packer`, you will need to install the `md5` and `luajson` rocks by yourself. Such a configuration have not yet been tested.

Along with your Telescope Configuration:
```lua
local telescope = require('telescope')

-- avaible options are described below
telescope.extensions.yanks.setup(options)

function Telescope.yanks()
    telescope.extensions.yanks.yanks {
        -- telescope finder configuration
    }
end

vim.api.nvim_set_keymap('n', '<space>y', ':lua Telescope.yanks()<cr>', {silent = true})
```

## Features

 * Persist yank list across vim instances.
 * Fuzzy search your yanks with a syntax highlighted preview.
 * Pastes the selected yank on enter.

## Options

All are optional

 * `options.db_dir`: path to a directory to store the yanks. Must exist. Defaults to `~/.local/nvim/yanks/`
 * `options.maxsize`: maximum number of yanks to store. Defaults to 200.

## License

MIT
