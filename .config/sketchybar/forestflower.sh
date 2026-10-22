# Forest Flower palette for SketchyBar.
# Source this file. It reads macOS appearance and sets FF_* to 0xAARRGGBB.
#
# Night is AppleInterfaceStyle=Dark. Day is the key being absent.

if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
  FF_MODE=night
  FF_BAR=0xff000000
  FF_FG=0xffd0dac9
  FF_CHEVRON=0xff575653
  FF_CLOCK=0xff3aa99f
  FF_VOLUME=0xff4385be
  FF_BATTERY=0xffd0a215
  FF_MEDIA=0xff8b7ec8
  FF_ACCENT=0xfffbc701
  FF_ON_ACCENT=0xff000000
  FF_DANGER=0xffff9786
  FF_ACTIVE_BG=0xfffbc701
  FF_ACTIVE_FG=0xff000000
  FF_OCC_FG=0xffd0dac9
  FF_SELECTION=0xff1d2112
else
  FF_MODE=day
  FF_BAR=0xfff3f8ef
  FF_FG=0xff363e30
  FF_CHEVRON=0xff6f6e69
  FF_CLOCK=0xff24837b
  FF_VOLUME=0xff205ea6
  FF_BATTERY=0xffad8301
  FF_MEDIA=0xff5e409d
  FF_ACCENT=0xff705800
  FF_ON_ACCENT=0xfff3f8ef
  FF_DANGER=0xff942921
  FF_ACTIVE_BG=0xff705800
  FF_ACTIVE_FG=0xfff3f8ef
  FF_OCC_FG=0xff363e30
  FF_SELECTION=0xffccd6b9
fi
