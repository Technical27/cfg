fun! g:LoadColors()
  hi! clear SignColumn

  " all the treesitter highlights
  hi! link TSAnnotation GruvboxAqua
  hi! link TSBoolean GruvboxPurple
  hi! link TSCharacter GruvboxPurple
  hi! TSComment gui=italic guifg=GruvboxGray
  hi! link TSConstructor GruvboxOrange
  hi! link TSConditional GruvboxRed
  hi! link TSConstant GruvboxPurple
  hi! link TSConstBuiltin GruvboxOrange
  hi! link TSConstMacro GruvboxAqua
  hi! link TSError GruvboxRed
  hi! link TSException GruvboxRed
  hi! link TSField GruvboxBlue
  hi! link TSFloat GruvboxPurple
  hi! link TSFunction GruvboxGreenBold
  hi! link TSFuncBuiltin GruvboxOrange
  hi! link TSFuncMacro GruvboxAqua
  hi! link TSInclude GruvboxAqua
  hi! link TSKeyword GruvboxRed
  hi! link TSLabel GruvboxRed
  hi! link TSMethod GruvboxGreenBold
  hi! link TSNamespace GruvboxAqua
  hi! clear TSNone
  hi! link TSNumber GruvboxPurple
  hi! link TSOperator GruvboxFg1
  hi! link TSParamter GruvboxBlue
  hi! link TSParameterReferance TSParameter
  hi! link TSProperty GruvboxBlue
  hi! link TSPunctDelimiter GruvboxFg
  hi! link TSPunctBracket GruvboxFg
  hi! link TSPunctSpecial GruvboxFg
  hi! link TSTagDelimiter GruvboxFg
  hi! link TSRepeat GruvboxRed
  hi! link TSString GruvboxGreen
  hi! link TSStringRegex GruvboxYellow
  hi! link TSStringEscape GruvboxOrange
  hi! link TSTag GruvboxRed
  hi! link TSText TSNone
  hi! link TSLiteral GruvboxGreen
  hi! TSURI gui=underline guifg=GruvboxAqua
  hi! link TSType GruvboxYellow
  hi! link TSTypeBuiltin GruvboxYellow
  hi! link TSVariable GruvboxFg
  hi! TSEmphasis gui=italic
  hi! TSUnderline gui=underline
endf

call g:LoadColors()

augroup Color
  autocmd!
  autocmd ColorScheme * call g:LoadColors()
augroup end
