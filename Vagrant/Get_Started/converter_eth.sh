
standartTor="\"tor-!\" [function=\"host\" vagrant=\"eth1\" os=\"hashicorp/bionic64\" version=\"1.0.282\" memory=\"$3\" config=\"./helper_scripts/config_production_server.sh\" ]"
standartServer="\"server-!\" [function=\"host\" vagrant=\"eth1\" os=\"hashicorp/bionic64\" version=\"1.0.282\" memory=\"$3\" config=\"./helper_scripts/config_production_server.sh\" ] "
standartSwpConnection="\"tor-(\":\"eth&\" -- \"tor-)\":\"eth!\" [left_mac=\"00:!0:00:00:00:!!\"][right_mac=\"00:!0:00:00:00:00\"]"
standartServerConnection="\"server-(\":\"eth1\" -- \"tor-)\":\"eth&\" [left_mac=\"00:0!:00:@@:@@:0@\"][right_mac=\"00:!0:00:@@:@@:0@\"]"
hatedLine="Vagrant.require_version \">= 1.8.6\", \"< 2.0.0\""

allTors=$1
allServers=$2
allSwpConnections=$(($allTors -1))

echo "graph vx {" > viewer.dot

####DEFINE SERVERS AND TORS
currentLetter=A
for (( everyTor=0; everyTor < $allTors; everyTor++)); do
  thisTor=`echo $standartTor | sed "s/!/$currentLetter/g"`
  echo $thisTor >> viewer.dot
  for (( everyServer=0; everyServer < $allServers; everyServer++)); do
    thisServer=`echo $standartServer | sed "s/!/$currentLetter$everyServer/g"`
    echo $thisServer >> viewer.dot
  done
  currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  echo "" >> viewer.dot;
done


####CREATE CONNECTIONS BETWEEN TOR AND SERVERS
currentLetter=A
for (( everyTor=0; everyTor < $allTors; everyTor++)); do
  thisMacTor=$(($everyTor +1))
  for (( everyServer=0; everyServer < $allServers; everyServer++)); do
    thisMacServer=$(($everyServer +1))
    thisConnection=`echo $standartServerConnection | sed "s/(/$currentLetter$everyServer/g" | sed "s/&/$thisMacServer/g" | sed "s/)/$currentLetter/g" | sed "s/!/$thisMacTor/g" | sed "s/@/$thisMacServer/g"`
    echo $thisConnection >> viewer.dot
  done
  currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
done

echo "" >> topology.dot

####CREATE SWITCH PORT CONNECTIONS
currentLetter=A
currentPort=$(($everyServer+1))
nextPort=$(($everyServer+1))
for (( everySwpConnection=0; everySwpConnection < $allSwpConnections; everySwpConnection++)); do
  nextSwpConnections=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  thisSwpConnection=`echo $standartSwpConnection | sed "s/(/$currentLetter/g" | sed "s/)/$nextSwpConnections/g" | sed "s/&/$currentPort/g" | sed "s/!/$nextPort/g"`
  currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  currentPort=$(($currentPort+1))
  nextPort=$(($nextPort+1))
echo $thisSwpConnection >> viewer.dot
done

echo "" >> viewer.dot

echo "}" >> viewer.dot
