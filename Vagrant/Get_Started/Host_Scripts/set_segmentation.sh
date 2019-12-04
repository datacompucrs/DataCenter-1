server=$1
tor=$2
op=$3

RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

alltTors=`ls ./Guest_Scripts/ | grep interface_commands_`

if    [[ $op == "1" ]]; then #Bridge Only
for eachTor in $alltTors; do
  thisMachine=${eachTor:19:-3}
  echo -e ${BLUE}"creating ${GREEN}bridge${BLUE} for ${GREEN}$thisMachine${BLUE} machine"${NC}
  vagrant ssh $thisMachine -c " /vagrant/Guest_Scripts/$eachTor"
done
elif    [[ $op == "2" ]]; then #Vlan
for eachTor in $alltTors; do
  thisMachine=${eachTor:19:-3}
  echo -e ${BLUE}"creating ${GREEN}vlan${BLUE} for ${GREEN}$thisMachine${BLUE} machine"${NC}
  vagrant ssh $thisMachine -c " /vagrant/Guest_Scripts/$eachTor"
done
elif    [[ $op == "3" ]]; then #Vlan
  for eachTor in $alltTors; do
    read -a infoArray <<< $(cat ./Guest_Scripts/$eachTor)
    echo -e ${BLUE}"creating ${GREEN}bridge${BLUE} and ${GREEN}vlan${BLUE} for ${infoArray[0]} machine"${NC}
    vagrant ssh ${infoArray[0]} -c "
    servers=$server;
    sudo apt-get install bridge-utils;
    sudo apt-get install vlan;
    sudo modprobe 8021q;
    sudo brctl addbr br0;
    sudo brctl addbr br1;
    sudo ifconfig br0 0;
    sudo ifconfig br1 0;
    thisText=\`cat /vagrant/Guest_Scripts/${eachTor} |  cut -d\" \" -f2- | sed 's/ /\n/g' | awk '{a=\$0;printf \"%s \",a,\$0}'\`;
    read -a swpArray <<< \$thisText;
    sudo vconfig add  \${swpArray[0]} 100
    sudo vconfig add  \${swpArray[0]} 200
    sudo ifconfig \${swpArray[0]}.100 0;
    sudo ifconfig \${swpArray[0]}.200 0;
    sizeArray=\${#swpArray[@]};
    inc=1;
    for (( everyItem=1; everyItem < \$((servers /2))+1; everyItem=everyItem+1));
      do echo \$((servers/2));
      echo \$everyItem
      sudo brctl addif br0 \${swpArray[(2*\$inc)]}
      inc=\$((inc+1))
    done;
    for (( everyItem=1; everyItem < (\$servers /2)+1; everyItem=everyItem+1));
      do sudo brctl addif br1 \${swpArray[(2*\$inc)]}
      inc=\$((inc+1))
    done;
    sudo brctl addif br0 \${swpArray[0]}.100
    sudo brctl addif br1 \${swpArray[0]}.200
    "
  done
fi
