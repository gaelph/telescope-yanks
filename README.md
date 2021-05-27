# Telescope-yanks

A Yank extensions for [Telescope](https://github.com/nvim-telescope/telescope.nvim).

This a partial reimplementation of [coc-yank](https://github.com/neoclide/coc-yank), but rewrote in lua.

## Install

With packer:
```lua
	use {"gaelph/telescope-yanks", rocks = {"md5", "luajson"}}
```

Along with your Telescope Configuration:
```lua
-- see options below
telescope.extensions.yanks.setup(options)

function Telescope.yanks()
    telescope.extensions.yanks.yanks {
        -- telescope finder configuration
    }
end

vim.api.nvim_set_keymap('n', '<space>y', ':lua Telescope.yanks()<cr>', {silent = true})
vimp.nmap('<Space>y', ':lua Telescope.yanks()<CR>')
```

## Options

All are optional

 * `options.db_dir`: path to a directory to store the yanks. Must exist. Defaults to `~/.local/nvim/yanks/`
 * `options.maxsize`: maximum number of yanks to store. Defaults to 200.

## License

MIT