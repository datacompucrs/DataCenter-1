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
  for (( everySpine=0; everySpine < 2; everySpine++)); do
    currentLetter=A
    if [[ $everySpine == 0 ]]; then
      direction=L
    else
      direction=R
    fi
    for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
      currentName=tor-$direction$currentLetter
      currentServerIp="0"
      if [[ $everySpine == 0 ]]; then
        echo "spine swp$everyTor $constantZero" >> IP_List.txt
      else
        echo "spine swp$((tor+everyTor)) $constantZero" >> IP_List.txt
      fi
        echo "$currentName swp50 $constantZero" >> IP_List.txt
      for (( everyServer=1; everyServer < $server+1; everyServer++)); do
        echo "$currentName swp$everyServer $constantZero" >> IP_List.txt
      done
      for (( everyServer=1; everyServer < $server+1; everyServer++)); do
        echo "server-$direction$currentLetter$((everyServer-1)) eth1 $constantZero" >> IP_List.txt
      done
      currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
    done
  done
###################################################################################################################

elif  [[ $networkConfig == "2" ]]; then #Servers with IP, Tor without, except spine conection
  for (( everySpine=0; everySpine < 2; everySpine++)); do
    currentLetter=A
    if [[ $everySpine == 0 ]]; then
      direction=L
    else
      direction=R
    fi
    for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
      currentServerIp=`echo $serverIp | sed "s/!/1/g"`
      thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
      if [[ $everySpine == 0 ]]; then
        echo "spine swp$everyTor $thisServerIP" >> IP_List.txt
      else
        echo "spine swp$((tor+everyTor)) $thisServerIP" >> IP_List.txt
      fi
      currentName=tor-$direction$currentLetter
      echo "$currentName swp50 $constantZero" >> IP_List.txt
      inc=$((inc+1))
      for (( everyServer=1; everyServer < $server+1; everyServer++)); do
        echo "tor-$direction$currentLetter swp$everyServer $constantZero" >> IP_List.txt
      done
      for (( everyServer=1; everyServer < $server+1; everyServer++)); do
        thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
        echo "server-$direction$currentLetter$((everyServer-1)) eth1 $thisServerIP" >> IP_List.txt
        inc=$((inc+1))
      done
      currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
    done;
  done
###################################################################################################################

elif  [[ $networkConfig == "3" ]]; then #Servers with IP, Tor with Ip, spine with IP
  for (( everySpine=0; everySpine < 2; everySpine++)); do
    currentLetter=A
    if [[ $everySpine == 0 ]]; then
      direction=L
    else
      direction=R
    fi
    for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
      currentServerIp=`echo $serverIp | sed "s/!/1/g"`
      thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
      currentName=tor-$direction$currentLetter
      inc=$((inc+1))
      if [[ $everySpine == 0 ]]; then
        echo "spine swp$everyTor $thisServerIP" >> IP_List.txt
      else
        echo "spine swp$((tor+ everyTor)) $thisServerIP" >> IP_List.txt
      fi
      thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
      echo "$currentName swp50 $thisServerIP" >> IP_List.txt
      inc=$((inc+1))

      for (( everyServer=1; everyServer < $server+1; everyServer++)); do
        thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
        echo "$currentName swp$everyServer $thisServerIP" >> IP_List.txt
        inc=$((inc+1))
      done
      for (( everyServer=1; everyServer < $server+1; everyServer++)); do
        thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
        echo "server-$direction$currentLetter$((everyServer-1)) eth1 $thisServerIP" >> IP_List.txt
        inc=$((inc+1))
      done
      currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
    done
  done
  ###################################################################################################################

elif [[ $networkConfig == "4" ]]; then  #New IP for each enlace
spineport=1
for (( everySpine=0; everySpine < 2; everySpine++)); do
  currentLetter=A
  if [[ $everySpine == 0 ]]; then
    direction=L
  else
    direction=R
  fi
    for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
      inc="1"
      incTor="1"
      incIntraTor="2"
      if [[ $everySpine == 0 ]]; then
        currentTorIp=`echo $torIp | sed "s/!/$everyTor/g"`
        currentServerIp=`echo $serverIp | sed "s/!/$everyTor/g"`
        currentIntraTorIp=`echo $intraTorIp | sed "s/!/$everyTor/g"`
      else
        currentTorIp=`echo $torIp | sed "s/!/$((everyTor+tor))/g"`
        currentServerIp=`echo $serverIp | sed "s/!/$((everyTor+tor))/g"`
        currentIntraTorIp=`echo $intraTorIp | sed "s/!/$((everyTor+tor))/g"`
      fi
      currentName=tor-$direction$currentLetter
      for (( everyServer=1; everyServer < $server+1; everyServer++)); do
        thisTorIP=`echo $currentTorIp | sed "s/@/$((everyServer*2))/g"`
        echo "$currentName swp$everyServer $thisTorIP" >> IP_List.txt
      done
      for (( everyServer=1; everyServer < $server+1; everyServer++)); do
        thisTorIP=`echo $currentTorIp | sed "s/@/$(((everyServer*2)+1))/g"`
        echo "server-$direction$currentLetter$((everyServer-1)) eth1 $thisTorIP" >> IP_List.txt
      done
      if [[ $everySpine == 0 ]]; then
        currentTorIp=`echo $intraTorIp | sed "s/!/$((everyTor+(tor*2)))/g"`
        thisTorIP=`echo $currentTorIp | sed "s/@/1/g"`
        echo "$currentName swp50 $thisTorIP" >> IP_List.txt
        thisTorIP=`echo $currentTorIp | sed "s/@/2/g"`
        echo "spine swp$spineport $thisTorIP" >> IP_List.txt
        spineport=$((spineport+1))
      else
        currentTorIp=`echo $intraTorIp | sed "s/!/$(((everyTor)+(tor*3)))/g"`
        thisTorIP=`echo $currentTorIp | sed "s/@/1/g"`
        echo "$currentName swp50 $thisTorIP" >> IP_List.txt
        thisTorIP=`echo $currentTorIp | sed "s/@/2/g"`
        echo "spine swp$spineport $thisTorIP" >> IP_List.txt
        spineport=$((spineport+1))
      fi
      currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
    done
  done
###################################################################################################################

elif [[ $networkConfig == "5" ]]; then         #New IP only for servers
  spineport=1
  for (( everySpine=0; everySpine < 2; everySpine++)); do
    currentLetter=A
    if [[ $everySpine == 0 ]]; then
      direction=L
    else
      direction=R
    fi
      for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
        inc="1"
        incTor="1"
        incIntraTor="2"
        if [[ $everySpine == 0 ]]; then
          currentTorIp=`echo $torIp | sed "s/!/$everyTor/g"`
          currentServerIp=`echo $serverIp | sed "s/!/$everyTor/g"`
          currentIntraTorIp=`echo $intraTorIp | sed "s/!/$everyTor/g"`
        else
          currentTorIp=`echo $torIp | sed "s/!/$((everyTor+tor))/g"`
          currentServerIp=`echo $serverIp | sed "s/!/$((everyTor+tor))/g"`
          currentIntraTorIp=`echo $intraTorIp | sed "s/!/$((everyTor+tor))/g"`
        fi
        currentName=tor-$direction$currentLetter
        for (( everyServer=1; everyServer < $server+1; everyServer++)); do
          thisTorIP=`echo $currentTorIp | sed "s/@/$((everyServer*2))/g"`
          echo "$currentName swp$everyServer $constantZero" >> IP_List.txt
        done
        for (( everyServer=1; everyServer < $server+1; everyServer++)); do
          thisTorIP=`echo $currentTorIp | sed "s/@/$(((everyServer*2)+1))/g"`
          echo "server-$direction$currentLetter$((everyServer-1)) eth1 $thisTorIP" >> IP_List.txt
        done
        if [[ $everySpine == 0 ]]; then
          currentTorIp=`echo $intraTorIp | sed "s/!/$((everyTor+(tor*2)))/g"`
          thisTorIP=`echo $currentTorIp | sed "s/@/1/g"`
          echo "$currentName swp50 $constantZero" >> IP_List.txt
          thisTorIP=`echo $currentTorIp | sed "s/@/2/g"`
          echo "spine swp$spineport $thisTorIP" >> IP_List.txt
          spineport=$((spineport+1))
        else
          currentTorIp=`echo $intraTorIp | sed "s/!/$(((everyTor)+(tor*3)))/g"`
          thisTorIP=`echo $currentTorIp | sed "s/@/1/g"`
          echo "$currentName swp50 $constantZero" >> IP_List.txt
          thisTorIP=`echo $currentTorIp | sed "s/@/2/g"`
          echo "spine swp$spineport $thisTorIP" >> IP_List.txt
          spineport=$((spineport+1))
        fi
        currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
      done
    done
###################################################################################################################

else  #Servers with IP, Tor without, except spine conection, each half of spine have different ip
  incNetwork=1
  for (( everySpine=0; everySpine < 2; everySpine++)); do
    currentLetter=A
    inc=1
    currentServerIp=`echo $serverIp | sed "s/!/$incNetwork/g"`
    incNetwork=$((incNetwork+1))
    if [[ $everySpine == 0 ]]; then
      direction=L
    else
      direction=R
    fi
    for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
      currentName=tor-$direction$currentLetter
      thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
      if [[ $everySpine == 0 ]]; then
        echo "spine swp$everyTor $thisServerIP" >> IP_List.txt
      else
        echo "spine swp$((tor+everyTor)) $thisServerIP" >> IP_List.txt
      fi
      echo "$currentName swp50 $constantZero" >> IP_List.txt
      inc=$((inc+1))
      for (( everyServer=1; everyServer < $server+1; everyServer++)); do
        echo "tor-$direction$currentLetter swp$everyServer $constantZero" >> IP_List.txt
      done
      for (( everyServer=1; everyServer < $server+1; everyServer++)); do
        thisServerIP=`echo $currentServerIp | sed "s/@/$((inc))/g"`
        echo "server-$direction$currentLetter$((everyServer-1)) eth1 $thisServerIP" >> IP_List.txt
        inc=$((inc+1))
      done
      currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
    done;
  done

fi
