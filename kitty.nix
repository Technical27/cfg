{
  keybindings = {
    "ctrl+shift+c" = "copy_to_clipboard";
    "ctrl+shift+v" = "paste_from_clipboard";
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

    foreground #ebdbb2
    background #282828

    cursor #ebdbb2

    color0 #1d2021
    color8 #928374

    color1 #cc241d
    color9 #fb4934

    color2 #98971a
    color10 #b8bb26

    color3 #d79921
    color11 #fabd2f

    color4 #458588
    color12 #83a698

    color5 #b16286
    color13 #d3869b

    color6 #689d6a
    color14 #8ec07c

    color7 #a89984
    color15 #ebdbb2

    active_tab_foreground #282828
    active_tab_background #3c3836
    inactive_tab_foreground #ebdbb2
    inactive_tab_background #282828

    active_border_color #ebdbb2
    inactive_border_color #282828
    bell_border_color #cc241d
    shell_integration disabled
    confirm_os_window_close -1

    linux_display_server wayland
    wayland_titlebar_color background
  '';
}
