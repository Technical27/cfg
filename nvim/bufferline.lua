local get_hex = require('cokeline/utils').get_hex

local grey = "#c6c6c6"
local black = "#282828"

require('cokeline').setup({
  default_hl = {
    fg = function(buffer)
      return
        buffer.is_focused
        and black
        or grey
    end,
    bg = function(buffer)
      return
        buffer.is_focused
        and grey
        or black
    end,
  },

  components = {
    {
      text = function(buffer)
        if not buffer.is_first then
          if buffer.is_focused then
            return ''
          end

          local info = vim.fn.getbufinfo({ buflisted = true })

          if info[buffer.index - 1].bufnr ~= vim.fn.bufnr('%') then
            return ''
          end
        end
        return ''
      end,
    },
    {
      text = function(buffer) return ' ' .. buffer.devicon.icon end,
      fg = function(buffer) return buffer.devicon.color end,
    },
    {
      text = function(buffer) return buffer.unique_prefix end,
      fg = get_hex('Comment', 'fg'),
      style = 'italic',
    },
    {
      text = function(buffer) return buffer.filename .. ' ' end,
    },
    {
      text = function(buffer)
        if buffer.is_modified then
          return '+ '
        end
        return ''
      end
    },
    {
      text = function(buffer)
        if buffer.is_focused then
            return ''
        end
        return ''
      end,
      bg = function(buffer)
        return
          buffer.is_focused
          and black
          or grey
      end,
      fg = function(buffer)
        return
          buffer.is_focused
          and grey
          or black
      end,
    },
    {
      text = function(buffer)
        if buffer.is_last and not buffer.is_focused then
          return ''
        end
        return ''
      end
    }
  },
})
