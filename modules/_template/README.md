# Module interface contract (NuitOS-exp).
#
# modules/<id>/
#   module.conf    REQUIRED  id/provides/requires/conflicts/description.
#                              assemble.sh refuses two modules with the same
#                              provides= value (e.g. two provides=bar).
#   packages.list  REQUIRED  official-repo pkgs only, one per line.
#                              AUR -> customize_airootfs.sh vendor hook.
#   skel/          OPTIONAL  mirrors etc/skel/.config/... (dotfiles).
#                              compositor-hyprland exposes
#                              ~/.config/hypr/modules/*.conf includes, so most
#                              modules only drop a fragment there.
#   system/        OPTIONAL  mirrors airootfs/{etc,usr}/... (greeter theme,
#                              plymouth theme, .desktop files, schemas).
#   enable         OPTIONAL  executable, runs at build to write generated
#                              seams (bar-launch.conf, terminal.env, ...).
#                              Must read ../../DESIGN.json for tokens.
#   install-hook   OPTIONAL  bash fragment sourced by nuit-installer to copy
#                              payload + write chroot config for this module.
#   DESIGN.tokens  OPTIONAL  partial JSON merged over root DESIGN.json.
#   README.md      REQUIRED  what it swaps, what binds it consumes.
#
# Profiles (profiles/*.list) choose the module set. build/assemble.sh
# concatenates packages.list in profile order into
# iso/packages.x86_64.generated and merges skel/ + system/ into a staging
# airootfs for review before calling mkarchiso.
