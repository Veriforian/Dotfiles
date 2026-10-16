# Overrides Omarchy's default/themed/foot.ini.tpl (copied from Omarchy 4.0, 2026-10-16).
# Only change: the terminal background (and ANSI black / cursor text, which
# Omarchy ties to it) is darker than the theme's background, for every theme.
#   mix background -> darker_background: 50% ~ 20% darker, 75% ~ 30%, 100% ~ 40%
#   (One Dark Pro: #282c34 -> #1c1f24 at 75%). Change all three together.
# Re-render with: omarchy theme set "$(cat ~/.local/state/omarchy/current/theme.name)"
[colors-dark]
foreground={{ foreground_strip }}
background={{ mix_strip background darker_background 75% }}
selection-foreground={{ selection_foreground_strip }}
selection-background={{ selection_background_strip }}

cursor={{ mix_strip background darker_background 75% }} {{ bright_foreground_strip }}

regular0={{ mix_strip background darker_background 75% }}
regular1={{ red_strip }}
regular2={{ green_strip }}
regular3={{ yellow_strip }}
regular4={{ blue_strip }}
regular5={{ purple_strip }}
regular6={{ cyan_strip }}
regular7={{ foreground_strip }}

bright0={{ muted_strip }}
bright1={{ bright_red_strip }}
bright2={{ bright_green_strip }}
bright3={{ bright_yellow_strip }}
bright4={{ bright_blue_strip }}
bright5={{ bright_magenta_strip }}
bright6={{ bright_cyan_strip }}
bright7={{ bright_foreground_strip }}
