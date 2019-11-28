server=$1
tor=$2
op=$3

allServers=`ls ./Guest_Scripts/ | grep setup_server`
alltTors=`ls ./Guest_Scripts/ | grep setup_tor`

RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

if [[ $op == "1" ]]; then #bridge
  for eachTor in $alltTors; do
    read -a infoArray <<< $(cat ./Guest_Scripts/$eachTor)
    echo -e ${BLUE}"creating ${GREEN}bridge${BLUE} file for ${infoArray[0]} machine"${NC}
    echo "sudo ip link add name br0 type bridge" >>   ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "sudo ip link set dev br0 up" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "thisText=\`cat /vagrant/Guest_Scripts/${eachTor} |  cut -d\" \" -f2- | sed 's/ /\n/g' | awk '{a=\$0;printf \"%s \",a,\$0}'\`;" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "read -a swpArray <<< \$thisText;" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "sizeArray=\${#swpArray[@]};" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "for (( everyItem=0; everyItem < \$sizeArray /2; everyItem=everyItem+1));"  >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "do sudo ip link set dev \${swpArray[(2*\$everyItem)]} master br0"  >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "done;" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    chmod 777 ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
  done
elif    [[ $op == "2" ]]; then #Vlan
  for eachTor in $alltTors; do
    read -a infoArray <<< $(cat ./Guest_Scripts/$eachTor)
    echo -e ${BLUE}"creating ${GREEN}bridge${BLUE} file for ${infoArray[0]} machine"${NC}
    echo "sudo ip link add name br0 type bridge" >>   ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "sudo ip link add name br1 type bridge" >>   ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "sudo ip link set dev br0 up" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "sudo ip link set dev br1 up" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "thisText=\`cat /vagrant/Guest_Scripts/${eachTor} |  cut -d\" \" -f2- | sed 's/ /\n/g' | awk '{a=\$0;printf \"%s \",a,\$0}'\`;" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "read -a swpArray <<< \$thisText;" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "sizeArray=\${#swpArray[@]};" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "sudo ip link add link \${swpArray[0]} name \${swpArray[0]}.100 type vlan id 100" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "sudo ip link add link \${swpArray[0]} name \${swpArray[0]}.200 type vlan id 200" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "sudo ip link set dev \${swpArray[0]}.100 up" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "sudo ip link set dev \${swpArray[0]}.200 up" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "servers=$server" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "inc=1" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "for (( everyItem=1; everyItem < \$((servers /2))+1; everyItem=everyItem+1));" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "do sudo ip link set dev \${swpArray[(2*\$inc)]} master br0" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "inc=\$((inc+1))" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "done;" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "for (( everyItem=1; everyItem < \$((servers /2))+1; everyItem=everyItem+1));" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "do sudo ip link set dev \${swpArray[(2*\$inc)]} master br1" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "inc=\$((inc+1))" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "done;" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "sudo ip link set dev \${swpArray[0]}.100 master br0" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    echo "sudo ip link set dev \${swpArray[0]}.200 master br1" >> ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
    chmod 777 ./Guest_Scripts/interface_commands_${infoArray[0]}.sh
  done
fi
