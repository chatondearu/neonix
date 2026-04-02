# Config rAudio USB input
see: https://github.com/rern/rAudio

## by USB with USB Behringer U-Control UCA202/UCA222 

Set the service Alsa to root the sound to the I2S Amp

Write the config file for the loopback service:
`nano /etc/systemd/system/alsaloop.service`

```ini,toml
[Unit]
Description=ALSA Loopback Service (USB to I2S)
After=sound.target

[Service]
Type=simple
ExecStart=/usr/bin/alsaloop -C plughw:1,0 -P plughw:0,0 -t 50000
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload
systemctl restart alsaloop.service
```

To stop the loopback and restore the default rooting of rAudio to the I2S amp (to use DLNA or Airplay features)
`systemctl stop alsaloop.service`

And to reverse
`systemctl start alsaloop.service`

### Virtual mixer

dmix will say to Alsa to use a virtual mixer to avoid the blocking of the access to the I2S amp
If we want to use a software mixer we can write where `CODEC` is the usb card:
`ExecStart=/usr/bin/alsaloop -C plughw:CODEC,0 -P default -t 50000`

Say to Alsa to globaly use the dmix by creating or editing `nano /etc/asound.conf`

and add this block
```
pcm.!default {
    type plug
    slave.pcm "dmix:sndrpimerusamp"
}

ctl.!default {
    type hw
    card sndrpimerusamp
}
```

for MDP, add this configuration in the config file `/etc/mpd.conf`

```
audio_output {
        type            "alsa"
        name            "Merus Audio Amp"
        device          "default"
}
```

and be sure to replace every `hw:ID,0` by `default`

`grep -rn "hw:1,0" /etc/ /srv/`

```bash
systemctl daemon-reload
systemctl start alsaloop.service
systemctl enable alsaloop.service
systemctl restart mpd.service
```

### Usefull commands:

set the volume of the devices
`alsamixer -c <card number: 0>`

save the settings
`alsactl store`


## Note

to access the rAudio ssh `ssh root@<IP>` with default password `ros`