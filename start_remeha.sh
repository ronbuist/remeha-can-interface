#!/usr/bin/bash

tmpdir=/run/remeha
tmpfile=remeha.json

function echolog {
  echo `date`: $*
}

candumppid=`ps aux|grep candump|grep can0|xargs|cut -d" " -f2`
if [[ "$candumppid" != "" ]]; then
  echolog Candump already running on PID $candumppid. Nothing to do...
  exit
fi

if [ -d $tmpdir ]; then
  if [ -w $tmpdir ]; then
    echolog Directory "$tmpdir" exists and is writable for `whoami`.
    sudo rm -f $tmpdir/$tmpfile
  else
    echolog Directory "$tmpdir" exists but is not writable for `whoami`. Fixing...
    sudo rm -rf $tmpdir
    sudo mkdir $tmpdir
    sudo chown `whoami`: $tmpdir
  fi
else
  echolog Directory "$tmpdir" does not exist. Creating...
  sudo mkdir $tmpdir
  sudo chown `whoami`: $tmpdir
fi


canstatus=`/usr/sbin/ifconfig | grep can0 | grep UP | wc -l`
if [[ "$canstatus" == "0" ]]; then
  echolog CAN interface is down. Bringing it up...
  sudo ip link set dev can0 up type can bitrate 1000000
fi

echolog Starting RemehaCAN
candump can0 -tz | ~/scripts/remeha.sh $tmpdir/$tmpfile &
sleep 2
candumppid=`ps aux|grep candump|grep can0|xargs|cut -d" " -f2`
if [[ "$candumppid" != "" ]]; then
  echolog Remeha CAN logger started on PID $candumppid
else
  echolog Could not start Remeha CAN logger...
fi
