local lsp = require('feline.providers.lsp')
local vi_mode = require('feline.providers.vi_mode')
local icons = require('nvim-web-devicons')

local api = vim.api

local force_inactive = {
  filetypes = {},
  buftypes = {},
  bufnames = {}
}

local components = {
  active = {{}, {}, {}},
  inactive = {{}, {}, {}}
}

local colors = {
  bg = '#282828',
  black = '#282828',
  gray = '#3c3836',
  yellow = '#fabd2f',
  aqua = '#689d6a',
  blue = '#458588',
  green = '#b8bb26',
  orange = '#fe8019',
  violet = '#d3869b',
  white = '#d5c4a1',
  fg = '#a89984',
  skyblue = '#83a598',
  red = '#fb4934',
}

local vi_mode_colors = {
    ['NORMAL'] = 'green',
    ['OP'] = 'green',
    ['INSERT'] = 'skyblue',
    ['VISUAL'] = 'orange',
    ['LINES'] = 'orange',
    ['BLOCK'] = 'orange',
    ['REPLACE'] = 'violet',
    ['V-REPLACE'] = 'violet',
    ['ENTER'] = 'aqua',
    ['MORE'] = 'aqua',
    ['SELECT'] = 'orange',
    ['COMMAND'] = 'green',
    ['SHELL'] = 'green',
    ['TERM'] = 'green',
    ['NONE'] = 'yellow'
}

local buffer_not_empty = function()
  if vim.fn.empty(vim.fn.expand('%:t')) ~= 1 then
    return true
  end
  return false
end

local checkwidth = function()
  local squeeze_width  = vim.fn.winwidth(0) / 2
  if squeeze_width > 40 then
    return true
  end
  return false
end

force_inactive.filetypes = {
  'NvimTree',
  'dbui',
  'packer',
  'startify',
  'fugitive',
  'fugitiveblame'
}

force_inactive.buftypes = {
  'terminal'
}

components.active[1][1] = {
  provider = vi_mode.get_vim_mode,
  hl = function()
    local val = {}

    val.bg = vi_mode.get_mode_color()
    val.fg = 'black'
    val.style = 'bold'

    return val
  end,
  left_sep = function()
    return {
      hl = {
        fg = vi_mode.get_mode_color(),
        bg = 'gray'
      },
      str = '█'
    }
  end,
  right_sep = function()
    local bg

    if vim.fn.expand("%:F"):len() > 0 then
      bg = 'gray'
    else
      bg = 'NONE'
    end

    return {
      hl = {
        fg = vi_mode.get_mode_color(),
        bg = bg
      },
      str = '█'
    }
  end
}

-- components.active[1][2] = {
--   provider = function()
--     local filename = vim.fn.expand('%:t')
--     local extension = vim.fn.expand('%:e')
--     local icon = icons.get_icon(filename, extension)
--     if icon == nil then
--       icon = ''
--     end
--     return icon
--   end,
--   enabled = function() return vim.fn.expand("%:F"):len() > 0 end,
--   hl = function()
--     local val = {}
--     local filename = vim.fn.expand('%:t')
--     local extension = vim.fn.expand('%:e')
--     local icon, name = icons.get_icon(filename, extension)
--     if icon ~= nil then
--       val.fg = vim.fn.synIDattr(vim.fn.hlID(name), 'fg')
--     else
--       val.fg = 'white'
--     end
--     val.bg = 'gray'
--     val.style = 'bold'
--     return val
--   end,
--   left_sep = '█',
--   right_sep = '█'
-- }

components.active[1][2] = {
  provider = 'file_info',
  type = 'unique',
  enabled = function()
    return vim.fn.fnamemodify(api.nvim_buf_get_name(api.nvim_get_current_buf()), ':t'):len() > 0
  end,
  hl = {
    fg = 'white',
    bg = 'gray',
    style = 'bold'
  },
  left_sep = '█',
  right_sep = ''
}

-- components.active[1][3] = {
--   provider = function() return vim.fn.expand("%:F") end,
--   hl = function()
--     local fg
--     local bufnr = api.nvim_get_current_buf()

--     if api.nvim_buf_get_option(bufnr, "modified") then
--       fg = 'skyblue'
--     else
--       fg = 'white'
--     end

--     return {
--       fg = fg,
--       bg = 'gray',
--       style = 'bold'
--     }
--   end,
--   right_sep = '█'
-- }

components.active[1][3] = {
  provider = 'git_branch',
  hl = {
    fg = 'yellow',
    bg = 'bg',
    style = 'bold'
  },
  left_sep = ' ',
  right_sep = ' '
}

components.active[1][4] = {
  provider = 'git_diff_added',
  hl = {
    fg = 'green',
    bg = 'bg',
    style = 'bold'
  }
}

components.active[1][5] = {
  provider = 'git_diff_changed',
  hl = {
    fg = 'orange',
    bg = 'bg',
    style = 'bold'
  }
}

components.active[1][6] = {
  provider = 'git_diff_removed',
  hl = {
    fg = 'red',
    bg = 'bg',
    style = 'bold'
  }
}

-- function is_active(bufnr)
--   return api.nvim_buf_get_option(bufnr, "buflisted") and api.nvim_buf_get_name(bufnr) ~= ""
-- end

-- local function get_buffers()
--   local buffers = {}
--   local current_bufnr = api.nvim_get_current_buf()

--   for _, buffer in ipairs(api.nvim_list_bufs()) do
--     if is_active(buffer) then
--       local fg
--       if buffer == current_bufnr then
--         fg = 'skyblue'
--       else
--         fg = 'gray'
--       end
--       table.insert(buffers, {
--         str = api.nvim_buf_get_name(buffer),
--         hl = {
--           fg = fg,
--           bg = 'bg'
--         },
--         left_sep = ' ',
--         right_sep = ' ',
--       })
--     end
--   end

--   return unpack(buffers)
-- end

-- components.active[2][1] = {
--   provider = get_buffers
-- }

components.active[3][1] = {
  provider = 'lsp_client_names',
  hl = {
    fg = 'yellow',
    bg = 'bg',
    style = 'bold'
  },
  right_sep = ' '
}

-- diagnosticErrors
components.active[3][2] = {
  provider = 'diagnostic_errors',
  enabled = function() return lsp.diagnostics_exist('Error') end,
  hl = {
    fg = 'red',
    style = 'bold'
  }
}
-- diagnosticWarn
components.active[3][3] = {
  provider = 'diagnostic_warnings',
  enabled = function() return lsp.diagnostics_exist('Warning') end,
  hl = {
    fg = 'yellow',
    style = 'bold'
  }
}
-- diagnosticHint
components.active[3][4] = {
  provider = 'diagnostic_hints',
  enabled = function() return lsp.diagnostics_exist('Hint') end,
  hl = {
    fg = 'cyan',
    style = 'bold'
  }
}
-- diagnosticInfo
components.active[3][5] = {
  provider = 'diagnostic_info',
  enabled = function() return lsp.diagnostics_exist('Information') end,
  hl = {
    fg = 'skyblue',
    style = 'bold'
  }
}


require('feline').setup({
  colors = colors,
  default_bg = bg,
  default_fg = fg,
  vi_mode_colors = vi_mode_colors,
  components = components,
  force_inactive = force_inactive,
})
