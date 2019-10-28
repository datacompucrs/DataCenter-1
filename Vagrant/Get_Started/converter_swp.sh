
standartTor="\"tor-!\"   [function=\"leaf\" vagrant=\"eth1\" os=\"hashicorp/bionic64\" version=\"1.0.282\" memory=\"$3\" config=\"./helper_scripts/config_production_switch.sh\" ]"
standartServer="\"server-!\" [function=\"host\" vagrant=\"eth3\" os=\"hashicorp/bionic64\" version=\"1.0.282\" memory=\"$3\" config=\"./helper_scripts/config_production_server.sh\" ] "
standartSwpConnection="\"tor-(\":\"swp&\" -- \"tor-)\":\"swp!\""
standartServerConnection="\"server-(\":\"eth1\" -- \"tor-)\":\"swp&\" [left_mac=\"00:0!:00:@@:@@:0@\"]"
hatedLine="Vagrant.require_version \">= 1.8.6\", \"< 2.0.0\""

allTors=$1
allServers=$2
allSwpConnections=$(($allTors -1))

echo "graph vx {" > topology.dot

####DEFINE SERVERS AND TORS
currentLetter=A
for (( everyTor=0; everyTor < $allTors; everyTor++)); do
  thisTor=`echo $standartTor | sed "s/!/$currentLetter/g"`
  echo $thisTor >> topology.dot
  for (( everyServer=0; everyServer < $allServers; everyServer++)); do
    thisServer=`echo $standartServer | sed "s/!/$currentLetter$everyServer/g"`
    echo $thisServer >> topology.dot
  done
  currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  echo "" >> topology.dot;
done


####CREATE SWITCH PORT CONNECTIONS
currentLetter=A
currentPort=50
nextPort=49
for (( everySwpConnection=0; everySwpConnection < $allSwpConnections; everySwpConnection++)); do
  nextSwpConnections=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  thisSwpConnection=`echo $standartSwpConnection | sed "s/(/$currentLetter/g" | sed "s/)/$nextSwpConnections/g" | sed "s/&/$currentPort/g" | sed "s/!/$nextPort/g"`
  currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
echo $thisSwpConnection >> topology.dot
done

echo "" >> topology.dot


####CREATE CONNECTIONS BETWEEN TOR AND SERVERS
currentLetter=A
for (( everyTor=0; everyTor < $allTors; everyTor++)); do
  thisMacTor=$(($everyTor +1))
  for (( everyServer=0; everyServer < $allServers; everyServer++)); do
    thisMacServer=$(($everyServer +1))
    thisConnection=`echo $standartServerConnection | sed "s/(/$currentLetter$everyServer/g" | sed "s/&/$thisMacServer/g" | sed "s/)/$currentLetter/g" | sed "s/!/$thisMacTor/g" | sed "s/@/$thisMacServer/g"`
    echo $thisConnection >> topology.dot
  done
  currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
done

echo "}" >> topology.dot


python ./topology_converter.py ./topology.dot -p libvirt

####CREATE IPS
nServersNetworks=$(($allTors))
standartIp="192.168.!0.@"
for (( everyNetwork=0; everyNetwork < $nServersNetworks; everyNetwork++)); do
  thisNetwork=`echo $standartIp | sed "s/!/$everyNetwork/g" | sed "s/@/0/g"`
  echo ""
  echo network $thisNetwork
  for (( everyServer=0; everyServer < $allServers+$allServers; everyServer++)); do
    machineId=$(($everyServer+1))
    machineNetwork=`echo $standartIp | sed "s/!/$everyNetwork/g" | sed "s/@/$machineId/g"`
    echo machine $machineNetwork
  done
done
    echo ""
nTorNetworks=$(($allTors-1))
for (( everyTor=$everyNetwork; everyTor < $nTorNetworks+$everyNetwork; everyTor++)); do
  thisNetwork=`echo $standartIp | sed "s/!/$everyTor/g" | sed "s/@/0/g"`
  echo ""
  echo network $thisNetwork
  for (( everySwp=0; everySwp < 2; everySwp++)); do
    swpId=$(($everySwp+1))
    machineNetwork=`echo $standartIp | sed "s/!/$everyTor/g" | sed "s/@/$swpId/g"`
    echo machine $machineNetwork
  done
done

eth_list=`cat topology.dot | grep -o "\w*eth\w*" | sort | uniq`
swp_list=`cat topology.dot | grep -o "\w*swp\w*" | sort | uniq`

expectedText="sudo ipconfig $interface $ip up"

sed -i "/$hatedLine/d" ./Vagrantfile
