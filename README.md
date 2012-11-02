# tlassemble

###Building and Installation
```bash
git clone https://github.com/dbridges/cocoa-tlassemble.git
cd cocoa-tlassemble
make
sudo cp tlassemble /usr/local/bin/
```

###Usage
tlassemble INPUTDIRECTORY OUTPUTFILENAME [OPTIONS]

###Examples
tlassemble ./images time_lapse.mov
tlassemble ./images time_lapse.mov -fps 30 -height 720 -codec h264 -quality high
tlassemble ./images time_lapse.mov -quiet yes

###Options
-fps: Frames per second for final movie can be anywhere between 0.1 and 60.0.
-height: If specified images are resized proportionally to height given.
-codec: Codec to use to encode can be 'h264' 'photojpeg' 'raw' or 'mpv4'.
-quality: Quality to encode with can be 'high' 'normal' 'low'.
-quiet: Set to 'yes' to suppress output during encoding.
-reverse: Set to 'yes' to reverse the order that images are displayed in the movie.

