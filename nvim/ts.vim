fun! g:LoadColors()
  hi! link SignColumn GruvboxBg
  hi! link TabLineFill GruvboxBg
  hi! link CursorLineNr GruvboxYellow

  " all the treesitter highlights
  hi! @annotation gui=italic guifg=#8ec07c
  hi! @attribute gui=italic guifg=#8ec07c
  hi! link @boolean GruvboxPurple
  hi! link @character GruvboxPurple
  hi! @comment gui=italic guifg=#928374
  hi! link @constructor GruvboxOrange
  hi! link @conditional GruvboxRed
  hi! link @constant GruvboxPurple
  hi! link @constant.builtin GruvboxOrange
  hi! link @constant.macro GruvboxAqua
  hi! link @error GruvboxRed
  hi! link @exception GruvboxRed
  hi! link @field GruvboxBlue
  hi! link @float GruvboxPurple
  hi! link @function GruvboxGreenBold
  hi! link @function.builtin GruvboxOrangeBold
  hi! link @function.macro GruvboxAquaBold
  hi! link @include GruvboxAqua
  hi! link @keyword GruvboxRed
  hi! link @label GruvboxRed
  hi! link @method GruvboxGreenBold
  hi! link @namespace GruvboxAqua
  hi! link @number GruvboxPurple
  hi! link @operator GruvboxFg1
  hi! link @parameter GruvboxBlue
  hi! link @parameter.reference GruvboxBlue
  hi! link @property GruvboxBlue
  hi! link @punctuation.delimiter GruvboxFg
  hi! link @punctuation.braket GruvboxFg
  hi! link @punctuation.special GruvboxFg
  hi! link @tag.delimter GruvboxFg
  hi! link @repeat GruvboxRed
  hi! link @string GruvboxGreen
  hi! link @string.regex GruvboxYellow
  hi! link @string.escape GruvboxOrange
  hi! link @tag GruvboxRed
  hi! link @text @none
  hi! link @literal GruvboxGreen
  hi! link @uri GruvboxBlueUnderline
  hi! link @type GruvboxYellow
  hi! link @type.builtin GruvboxYellow
  hi! link @type.qualifier GruvboxRed
  hi! link @variable GruvboxFg
  hi! link @variable.builtin GruvboxOrange
  hi! @emphasis gui=italic
  hi! @underline gui=underline
endf

augroup Color
  autocmd!
  autocmd ColorScheme gruvbox call g:LoadColors()
augroup end
