local terminal="alacritty"
local browser="/home/ajani/apps/zen/zen"
local files="thunar"
local launcher="vicinae toggle"

local screenshot_region="grim -g \"$(slurp)\" - | swappy -f -"
local screenshot_full="grim - | swappy -f -"

local mainMod="SUPER"

hl.monitor({ output="eDP-1", mode="1920x1080@144", position="auto", scale="1" })
hl.config({
  general={ gaps_in=4, gaps_out=10, resize_on_border=true, border_size=2, col={ active_border="rgba(333333ee)", inactive_border="rgba(333333aa)" } },
  animations={ enabled=false },
  dwindle={ preserve_split=true },
  misc={ force_default_wallpaper=-1, disable_hyprland_logo=true, disable_splash_rendering=true },
  input={ touchpad={ natural_scroll=true } },
  decoration={
    rounding=10, active_opacity=1.0, inactive_opacity=1.0, fullscreen_opacity=1.0,
    blur={ enabled=true, size=3, passes=4, ignore_opacity=true, xray=true }
  }
})

hl.monitor({
  output = "DP-1",
  mode = "1920x1080@144",
  position = "0x0",
  scale = 1,
})

hl.env("LIBVA_DRIVER_NAME","nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME","nvidia")
hl.env("XCURSOR_THEME","Breeze_Light")
hl.env("XCURSOR_SIZE","24")

hl.on("hyprland.start", function()
  hl.exec_cmd("vicinae server")
  hl.exec_cmd("quickshell")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("mako")
  hl.exec_cmd("hyprctl keyword layerrule blur, vicinae")
end)

-- Programs
hl.bind(mainMod.." + Return",hl.dsp.exec_cmd(terminal))
hl.bind(mainMod.." + B",hl.dsp.exec_cmd(browser))
hl.bind(mainMod.." + E",hl.dsp.exec_cmd(files))
hl.bind(mainMod.." + Space",hl.dsp.exec_cmd(launcher))
hl.bind(mainMod.." + D",hl.dsp.exec_cmd("vicinae vicinae://launch/applications"))
hl.bind(mainMod.." + SHIFT + M",hl.dsp.exit())
hl.bind(mainMod.." + S",hl.dsp.exec_cmd(screenshot_region))
hl.bind(mainMod.." + SHIFT + S",hl.dsp.exec_cmd(screenshot_full))
hl.bind(mainMod.." + SHIFT + Escape",hl.dsp.exec_cmd("pidof hyprlock || /home/ajani/.config/hypr/lockwall.sh"))

hl.bind(mainMod.." + CTRL + SHIFT + W",hl.dsp.exec_cmd([[p=$(find "$HOME/wallpapers" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) | shuf -n1) && awww img --transition-fps 144 --transition-type random "$p"; qs ipc call theme refresh]]))
hl.bind(mainMod.." + SHIFT + W",hl.dsp.exec_cmd("qs ipc call wallpapers toggle"))
hl.bind(mainMod.." + P",hl.dsp.exec_cmd("qs ipc call bar toggle"))
hl.bind(mainMod.." + C",hl.dsp.exec_cmd("vicinae vicinae://launch/clipboard/history"))

-- Windows
hl.bind(mainMod.." + F",hl.dsp.window.fullscreen({ mode="maximized", action="toggle" }))
hl.bind(mainMod.." + SHIFT + F",hl.dsp.window.fullscreen({ mode="fullscreen", action="toggle" }))
hl.bind(mainMod.." + Q",hl.dsp.window.close())
hl.bind(mainMod.." + W",hl.dsp.window.float({ action="toggle" }))

hl.bind(mainMod.." + left",hl.dsp.focus({ direction="left" }))
hl.bind(mainMod.." + right",hl.dsp.focus({ direction="right" }))
hl.bind(mainMod.." + up",hl.dsp.focus({ direction="up" }))
hl.bind(mainMod.." + down",hl.dsp.focus({ direction="down" }))
hl.bind(mainMod.." + h",hl.dsp.focus({ direction="left" }))
hl.bind(mainMod.." + l",hl.dsp.focus({ direction="right" }))
hl.bind(mainMod.." + k",hl.dsp.focus({ direction="up" }))
hl.bind(mainMod.." + j",hl.dsp.focus({ direction="down" }))
hl.bind(mainMod.." + SHIFT + h",hl.dsp.window.move({ direction="left" }))
hl.bind(mainMod.." + SHIFT + l",hl.dsp.window.move({ direction="right" }))
hl.bind(mainMod.." + SHIFT + j",hl.dsp.window.move({ direction="down" }))
hl.bind(mainMod.." + SHIFT + k",hl.dsp.window.move({ direction="up" }))

hl.bind("SUPER + TAB",hl.dsp.window.cycle_next(),{ description="Cycle windows" })

hl.bind("SUPER + T",function()
  local ws=hl.get_active_workspace()
  if not ws then return end
  if ws.tiled_layout=="scrolling" then hl.workspace_rule({ workspace=ws.id, layout="dwindle" }) else hl.workspace_rule({ workspace=ws.id, layout="scrolling" }) end
end,{ description="Toggle tiling / scrolling layout" })

-- Workspaces
for i=1,10 do
  local key=i%10
  hl.bind(mainMod.." + "..key,hl.dsp.focus({ workspace=i }))
  hl.bind(mainMod.." + SHIFT + "..key,hl.dsp.window.move({ workspace=i }))
end

hl.bind(mainMod.." + mouse_down",hl.dsp.focus({ workspace="e+1" }))
hl.bind(mainMod.." + mouse_up",hl.dsp.focus({ workspace="e-1" }))
hl.bind(mainMod.." + mouse:272",hl.dsp.window.drag(),{ mouse=true })
hl.bind(mainMod.." + mouse:273",hl.dsp.window.resize(),{ mouse=true })

-- Multimedia
hl.bind("XF86AudioRaiseVolume",hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),{ locked=true, repeating=true })
hl.bind("XF86AudioLowerVolume",hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),{ locked=true, repeating=true })
hl.bind("XF86AudioMute",hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),{ locked=true, repeating=true })
hl.bind("XF86AudioMicMute",hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),{ locked=true, repeating=true })
hl.bind("XF86MonBrightnessUp",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),{ locked=true, repeating=true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),{ locked=true, repeating=true })
hl.bind("XF86AudioNext",hl.dsp.exec_cmd("playerctl next"),{ locked=true })
hl.bind("XF86AudioPause",hl.dsp.exec_cmd("playerctl play-pause"),{ locked=true })
hl.bind("XF86AudioPlay",hl.dsp.exec_cmd("playerctl play-pause"),{ locked=true })
hl.bind("XF86AudioPrev",hl.dsp.exec_cmd("playerctl previous"),{ locked=true })

hl.gesture({ fingers=3, direction="horizontal", action="workspace" })

-- Window Rules
hl.window_rule({ name="suppress-maximize-events", match={ class=".*" }, suppress_event="maximize" })
hl.window_rule({ name="fix-xwayland-drags", match={ class="^$", title="^$", xwayland=true, float=true, fullscreen=false, pin=false }, no_focus=true })
-- hl.window_rule({ name="floating-terminal", match={ class="^(Alacritty)$" }, float=true, size={1400,1000} })
hl.window_rule({ name="floating-utilities", match={ class="^(thunar|mpv|blueman-manager|com.saivert.pwvucontrol)$" }, float=true, pin=true, size={800,600} })
hl.window_rule({ name="picture-in-picture", match={ title="^(Picture-in-Picture)$" }, float=true, pin=true, size={400,400} })


-- Keep fullscreen/video sharp
local blur_allowed = { "Alacritty" }
local pattern = "^(?!(" .. table.concat(blur_allowed, "|") .. ")$).*$"
hl.window_rule({ name="no-blur-others", match={ class=pattern }, no_blur=true })

-- vicinae blur
hl.layer_rule({ match = { namespace = "vicinae" }, name = "vicinae-blur", blur = true, ignore_alpha = 0, })

-- quickshell surfaces
-- hl.layer_rule({ match = { namespace = "qs-bar" }, name = "qs-bar-blur", blur = true, ignore_alpha = 0.2 })
-- hl.layer_rule({ match = { namespace = "qs-wallpapers" }, name = "qs-wallpapers-blur", blur = true, ignore_alpha = 0.0 })



