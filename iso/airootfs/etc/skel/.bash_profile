# NuitOS live session: jump straight into Hyprland on the first console.
# The live ISO autologins `nuitos` on tty1 (getty override) with no display
# manager at all — no login screen when trying the OS. Installed systems use
# LightDM+slick (written by nuit-installer) — this stanza only fires for
# the live user, never for installed users.
if [ "${USER:-}" = "nuitos" ] && [ -z "${WAYLAND_DISPLAY:-}" ] && [ "${XDG_VTNR:-}" = 1 ]; then
  exec Hyprland
fi
