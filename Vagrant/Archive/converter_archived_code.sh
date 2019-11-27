echo "Vagrant already up, starting inline provisioning"
####DEFINE IP ADDRESS FOR EACH INTERFACE
declare -a swpNames
declare -a provisionText
declare -a everyServerIpAddress
currentLetter=A
serverIp="10.32.!0.@"
torIp="192.168.!0.@"
inc="1"
for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
  ####creates an ip address for each in between tor conection, if required
  currentName=tor-$currentLetter
  if [[ $switchMode != 1 ]]; then
    currentServerIp=`echo $serverIp | sed "s/!/$everyTor/g"`
  else
    currentServerIp="192.168.10.@"
  fi

    if [[ $tor != 1 ]]; then
      if [[ $everyTor == 1 ]]; then
        if [[ $switchMode != 1 ]]; then
          currentTorIp=`echo $torIp | sed "s/!/$everyTor/g"`
          intraTorIp=`echo $currentTorIp | sed "s/@/50/g"`
          echo "provisioning machine tor-$currentLetter adding ip to swp50"
          vagrant ssh tor-$currentLetter -c "sudo ifconfig swp50 $intraTorIp up" > /dev/null 2>&1
        else
          echo "provisioning machine tor-$currentLetter ip 0 to swp50"
          vagrant ssh tor-$currentLetter -c "sudo ifconfig swp50 0 " > /dev/null 2>&1
          echo "provisioning machine tor-$currentLetter installing and adding bridge"
          vagrant ssh tor-$currentLetter -c "sudo apt-get install bridge-utils; sudo brctl addbr TOR; sudo brctl addif TOR swp50" > /dev/null 2>&1
        fi

      elif [[ $everyTor == $tor ]]; then
        if [[ $switchMode != 1 ]]; then
          currentTorIp=`echo $torIp | sed "s/!/$((everyTor-1))/g"`
          intraTorIp=`echo $currentTorIp | sed "s/@/49/g"`
          echo "provisioning machine tor-$currentLetter adding ip $intraTorIp to swp49"
          vagrant ssh tor-$currentLetter -c "sudo ifconfig swp49 $intraTorIp up" > /dev/null 2>&1
        else
          echo "provisioning machine tor-$currentLetter adding ip 0 to swp49"
          vagrant ssh tor-$currentLetter -c "sudo ifconfig swp49 0  " > /dev/null 2>&1
          echo "provisioning machine tor-$currentLetter installing and adding bridge"
          vagrant ssh tor-$currentLetter -c "sudo apt-get install bridge-utils; sudo brctl addbr TOR; sudo brctl addif TOR swp49" > /dev/null 2>&1
        fi
      else
        if [[ $switchMode != 1 ]]; then
          currentTorIp=`echo $torIp | sed "s/!/$everyTor/g"`
          pastTorIp=`echo $torIp | sed "s/!/$((everyTor-1))/g"`
          intraTorIp50=`echo $currentTorIp | sed "s/@/50/g"`
          intraTorIp49=`echo $pastTorIp | sed "s/@/49/g"`
          echo "provisioning machine tor-$currentLetter adding ip $intraTorIp50 to swp50"
          vagrant ssh tor-$currentLetter -c "sudo ifconfig swp50 $intraTorIp50 up" > /dev/null 2>&1
          echo "provisioning machine tor-$currentLetter adding ip to swp49"
          vagrant ssh tor-$currentLetter -c "sudo ifconfig swp49 $intraTorIp49 up" > /dev/null 2>&1
        else
          echo "provisioning machine tor-$currentLetter adding ip 0 to swp50"
          vagrant ssh tor-$currentLetter -c "sudo ifconfig swp50 0  " > /dev/null 2>&1
          echo "provisioning machine tor-$intraTorIp adding ip 0 to swp49"
          vagrant ssh tor-$currentLetter -c "sudo ifconfig swp49 0  " > /dev/null 2>&1
          echo "provisioning machine tor-$currentLetter installing and adding bridge"
          vagrant ssh tor-$currentLetter -c "sudo apt-get install bridge-utils; sudo brctl addbr TOR; sudo brctl addif TOR swp49; sudo brctl addif TOR swp50;" > /dev/null 2>&1
        fi
      fi
    fi

    ####creates an ip address for each Tor to Server interface
    if [[ $switchMode != 1 ]]; then
      unset swpNames
      for (( everyServer=0; everyServer < $server+1; everyServer++)); do
        oneServerIp=`echo $currentServerIp | sed "s/@/$((everyServer*2))/g"`
        swpNames+="$oneServerIp "
      done
      read -a swpArray <<< $swpNames
      provisionText="vagrant ssh tor-$currentLetter -c \""
      for (( everyServer=1; everyServer < $server+1; everyServer++)); do
        echo "vagrant ssh tor-$currentLetter -c \"sudo ifconfig swp$everyServer ${swpArray[$everyServer]} up\""
        vagrant ssh tor-$currentLetter -c "sudo ifconfig swp$everyServer ${swpArray[$everyServer]} up" > /dev/null 2>&1
        echo "done"
      done
    else
      if [[ $tor == 1 ]]; then
        echo "provisioning machine tor-$currentLetter installing and adding bridge"
        vagrant ssh tor-$currentLetter -c "sudo apt-get install bridge-utils; sudo brctl addbr TOR" > /dev/null 2>&1
      fi
      provisionText="vagrant ssh tor-$currentLetter -c \""
      for (( everyServer=1; everyServer < $server+1; everyServer++)); do
        echo "vagrant ssh tor-$currentLetter -c \"sudo ifconfig swp$everyServer 0 \""
        vagrant ssh tor-$currentLetter -c "sudo ifconfig swp$everyServer 0 ; sudo brctl addif TOR swp$everyServer " > /dev/null 2>&1
        echo "done"
      done
      vagrant ssh tor-$currentLetter -c "sudo ifconfig TOR up;"
    fi



  ####creates an ip address for each Server to Tor interface
  unset swpNames
  for (( everyServer=0; everyServer < $server+1; everyServer++)); do
    inc=$((inc+1))
    oneServerIp=`echo $currentServerIp | sed "s/@/$inc/g"`
    swpNames+="$oneServerIp "
  done
    read -a swpArray <<< $swpNames
    provisionText="vagrant ssh tor-$currentLetter -c \""
  for (( everyServer=1; everyServer < $server+1; everyServer++)); do
    echo "vagrant ssh server-$currentLetter$((everyServer-1)) -c \"sudo ifconfig eth1 ${swpArray[$everyServer]} up\""
    vagrant ssh server-$currentLetter$((everyServer-1)) -c "sudo ifconfig eth1 ${swpArray[$everyServer]} up" > /dev/null 2>&1
    everyServerIpAddress+=("${swpArray[$everyServer]} server-$currentLetter$((everyServer-1))")
    echo "done"
  done

  currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
done


currentLetter=A
arraySize=${#everyServerIpAddress[@]}
for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
  for (( everyServer=0; everyServer < $server; everyServer++)); do
    for (( everyLine=0; everyLine < $arraySize; everyLine++)); do
        vagrant ssh server-$currentLetter$everyServer -c " echo ${everyServerIpAddress[everyLine]} | sudo tee -a /etc/hosts"
    done;
  done;
currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
done;
