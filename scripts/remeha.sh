#!/usr/bin/bash

logfile=/mnt/ExtraDisk/CAN/remehacan-$(date "+%Y%m%d-%H%M%S").log

power="0"
pressure="0"
flowtemperature="0.0"
setpoint="0.0"
toggle="0"
status="254"
statustext="unknown"
remeha_date="1984-01-01"
remeha_time="00:00:00"

debug="0"

function hex2int {
  hex=`echo $(tac -s ' ' <<< $*) | sed 's/[[:space:]]//g'`
  echo $((16#$hex))
}

while read logline; do
  ignore=0
  line=${logline#*)}
  line=$(echo ${line:6})
  canid=${line:0:3}
  case $canid in
    100)
      # Date and time. First the date...
      dateint=$(hex2int ${line:19})
      remeha_date=$(date -d "1984-01-01 + $dateint days" +"%Y-%m-%d")

      # Time.
      timeseconds=$(( $(hex2int ${line:8:11}) / 1000))
      remeha_time=$(date -d@$timeseconds -u +%H:%M:%S)
      ;;

    282)
      # Power and flow temperature
      power=$(hex2int ${line:8:2})
      tempint=$(( $(hex2int ${line:11:5}) / 10))
      tempint=$(printf "%02d" $tempint)
      # Flow temperature needs to be divided by 10. We fake this by just placing a dot before the last character.
      flowtemperature=${tempint:0:(-1)}.${tempint:(-1):1}
      ;;

    382)
      # Setpoint
      tempint=$(( $(hex2int ${line:11:5}) / 10))
      tempint=$(printf "%02d" $tempint)
      # Setpoint is also a temperature; needs to be divided by 10.
      setpoint=${tempint:0:(-1)}.${tempint:(-1):1}
      ;;

    1C1)
      # Contains a lot of things in multiple lines, including pressure. I could not figure out any other reliable way to
      # determine which line with CAN ID 1C1 to use other than using the line before the one containing the pressure to
      # "signal" that the next line should be used...
      if [[ "$toggle" == "1" ]]; then
        toggle="0"
        pressureint=$(hex2int ${line:23:2})
        # Pressure also needs to be divided by 10.
        pressureint=$(printf "%02d" $pressureint)
        pressure=${pressureint:0:(-1)}.${pressureint:(-1):1}
      else
        ignore=1
        toggle_indicator=${line:8:8}
        if [[ "$toggle_indicator" == "41 3F 50" ]]; then
          toggle="1"
        fi
      fi
      ;;

    481)
      # Status.
      status=$(hex2int ${line:8:2})
      case $status in
        0)
          statustext="stand-by"
          ;;
        1)
          statustext="demand"
          ;;
        2)
          statustext="start generator"
          ;;
        3)
          statustext="heat active"
          ;;
        4)
          statustext="dhw active"
          ;;
        5)
          statustext="stop generator"
          ;;
        6)
          statustext="pump active"
          ;;
        8)
          statustext="delay"
          ;;
        9)
          statustext="block"
          ;;
        10)
          statustext="lock"
          ;;
        11)
          statustext="test heat min"
          ;;
        12)
          statustext="test heat max"
          ;;
        13)
          statustext="test DWH max"
          ;;
        15)
          statustext="manual heat"
          ;;
        16)
          statustext="frost protection"
          ;;
        19)
          statustext="reset"
          ;;
        21)
          statustext="paused"
          ;;
        200)
          statustext="service mode"
          ;;
        *)
          statustext="unknown"
          ;;
      esac
      ;;

    *)
      # Ignore any other CAN IDs.
      ignore=1
      ;;
  esac
  if [[ "$ignore" == "0" ]]; then
    outputline="{\"datetime\":\"$remeha_date $remeha_time\","
    outputline+="\"statusid\":\"$status\","
    outputline+="\"statusdescription\":\"$statustext\","
    outputline+="\"flowtemperature\":$flowtemperature,"
    outputline+="\"setpoint\":$setpoint,"
    outputline+="\"power\":$power,"
    outputline+="\"pressure\":$pressure}"
    echo $outputline > $1
    if [[ "$debug" != "0" ]]; then
      echo $logline >> $logfile
    fi
  fi
done
