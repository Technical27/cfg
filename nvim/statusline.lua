local gl = require 'galaxyline'
local cond = require 'galaxyline.condition'
local diagnostic = require 'galaxyline.provider_diagnostic'
local fileinfo = require 'galaxyline.provider_fileinfo'
local gls = gl.section

local function get_color(group)
    return vim.fn.synIDattr(vim.fn.hlID(group), "fg", "gui")
end

local colors = {
    bg = get_color('GruvboxBg0'),
    fg = get_color('GruvboxFg0'),
    section_bg = get_color('GruvboxBg1'),
    blue = get_color('GruvboxBlue'),
    green = get_color('GruvboxGreen'),
    purple = get_color('GruvboxPurple'),
    orange = get_color('GruvboxOrange'),
    red = get_color('GruvboxRed'),
    yellow = get_color('GruvboxYellow'),
    darkgrey = get_color('GruvboxFg1'),
    middlegrey = get_color('GruvboxFg2'),
}

local mode_color = function()
    local mode_colors = {
        [110] = colors.green,
        [105] = colors.blue,
        [99] = colors.green,
        [116] = colors.red,
        [118] = colors.orange,
        [22] = colors.orange,
        [86] = colors.purple,
        [82] = colors.purple,
        [115] = colors.purple,
        [83] = colors.purple,
    }

    local color = mode_colors[vim.fn.mode():byte()]
    if color ~= nil then
        return color
    else
        return colors.purple
    end
end

gls.left[1] = {
    ViMode = {
        provider = function()
            local aliases = {
                [110] = 'NORMAL',
                [105] = 'INSERT',
                [99] = 'COMMAND',
                [116] = 'TERMINAL',
                [118] = 'VISUAL',
                [22] = 'V-BLOCK',
                [86] = 'V-LINE',
                [82] = 'REPLACE',
                [115] = 'SELECT',
                [83] = 'S-LINE',
            }
            vim.api.nvim_command('hi GalaxyViMode guibg=' .. mode_color())
            vim.api.nvim_command('hi ViModeSeparator guifg=' .. mode_color())
            local mode = aliases[vim.fn.mode():byte()]
            if mode == nil then
                mode = vim.fn.mode():byte()
            end
            return '  ' .. mode .. ' '
        end,
        highlight = { colors.bg, colors.bg, 'bold' },
        separator = '',
        separator_highlight = { colors.bg, colors.section_bg, 'bold' },
    },
}

local function is_file()
    return vim.bo.buftype ~= 'nofile'
end

gls.left[2] = {
    FileIcon = {
        provider = function()
          return '  ' .. fileinfo.get_file_icon()
        end,
        condition = cond.buffer_not_empty,
        highlight = {
            fileinfo.get_file_icon_color,
            colors.section_bg
        },
    }
}

local function get_current_file_name()
    local file = vim.fn.expand('%:t')
    if vim.fn.empty(file) == 1 then return '' end
    -- if string.len(file_readonly()) ~= 0 then return file .. file_readonly() end
    --  .. ' '
    return file
end

gls.left[3] = {
    FileName = {
        provider = get_current_file_name,
        condition = function()
            return cond.buffer_not_empty and is_file
        end,
        highlight = { colors.middlegrey, colors.section_bg },
    },
}

local function file_status()
    if vim.bo.filetype == 'help' then return '' end
    if vim.bo.readonly == true then return '' end
    if vim.bo.modifiable then
        if vim.bo.modified then
            vim.api.nvim_command('hi GalaxyFileStatus guifg=' .. mode_color())
            return file .. '+'
        end
    end
    return ''
end

-- gls.left[4] = {
--    FileStatus = {
--        provider = file_status, condition = is_file, highlight = { colors.middlegrey, colors.section_bg },
--    }
--}

gls.right[2] = {
    Ruler = {
        provider = function()
            local pos = vim.fn.getcurpos()
            local buflines = vim.api.nvim_buf_line_count(0)
            local pct = math.floor((pos[2] / buflines) * 100)
            return string.format(' %d:%d ', pos[2], pos[3])
        end,
        condition = is_file,
        highlight = { colors.bg, colors.orange },
        separator = '',
        separator_highlight = { colors.orange, colors.section_bg },
    }
}

local function isgit()
    local cwd = vim.fn.getcwd()
    return vim.fn.isdirectory(cwd .. '/.git') == 1
end

gls.right[1] = {
    Project = {
        provider = function()
            return ' ' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t') .. ' '
        end,
        highlight = { colors.middlegrey, colors.section_bg },
        condition = isgit
    }
}

