everyCommand=$*
read -a commandArray <<< $everyCommand
sizeArray=${#commandArray[@]}

RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

####define empty variables for comparision
server="";tor="";memory="";os="";version="";destroy="";switchMode="";commandList="";standart="";ip="";op=0;

####HELP TEXT
if [[ $1 == --help ]]; then
  echo -e "-s server -- number of servers\n-t tor -- number of tors\n-m memory -- memory alocation\n-o os -- operation system\n-v version -- os version"
  echo -e "-d destroy -- destroys topology after iteration\n-sw switch -- does not provide ip to swp\n-c commands -- uses a bash file to provide a list of commands"
  echo "-st standart -- uses a txt file to have standart inputs"
  exit
fi

####CHECK EVERY ARGUMENT TO FILL SERVER, TOR, ETC, VARIABLES
for (( everyCommand=0; everyCommand < $sizeArray; everyCommand=everyCommand+1)); do
  if [[ ${commandArray[$everyCommand]} == --ip ]];       then ip=${commandArray[$everyCommand+1]};      fi
  if [[ ${commandArray[$everyCommand]} == -o ]];         then os=${commandArray[$everyCommand+1]};      fi
  if [[ ${commandArray[$everyCommand]} == -t ]];         then tor=${commandArray[$everyCommand+1]};     fi
  if [[ ${commandArray[$everyCommand]} == -s ]];         then server=${commandArray[$everyCommand+1]};  fi
  if [[ ${commandArray[$everyCommand]} == -m ]];         then memory=${commandArray[$everyCommand+1]};  fi
  if [[ ${commandArray[$everyCommand]} == -v ]];         then version=${commandArray[$everyCommand+1]}; fi
  if [[ ${commandArray[$everyCommand]} == -d ]];         then destroy=1;                                fi
  if [[ ${commandArray[$everyCommand]} == -st ]];        then standart=1;                               fi
  if [[ ${commandArray[$everyCommand]} == -sw ]];        then switchMode=1;                             fi
  if [[ ${commandArray[$everyCommand]} == -c ]];         then commandList=1;                            fi
  if [[ ${commandArray[$everyCommand]} == --bridge ]];   then op=1;                                     fi
  if [[ ${commandArray[$everyCommand]} == --vlan ]];     then op=2;                                     fi
  if [[ ${commandArray[$everyCommand]} == --spine ]];    then op=3;                                     fi
done

if [[ $standart == 1 ]]; then
  allArgs=`cat ./User_Script/standartRules.txt`
  read -a arrayArgs <<< $allArgs
  tor=${arrayArgs[0]}
  server=${arrayArgs[1]}
  memory=${arrayArgs[2]}
  os=${arrayArgs[3]}
  version=${arrayArgs[4]}
  destroy=${arrayArgs[5]}
  switchMode=${arrayArgs[6]}
  commandList=${arrayArgs[7]}
  up=${arrayArgs[8]}
fi

####PROVIDES DEFAULT VALUE FOR EMPTY VARIABLES
if [[ $tor == "" ]];       then tor=1;                 echo no tor definied, using tor equal to 1;                fi
if [[ $ip == "" ]];        then ip=1;                  echo no ip definied, using ip equal to no ip;              fi
if [[ $server == "" ]];    then server=1;              echo no server definied, using server equal to 1;          fi
if [[ $memory == "" ]];    then memory=500;            echo no memory definied, using memory equal to 1;          fi
if [[ $os == "" ]];        then os=hashicorp/bionic64; echo no os definied, using os equal to hashicorp/bionic64; fi
if [[ $version == "" ]];   then version=1.0.282;       echo no version definied, using version equal to 1.0.282;  fi

####CREATES A .DOT FILE IN ACORDANCE WITH DESIRED PROJECT VIEW
./.converter_eth.sh $tor $server $memory $os $version $op
####CREATES TOPOLOGY AND VAGRANTFILE
./.converter_swp.sh $tor $server $memory $os $version $op

rm -rf ./Guest_Scripts/*

####CREATE IPS
echo -e ${YELLOW}"creating IPs for all machines"${NC}
if [[ $op == 3 ]]; then
  ./Host_Scripts/create_IPs_spine.sh $server $tor $ip
else
  ./Host_Scripts/create_IPs.sh $server $tor $ip
fi
echo -e ${YELLOW}"creating IP files for each machine"${NC}
if [[ $op == 3 ]]; then
  ./Host_Scripts/break_IPs_spine.sh $server $tor
else
  ./Host_Scripts/break_IPs.sh $server $tor
fi
echo -e ${YELLOW}"creating script to set comunication"${NC}
./Host_Scripts/create_interfaceFiles.sh $server $tor $op
####BOOT MACHINES

vagrant up
sleep 20

echo -e ${YELLOW}"adding IP for each interface and adding hostname information"${NC}
./Host_Scripts/set_interfaces.sh $server $tor
echo -e ${YELLOW}"setting topology segmentation"${NC}
./Host_Scripts/set_segmentation.sh $server $tor $op


if [[ $commandList == 1 ]]; then
  ./User_Script/instructions.sh
fi


if [[ $destroy == 1 ]]; then
  vagrant destroy -f
fi
