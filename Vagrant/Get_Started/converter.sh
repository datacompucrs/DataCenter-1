everyCommand=$*
read -a commandArray <<< $everyCommand
sizeArray=${#commandArray[@]}

server=""
tor=""
memory=""
os=""
version=""

if [[ $1 == --help ]]; then
  echo -e "-s number of servers\n-t number of tors\n-m memory alocation\n-o operation system\n-v os version"
  exit
fi

for (( everyCommand=0; everyCommand < $sizeArray; everyCommand=everyCommand+2)); do
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


done

if [[ $server == "" ]]; then
  server=1
  echo no server definied, using server equal to 1
fi
if [[ $tor == "" ]]; then
  tor=1
  echo no tor definied, using tor equal to 1
fi
if [[ $memory == "" ]]; then
 memory=700
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


./converter_eth.sh $tor $server $memory $os $version
./converter_swp.sh $tor $server $memory $os $version

#vagrant up

declare -a swpNames
declare -a provisionText
currentLetter=A
serverIp="10.32.!0.@"
torIp="192.168.!0.@"
for (( everyTor=1; everyTor < $tor+1; everyTor++)); do

  currentName=tor-$currentLetter
  currentServerIp=`echo $serverIp | sed "s/!/$everyTor/g"`
  if [[ $everyTor == 1 ]]; then
    currentTorIp=`echo $torIp | sed "s/!/$everyTor/g"`
    intraTorIp=`echo $currentTorIp | sed "s/@/50/g"`
    echo "vagrant ssh tor-$currentLetter sudo ifconfig swp50 $intraTorIp up"
  elif [[ $everyTor == $tor ]]; then
    currentTorIp=`echo $torIp | sed "s/!/$((everyTor-1))/g"`
    intraTorIp=`echo $currentTorIp | sed "s/@/49/g"`
    echo "vagrant ssh tor-$currentLetter sudo ifconfig swp49 $intraTorIp up"
  else
    currentTorIp=`echo $torIp | sed "s/!/$everyTor/g"`
    pastTorIp=`echo $torIp | sed "s/!/$((everyTor-1))/g"`
    intraTorIp=`echo $currentTorIp | sed "s/@/50/g"`
    echo "vagrant ssh tor-$currentLetter sudo ifconfig swp49 $intraTorIp up"
    intraTorIp=`echo $pastTorIp | sed "s/@/49/g"`
    echo "vagrant ssh tor-$currentLetter sudo ifconfig swp49 $intraTorIp up"
  fi


  unset swpNames
  for (( everyServer=0; everyServer < $server+1; everyServer++)); do
    oneServerIp=`echo $currentServerIp | sed "s/@/$((everyServer*2))/g"`
    swpNames+="$oneServerIp "
  done
    read -a swpArray <<< $swpNames
    provisionText="vagrant ssh tor-$currentLetter -c \""
  for (( everyServer=1; everyServer < $server+1; everyServer++)); do

    provisionText+=" sudo ifconfig swp$everyServer ${swpArray[$everyServer]} up;"
  done
  provisionText+="\""
  echo $provisionText


  currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
done
