#!/bin/sh
#############
###<Notes>###
#############
# This script depends on screen.
# For the stop function to work, you must set an
# explicit session directory using absolute paths in your rtorrent.rc.
# If you typically just start rtorrent with just "rtorrent" on the
# command line, all you need to change is the "user" option.
# Attach to the screen session as your user with 
# "screen -dr rtorrent". Change "rtorrent" with srnname option.
# If you are running multiple instances of rtorrent,
# all options should be made respective to one another. so the first option for
# config should be related to the same first option for options.
##############
###</Notes>###
##############


#######################
##Start Configuration##
#######################
# system user to run as (can only use one)
user=user

# config file(s) separate multiple with newlines
config="/home/$user/.rtorrent.rc"

#set of options to run with each instance, separated by a new line
options=""
# Examples:
# starts one instance, sourcing both .rtorrent.rc and .rtorrent2.rc
# options="-o import=~/.rtorrent2.rc"
# starts two instances, ignoring .rtorrent.rc for both, and using
# .rtorrent2.rc for the first, and .rtorrent3.rc for the second
# we do not check for valid options
# options="-n -o import=~/.rtorrent2.rc
# -n -o import=rtorrent3.rc"

# default directory for screen, needs to be an absolute path
base=/home/${user}

# name of screen session, no whitespace allowed
srnname=rtorrent
#######################
###END CONFIGURATION###
#######################
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DESC="rtorrent"
NAME=rtorrent
DAEMON=/usr/bin/$NAME
SCRIPTNAME=/etc/init.d/$NAME

# Gracefully exit if the package has been removed.
test -x $DAEMON || exit 0

checkcnfg() {
  OLDIFS="$IFS"
  IFS=$'\n'
  for i in $config ; do
  	session=$(cat "$i" | grep "^[[:space:]]*session" | sed "s/^[[:space:]]*session[[:space:]]*=[[:space:]]*//")
	if ! [ -r $i ] ; then
		echo "cannot find readable config $i. check that it is there and permissions are appropriate">&2
		exit 3
	elif ! [ -r $session ] ; then
		echo "cannot find readable session directory $i. check permissions">&2
		exit 3
	fi
  done
  IFS="$OLDIFS"
}

d_start() {
  [ -d "$base" ] && cd "$base"
  stty stop undef && stty start undef
  su -c "screen -ls | grep "\.${srnname}[[:space:]]" > /dev/null" $user || su -c "screen -dm -S $srnname" $user
  OLDIFS="$IFS"
  IFS=$'\n'
  if [ -z "$options" ] ; then
  	sleep 3
  	su -c "screen -S $srnname -X screen rtorrent" $user
  else
	  for option in $options ; do
  		sleep 3
		su -c "screen -S $srnname -X screen rtorrent $option" $user
	  done
  fi
  IFS="$OLDIFS"
}

d_stop() {
  OLDIFS="$IFS"
  IFS=$'\n'
  for i in $config ; do
  	session=$(cat "$i" | grep "^[[:space:]]*session" | sed "s/^[[:space:]]*session[[:space:]]*=[[:space:]]*//")
	pid=$(cat ${session}/rtorrent.lock | sed "s/[^0-9]//g")
	# make sure the pid doesn't belong to another process
	# skip the pid otherwise
	if ps -A | grep ${pid}.*rtorrent > /dev/null ; then
		kill -s INT $pid
	fi
  done
  IFS="$OLDIFS"
}

checkcnfg

case "$1" in
  start)
	echo -n "Starting $DESC: $NAME"
	d_start
	echo "."
	;;
  stop)
	echo -n "Stopping $DESC: $NAME"
	d_stop
	echo "."
	;;
  restart|force-reload)
	echo -n "Restarting $DESC: $NAME"
	d_stop
	sleep 1
	d_start
	echo "."
	;;
  *)
	echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
	exit 1
	;;
esac

exit 0
