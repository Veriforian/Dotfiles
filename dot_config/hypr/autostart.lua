-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Vesktop in the tray, so Discord presence is up from login (CustomIdle in
-- ~/.config/vesktop/settings/settings.json keeps it from going idle).
o.launch_on_start("vesktop --start-minimized")
