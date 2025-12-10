#!/bin/bash
# Force HDA Intel PCH to analog stereo
pactl set-card-profile alsa_card.pci-0000_00_1b.0 output:analog-stereo
pactl set-default-sink alsa_output.pci-0000_00_1b.0.analog-stereo

