#!/bin/bash
# https://serverfault.com/a/767361/152358
# https://gist.github.com/mnebuerquo/e825530cf2bfd363b6c3cd82fe697d94
set -eu
displays=$(ps aux | grep Xorg | grep -v 'grep\|sed' | sed -r 's|.*(Xorg :[0-9]*).*|\1|' | cut -d' ' -f 2)

if [ -z $IDLETIME ]; then
  limit=$IDLETIME
else
  limit=30
fi

date
echo "Checking for inactive sessions!"
while read -r d; do
	export DISPLAY=$d
	idle=$(xprintidle)
	idleMins=$(($idle/1000/60))
	if [[ $idleMins -gt $limit ]]; then
		echo "WARN Display $d is logged in for longer than ${limit}min (${idleMins}m)"
		PID=$(pgrep -f "Xorg $d")
		echo "Killing $d ($PID)"
		kill -HUP $PID
		# http://linuxtoolkit.blogspot.com/2013/03/xrdpmmprocessloginresponse-login-failed.html
		FNAME=$(echo $d | sed -e 's/:/X/g')
		FILENAME="/tmp/.X11-unix/$FNAME"
		echo "Removing session for $d ($FILENAME)"
		rm -f $FILENAME
	else
		echo "INFO Display $d is still ok (${idleMins}m)"
	fi
done <<< "$displays"
