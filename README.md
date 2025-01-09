Put this script where you want (for instance `/usr/local/bin`) and make it executable by running `chmod +x rotate.sh`

You might have to slightly modifiy it to fit your configuration, especially the lines
`for device in "Wacom Pen and multitouch sensor Finger" "SynPS/2 Synaptics TouchPad" "Wacom Pen and multitouch sensor Pen Pen (0x9ecce51e)"`
should be modified accordingly to the output of 
`xinput --list`

Then just run it at startup in the way you want it, e.g. adding 
`exec ./rotation.sh &`
in your .xsession file, or better, make it a systemctl service.

Tested on a Lenovo X390 Yoga, it works nicely.
