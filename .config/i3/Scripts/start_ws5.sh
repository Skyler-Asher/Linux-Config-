#!/bin/sh
# create workspace 5 layout, then spawn 3 kitty windows that get swallowed
i3-msg "workspace 5; append_layout \"$HOME/.config/i3/layouts/ws5.json\""
sleep 0.15
kitty --class kitty &
sleep 0.12
kitty --class kitty &
sleep 0.12
kitty --class kitty &


