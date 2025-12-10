printf 'context.modules = [
  {   name = libpipewire-module-alsa-card
      args = {
        device.nick = "ALC662 Analog Fix"
        card = 0
        profile = "output:analog-stereo+input:analog-stereo"
      }
  }
]' > ~/.config/pipewire/pipewire.conf.d/99-force-analog.conf

