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
