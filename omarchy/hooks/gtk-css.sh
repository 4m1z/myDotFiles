#!/bin/bash
# Sync the staged theme's gtk.css (Nautilus/GTK colors) to GTK config.
# Called by omarchy-hook theme-set with the new theme slug as $1.
# Themes without gtk.css (e.g. stock themes) clear a stale link so
# Adwaita-dark returns instead of a previous custom theme lingering.

staged="$HOME/.local/state/omarchy/current/theme/gtk.css"

for target in "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"; do
  mkdir -p -- "$(dirname -- "$target")"
  if [[ -f $staged ]]; then
    ln -snf -- "$staged" "$target"
  else
    # Only remove links we manage; never delete a user-written gtk.css.
    if [[ -L $target ]]; then
      rm -f -- "$target"
    fi
  fi
done

# Nautilus (GTK4/libadwaita) picks up gtk.css on next launch.
if command -v nautilus >/dev/null 2>&1; then
  nautilus -q 2>/dev/null || true
fi
