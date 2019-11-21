everyCommand=$*
read -a commandArray <<< $everyCommand
sizeArray=${#commandArray[@]}

####define empty variables for comparision
server=""
tor=""
memory=""
os=""
version=""
destroy=""
switchMode=""
commandList=""
standart=""

####HELP TEXT
if [[ $1 == --help ]]; then
  echo -e "-s server -- number of servers\n-t tor -- number of tors\n-m memory -- memory alocation\n-o os -- operation system\n-v version -- os version"
  echo -e "-d destroy -- destroys topology after iteration\n-sw switch -- does not provide ip to swp\n-c commands -- uses a bash file to provide a list of commands"
  echo "-st standart -- uses a txt file to have standart inputs"
  exit
fi

####CHECK EVERY ARGUMENT TO FILL SERVER, TOR, ETC, VARIABLES
for (( everyCommand=0; everyCommand < $sizeArray; everyCommand=everyCommand+1)); do
  if [[ ${commandArray[$everyCommand]} == -s ]]; then
    server=${commandArray[$everyCommand+1]}

  fi
  if [[ ${commandArray[$everyCommand]} == -t ]]; then
    tor=${commandArray[$everyCommand+1]}
  fi

  if [[ ${commandArray[$everyCommand]} == -m ]]; then
    memory=${commandArray[$everyCommand+1]}
  fi

  if [[ ${commandArray[$everyCommand]} == -o ]]; then
    os=${commandArray[$everyCommand+1]}
  fi

  if [[ ${commandArray[$everyCommand]} == -v ]]; then
    version=${commandArray[$everyCommand+1]}
  fi

  if [[ ${commandArray[$everyCommand]} == -d ]]; then
    destroy=1
  fi

  if [[ ${commandArray[$everyCommand]} == -sw ]]; then
    switchMode=1
  fi
  if [[ ${commandArray[$everyCommand]} == -c ]]; then
    commandList=1
  fi
  if [[ ${commandArray[$everyCommand]} == -st ]]; then
    standart=1
  fi
done

if [[ $standart == 1 ]]; then
  allArgs=`cat standartRules.txt`
  read -a arrayArgs <<< $allArgs
  tor=${arrayArgs[0]}
  server=${arrayArgs[1]}
  memory=${arrayArgs[2]}
  os=${arrayArgs[3]}
  version=${arrayArgs[4]}
  destroy=${arrayArgs[5]}
  switchMode=${arrayArgs[6]}
  commandList=${arrayArgs[7]}
fi

####PROVIDES DEFAULT VALUE FOR EMPTY VARIABLES
if [[ $server == "" ]]; then
  server=1
  echo no server definied, using server equal to 1
fi
if [[ $tor == "" ]]; then
  tor=1
  echo no tor definied, using tor equal to 1
fi
if [[ $memory == "" ]]; then
 memory=500
 echo no memory definied, using memory equal to 1
fi
if [[ $os == "" ]]; then
 os=hashicorp/bionic64
 echo no os definied, using os equal to hashicorp/bionic64
fi
if [[ $version == "" ]]; then
 version=1.0.282
 echo no version definied, using version equal to 1.0.282
fi

####CREATES A .DOT FILE IN ACORDANCE WITH DESIRED PROJECT VIEW
./.converter_eth.sh $tor $server $memory $os $version
####CREATES TOPOLOGY AND VAGRANTFILE
./.converter_swp.sh $tor $server $memory $os $version

####BOOT MACHINES

vagrant up
sleep 20

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



if [[ $commandList == 1 ]]; then
  ./instructions.sh
fi


if [[ $destroy == 1 ]]; then
  vagrant destroy -f
fi
