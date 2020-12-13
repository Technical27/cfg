{
  keybindings = {
    "ctrl+shift+c" = "copy_to_clipboard";
    "ctrl+shift+v" = "paste_from_clipboard";
    "shift+enter" = "send_text all \\x1b[13;2u";
    # "f1" = "set_colors --configured ~/.config/kitty/gruvbox-light.conf";
    # "f1" = "kitten theme.py";
    # "shift+f1" = "set_colors --configured ~/.config/kitty/gruvbox-dark.conf";
  };
  extraConfig = ''
    font_family      JetBrains Mono Regular Nerd Font Complete Mono
    bold_font        JetBrains Mono Bold Nerd Font Complete Mono
    italic_font      JetBrains Mono Italic Nerd Font Complete Mono
    bold_italic_font JetBrains Mono Bold Italic Nerd Font Complete Mono
    font_size 13.0
    disable_ligatures cursor
    cursor_blink_interval 0
    enable_audio_bell no
    cursor_text_color background

    allow_remote_control socket-only
    listen_on unix:/tmp/kitty

    include theme.conf
  '';
}
