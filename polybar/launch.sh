#!/usr/bin/env sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -x polybar >/dev/null; do sleep 1; done

# Launch bar1 and bar2
polybar bottom &

outputs=$(xrandr -q | grep " connected" | cut -d ' ' -f1 | wc -l)
if [ $outputs == 2 ]
then
   polybar second &
fi

echo "Bars launched..."
