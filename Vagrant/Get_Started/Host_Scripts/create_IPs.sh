server=$1
tor=$2
networkConfig=$3

declare -a swpNames
declare -a provisionText
declare -a everyServerIpAddress
currentLetter=A
serverIp="1.1.!0.@"
torIp="2.2.!0.@"
intraTorIp="3.3.!0.@"
constantZero="0";
inc="1"

echo "" > IP_List.txt

cd ./Guest_Scripts/


if    [[ $networkConfig == "1" ]]; then #No Ip
  for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
    currentName=tor-$currentLetter
    currentServerIp="0"
    if [[ $tor != 1 ]]; then
      if [[ $everyTor == 1 ]]; then
        echo "tor-$currentLetter swp50 $constantZero" >> IP_List.txt
      elif [[ $everyTor == $tor ]]; then
        echo "tor-$currentLetter swp49 $constantZero" >> IP_List.txt
      else
        echo "tor-$currentLetter swp50 $constantZero" >> IP_List.txt
        echo "tor-$currentLetter swp49 $constantZero" >> IP_List.txt
      fi
    fi
    for (( everyServer=1; everyServer < $server+1; everyServer++)); do
      echo "tor-$currentLetter swp$everyServer $constantZero" >> IP_List.txt
    done
    for (( everyServer=1; everyServer < $server+1; everyServer++)); do
      echo "server-$currentLetter$((everyServer-1)) eth1 $constantZero" >> IP_List.txt
    done
    currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  done;
###################################################################################################################

elif  [[ $networkConfig == "2" ]]; then #Servers with IP, Tor without
  for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
    currentName=tor-$currentLetter
    currentServerIp=`echo $serverIp | sed "s/!/1/g"`
    if [[ $tor != 1 ]]; then
      if [[ $everyTor == 1 ]]; then
        echo "tor-$currentLetter swp50 $constantZero" >> IP_List.txt
      elif [[ $everyTor == $tor ]]; then
        echo "tor-$currentLetter swp49 $constantZero" >> IP_List.txt
      else
        echo "tor-$currentLetter swp50 $constantZero" >> IP_List.txt
        echo "tor-$currentLetter swp49 $constantZero" >> IP_List.txt
      fi
    fi
    for (( everyServer=1; everyServer < $server+1; everyServer++)); do
      echo "tor-$currentLetter swp$everyServer $constantZero" >> IP_List.txt
    done
    for (( everyServer=1; everyServer < $server+1; everyServer++)); do
      thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
      echo "server-$currentLetter$((everyServer-1)) eth1 $thisServerIP" >> IP_List.txt
      inc=$((inc+1))
    done
    currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  done;
###################################################################################################################

elif  [[ $networkConfig == "3" ]]; then #Servers with IP, Tor with Ip
  for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
    currentName=tor-$currentLetter
    currentServerIp=`echo $serverIp | sed "s/!/1/g"`
    if [[ $tor != 1 ]]; then
      if [[ $everyTor == 1 ]]; then
        thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
        echo "tor-$currentLetter swp50 $thisServerIP" >> IP_List.txt
        inc=$((inc+1))
      elif [[ $everyTor == $tor ]]; then
        thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
        echo "tor-$currentLetter swp49 $thisServerIP" >> IP_List.txt
        inc=$((inc+1))
      else
        thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
        echo "tor-$currentLetter swp50 $thisServerIP" >> IP_List.txt
        inc=$((inc+1))
        thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
        echo "tor-$currentLetter swp49 $thisServerIP" >> IP_List.txt
        inc=$((inc+1))
      fi
    fi
    for (( everyServer=1; everyServer < $server+1; everyServer++)); do
      thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
      echo "tor-$currentLetter swp$everyServer $thisServerIP" >> IP_List.txt
      inc=$((inc+1))
    done
    for (( everyServer=1; everyServer < $server+1; everyServer++)); do
      thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
      echo "server-$currentLetter$((everyServer-1)) eth1 $thisServerIP" >> IP_List.txt
      inc=$((inc+1))
    done
    currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  done;

  ###################################################################################################################

elif [[ $networkConfig == "4" ]]; then  #New IP for each enlace
  for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
    inc="1"
    incTor="1"
    incIntraTor="2"
    currentName=tor-$currentLetter
    currentTorIp=`echo $torIp | sed "s/!/$everyTor/g"`
    currentServerIp=`echo $serverIp | sed "s/!/$everyTor/g"`
    currentIntraTorIp=`echo $intraTorIp | sed "s/!/$everyTor/g"`
    if [[ $tor != 1 ]]; then
      if [[ $everyTor == 1 ]]; then
        thisTorIP=`echo $currentIntraTorIp | sed "s/@/1/g"`
        echo "tor-$currentLetter swp50 $thisTorIP" >> IP_List.txt
        incIntraTor=$((incIntraTor+1))
      elif [[ $everyTor == $tor ]]; then
        incIntraTor=$((incIntraTor-1))
        thisTorIP=`echo $intraTorIp | sed "s/!/$((everyTor-1))/g" | sed "s/@/2/g"`
        echo "tor-$currentLetter swp49 $thisTorIP" >> IP_List.txt
      else
        incIntraTor=$((incIntraTor+1))
        thisTorIP=`echo $currentIntraTorIp | sed "s/@/$((incIntraTor))/g"`
        echo "tor-$currentLetter swp50 $thisTorIP" >> IP_List.txt
        incIntraTor=$((incIntraTor-1))
        thisTorIP=`echo $intraTorIp | sed "s/!/$((everyTor-1))/g" | sed "s/@/$((incIntraTor))/g"`
        echo "tor-$currentLetter swp49 $thisTorIP" >> IP_List.txt
      fi
    fi
    for (( everyServer=1; everyServer < $server+1; everyServer++)); do
      thisTorIP=`echo $currentTorIp | sed "s/@/$((everyServer*2))/g"`
      echo "tor-$currentLetter swp$everyServer $thisTorIP" >> IP_List.txt
    done
    for (( everyServer=1; everyServer < $server+1; everyServer++)); do
      thisTorIP=`echo $currentTorIp | sed "s/@/$(((everyServer*2)+1))/g"`
      echo "server-$currentLetter$((everyServer-1)) eth1 $thisTorIP" >> IP_List.txt
    done
    currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  done;

else         #New IP only for servers

  for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
    inc="1"
    incTor="1"
    incIntraTor="2"
    currentName=tor-$currentLetter
    currentTorIp=`echo $torIp | sed "s/!/$everyTor/g"`
    currentServerIp=`echo $serverIp | sed "s/!/$everyTor/g"`
    currentIntraTorIp=`echo $intraTorIp | sed "s/!/$everyTor/g"`
    if [[ $tor != 1 ]]; then
      if [[ $everyTor == 1 ]]; then
        thisTorIP=`echo $currentIntraTorIp | sed "s/@/1/g"`
        echo "tor-$currentLetter swp50 $constantZero" >> IP_List.txt
        incIntraTor=$((incIntraTor+1))
      elif [[ $everyTor == $tor ]]; then
        incIntraTor=$((incIntraTor-1))
        thisTorIP=`echo $intraTorIp | sed "s/!/$((everyTor-1))/g" | sed "s/@/2/g"`
        echo "tor-$currentLetter swp49 $constantZero" >> IP_List.txt
      else
        incIntraTor=$((incIntraTor+1))
        thisTorIP=`echo $currentIntraTorIp | sed "s/@/$((incIntraTor))/g"`
        echo "tor-$currentLetter swp50 $constantZero" >> IP_List.txt
        incIntraTor=$((incIntraTor-1))
        thisTorIP=`echo $intraTorIp | sed "s/!/$((everyTor-1))/g" | sed "s/@/$((incIntraTor))/g"`
        echo "tor-$currentLetter swp49 $constantZero" >> IP_List.txt
      fi
    fi
    for (( everyServer=1; everyServer < $server+1; everyServer++)); do
      thisTorIP=`echo $currentTorIp | sed "s/@/$((everyServer*2))/g"`
      echo "tor-$currentLetter swp$everyServer $constantZero" >> IP_List.txt
    done
    for (( everyServer=1; everyServer < $server+1; everyServer++)); do
      thisTorIP=`echo $currentTorIp | sed "s/@/$((everyServer))/g"`
      echo "server-$currentLetter$((everyServer-1)) eth1 $thisTorIP" >> IP_List.txt
    done
    currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  done;

fi
