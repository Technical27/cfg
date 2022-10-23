local get_hex = require('cokeline/utils').get_hex
local get_visible = require('cokeline/buffers').get_visible

local grey = "#c6c6c6"
local black = get_hex("GruvboxBg0", "fg")

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

  buffers = {
    filter_valid = function(buffer)
      if vim.bo[buffer.number].filetype == 'qf' then
        return false
      end
      return true
    end
  },

  components = {
    {
      text = function(buffer)
        if not buffer.is_first then
          if buffer.is_focused then
            return ''
          end

          local info = get_visible()

          if not info[buffer.index - 1].is_focused then
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
