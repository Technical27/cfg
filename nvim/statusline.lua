local windline = require('windline')
local helper = require('windline.helpers')
local sep = helper.separators
local b_components = require('windline.components.basic')
local state = _G.WindLine.state
local vim_components = require('windline.components.vim')
local HSL = require('wlanimation.utils')

local lsp_comps = require('windline.components.lsp')
local git_comps = require('windline.components.git')

local hl_list = {
    Black = { 'white', 'black' },
    White = { 'black', 'white' },
    Normal = { 'NormalFg', 'NormalBg' },
    Inactive = { 'InactiveFg', 'InactiveBg' },
    Active = { 'ActiveFg', 'ActiveBg' },
}
local basic = {}

local airline_colors = {}

airline_colors.a = {
    NormalSep = { 'magenta_a', 'magenta_b' },
    InsertSep = { 'blue_a', 'blue_b' },
    VisualSep = { 'yellow_a', 'yellow_b' },
    ReplaceSep = { 'blue_a', 'blue_b' },
    CommandSep = { 'red_a', 'red_b' },
    Normal = { 'black', 'magenta_a' },
    Insert = { 'black', 'blue_a' },
    Visual = { 'black', 'yellow_a' },
    Replace = { 'black', 'blue_a' },
    Command = { 'black', 'red_a' },
}

airline_colors.b = {
    NormalSep = { 'magenta_b', 'magenta_c' },
    InsertSep = { 'blue_b', 'blue_c' },
    VisualSep = { 'yellow_b', 'yellow_c' },
    ReplaceSep = { 'blue_b', 'blue_c' },
    CommandSep = { 'red_b', 'red_c' },
    Normal = { 'white', 'magenta_b' },
    Insert = { 'white', 'blue_b' },
    Visual = { 'white', 'yellow_b' },
    Replace = { 'white', 'blue_b' },
    Command = { 'white', 'red_b' },
}

airline_colors.c = {
    NormalSep = { 'magenta_c', 'NormalBg' },
    InsertSep = { 'blue_c', 'NormalBg' },
    VisualSep = { 'yellow_c', 'NormalBg' },
    ReplaceSep = { 'blue_c', 'NormalBg' },
    CommandSep = { 'red_c', 'NormalBg' },
    Normal = { 'white', 'magenta_c' },
    Insert = { 'white', 'blue_c' },
    Visual = { 'white', 'yellow_c' },
    Replace = { 'white', 'blue_c' },
    Command = { 'white', 'red_c' },
}

basic.divider = { b_components.divider, hl_list.Normal }

local width_breakpoint_1 = 100
local width_breakpoint_2 = 75
local width_breakpoint_3 = 40

basic.section_a = {
    hl_colors = airline_colors.a,
    text = function(_,_,width)
        if width > width_breakpoint_2 then
            return {
                { ' ' .. state.mode[1] .. ' ', state.mode[2] },
                { sep.right_filled, state.mode[2] .. 'Sep' },
            }
        end
        if width > width_breakpoint_3 then
            return {
                { ' ' .. state.mode[1]:sub(1, 1) .. ' ', state.mode[2] },
                { sep.right_filled, state.mode[2] .. 'Sep' },
            }
        end
        return { { sep.right_filled, state.mode[2] .. 'Sep' } }
    end,
}


basic.section_b = {
    hl_colors = airline_colors.b,
    text = function(bufnr,_, width)
        if width > width_breakpoint_2 and git_comps.is_git(bufnr) then
            return {
                { git_comps.git_branch() , state.mode[2] },
                { ' ', '' },
                { sep.right_filled, state.mode[2] .. 'Sep' },
            }
        end
        return { { sep.right_filled, state.mode[2] .. 'Sep' } }
    end,
}


basic.section_c = {
    hl_colors = airline_colors.c,
    text = function()
        return {
            { ' ', state.mode[2] },
            { b_components.cache_file_name('[No Name]', 'unique')},
            { sep.right_filled, state.mode[2] .. 'Sep' },
        }
    end,
}

basic.section_x = {
    hl_colors = airline_colors.c,
    text = function(bufnr,_,width)
        if width > width_breakpoint_1 and vim.fn.expand('%') ~= '' then
            return {
                { sep.left_filled, state.mode[2] .. 'Sep' },
                { ' ', state.mode[2] },
                { b_components.file_encoding() },
                { ' ' },
                { b_components.file_format({ icon = true }) },
                { ' ' },
            }
        end
        return {
            { sep.left_filled, state.mode[2] .. 'Sep' },
        }
    end,
}

basic.section_y = {
    hl_colors = airline_colors.b,
    text = function(bufnr,_,width)
        if vim.bo[bufnr].filetype ~= '' then
            if width > width_breakpoint_1 then
                return {
                    { sep.left_filled, state.mode[2] .. 'Sep' },
                    { ' ', state.mode[2] },
                    -- NOTE: can't cache to buffer because of state.mode highlight
                    b_components.file_icon({ default = "", hl_colors = airline_colors.b[state.mode[2]]})(bufnr),
                    { ' ' },
                    { b_components.cache_file_type(), state.mode[2] },
                    { ' ' },
                }
            end
            if width > width_breakpoint_3 then
                return {
                    { sep.left_filled, state.mode[2] .. 'Sep' },
                    -- NOTE: see above
                    { ' ', state.mode[2] },
                    b_components.file_icon({ default = "", hl_colors = airline_colors.b[state.mode[2]]})(bufnr),
                    { ' ' },
                }
            end
        end
        return { { sep.left_filled, state.mode[2] .. 'Sep' } }
    end,
}

basic.section_z = {
    hl_colors = airline_colors.a,
    text = function(_,_,width)
        if width > width_breakpoint_2 then
            return {
                { sep.left_filled, state.mode[2] .. 'Sep' },
                { '  ', state.mode[2] },
                { b_components.progress_lua },
                { ' ' },
                { b_components.line_col_lua },
            }
        end
        if width > width_breakpoint_3 then
            return {
                { sep.left_filled, state.mode[2] .. 'Sep' },
                { ' ', state.mode[2] },
                { b_components.line_col_lua, state.mode[2] },
            }
        end
        return {
            { sep.left_filled, state.mode[2] .. 'Sep' },
            { b_components.line_col_lua, state.mode[2] },
        }
    end,
}

basic.lsp_diagnos = {
    name = 'diagnostic',
    width = width_breakpoint_2,
    hl_colors = {
        red = { 'red', 'NormalBg' },
        yellow = { 'yellow', 'NormalBg' },
        blue = { 'blue', 'NormalBg' },
    },
    text = function(bufnr,_,width)
        if lsp_comps.check_lsp(bufnr) then
            return {
                { ' ' },
                { lsp_comps.lsp_error({ format = ' %s', show_zero = true }), 'red' },
                { ' ' },
                { lsp_comps.lsp_warning({ format = ' %s', show_zero = true }), 'yellow' },
                { ' ' },
                { lsp_comps.lsp_hint({ format = ' %s', show_zero = true }), 'blue' },
            }
        end
        return ''
    end,
}

basic.git = {
    name = 'git',
    width = width_breakpoint_1,
    hl_colors = {
        green = { 'green', 'NormalBg' },
        red = { 'red', 'NormalBg' },
        blue = { 'blue', 'NormalBg' },
    },
    text = function(bufnr)
        if git_comps.is_git(bufnr) then
            return {
                { git_comps.diff_added({ format = ' %s', show_zero = true }), 'green' },
                { ' ' },
                { git_comps.diff_removed({ format = ' %s', show_zero = true }), 'red' },
                { ' ' },
                { git_comps.diff_changed({ format = '柳%s', show_zero = true }), 'blue' },
                { ' ' },
            }
        end
        return ''
    end,
}

local explorer = {
    filetypes = { 'fern', 'NvimTree', 'lir' },
    active = {
        { '  ', { 'white', 'magenta_b' } },
        { helper.separators.slant_right, { 'magenta_b', 'NormalBg' } },
        { b_components.divider, '' },
        { b_components.file_name(''), { 'NormalFg', 'NormalBg' } },
    },
    always_active = true,
    show_last_status = true
}

local default = {
    filetypes = { 'default' },
    active = {
        basic.section_a,
        basic.section_b,
        basic.section_c,
        basic.lsp_diagnos,
        { vim_components.search_count(), hl_list.Normal },
        basic.divider,
        basic.git,
        basic.section_x,
        basic.section_y,
        basic.section_z,
    },
    inactive = {
        { b_components.full_file_name, hl_list.Inactive },
        { b_components.divider, hl_list.Inactive },
        { b_components.line_col, hl_list.Inactive },
        { b_components.progress, hl_list.Inactive },
    },
}

windline.setup({
    theme = "gruvbox",
    colors_name = function(colors)
        local mod = function (c, value)
            if vim.o.background == 'light' then
                return HSL.rgb_to_hsl(c):tint(value):to_rgb()
            end
            return HSL.rgb_to_hsl(c):shade(value):to_rgb()
        end

        colors.magenta_a = colors.magenta
        colors.magenta_b = mod(colors.magenta,0.5)
        colors.magenta_c = mod(colors.magenta,0.7)

        colors.yellow_a = colors.yellow
        colors.yellow_b = mod(colors.yellow,0.5)
        colors.yellow_c = mod(colors.yellow,0.7)

        colors.blue_a = colors.blue
        colors.blue_b = mod(colors.blue,0.5)
        colors.blue_c = mod(colors.blue,0.7)

        colors.green_a = colors.green
        colors.green_b = mod(colors.green,0.5)
        colors.green_c = mod(colors.green,0.7)

        colors.red_a = colors.red
        colors.red_b = mod(colors.red,0.5)
        colors.red_c = mod(colors.red,0.7)

        return colors
    end,
    statuslines = {
        default,
        explorer,
    },
})
