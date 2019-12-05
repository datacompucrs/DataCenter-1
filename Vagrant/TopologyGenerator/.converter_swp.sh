
standartSpine="\"spine\"   [function=\"leaf\" vagrant=\"eth1\" os=\"$4\" version=\"$5\" memory=\"$3\" config=\"./helper_scripts/config_production_switch.sh\" ]"
standartTor="\"tor-!\"   [function=\"leaf\" vagrant=\"eth1\" os=\"$4\" version=\"$5\" memory=\"$3\" config=\"./helper_scripts/config_production_switch.sh\" ]"
standartServer="\"server-!\" [function=\"host\" vagrant=\"eth3\" os=\"$4\" version=\"$5\" memory=\"$3\" config=\"./helper_scripts/config_production_server.sh\" ] "
standartSwpConnection="\"tor-(\":\"swp&\" -- \"tor-)\":\"swp!\""
standartSpineConnection="\"tor-(\":\"swp&\" -- \"spine\":\"swp!\""
standartServerConnection="\"server-(\":\"eth1\" -- \"tor-)\":\"swp&\" " #[left_mac=\"00:0!:00:@@:@@:0@\"]
hatedLine="Vagrant.require_version \">= 1.8.6\", \"< 2.0.0\""

allTors=$1
allServers=$2
allSwpConnections=$(($allTors -1))
spineOn=$6



echo "graph vx {" > topology.dot

####DEFINE SERVERS AND TORS
currentLetter=A

if [[ $spineOn =  "3" ]]; then ## SPINE TOPOLOGY
  echo $standartSpine >> topology.dot
  for (( everySpine=0; everySpine < 2; everySpine++)); do
    if [[ $everySpine == 0 ]]; then
      newTor=`echo $standartTor | sed "s/!/L!/g"`
      newServer=`echo $standartServer | sed "s/!/L!/g"`
    else
      newTor=`echo $standartTor | sed "s/!/R!/g"`
      newServer=`echo $standartServer | sed "s/!/R!/g"`
    fi
    for (( everyTor=0; everyTor < $allTors; everyTor++)); do
      thisTor=`echo $newTor | sed "s/!/$currentLetter/g"`
      echo $thisTor >> topology.dot
      for (( everyServer=0; everyServer < $allServers; everyServer++)); do
        thisServer=`echo $newServer | sed "s/!/$currentLetter$everyServer/g"`
        echo $thisServer >> topology.dot
      done
      currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
      echo "" >> topology.dot;
    done
    currentLetter=A
  done
else    ## TOPOLOGY WITHOUT SPINE
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
fi

####CREATE SWITCH PORT CONNECTIONS
if [[ $spineOn =  "3" ]]; then ## SPINE TOPOLOGY
  leafPort=50
  nextPort=1
  spinePort=1
  for (( everySpine=0; everySpine < 2; everySpine++)); do
    currentLetter=A
    if [[ $everySpine == 0 ]]; then
      direction=L
    else
      direction=R
    fi
    for (( everySwpConnection=0; everySwpConnection < $allSwpConnections+1; everySwpConnection++)); do
      thisSwpConnection=`echo $standartSpineConnection | sed "s/(/$direction$currentLetter/g" | sed "s/&/$leafPort/g"  | sed "s/)/$leafPort/g" | sed "s/!/$nextPort/g"`
      nextPort=$((nextPort+1))
      echo $thisSwpConnection >> topology.dot
      currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
    done
  done
else
  currentLetter=A
  currentPort=50
  nextPort=49
  for (( everySwpConnection=0; everySwpConnection < $allSwpConnections; everySwpConnection++)); do
    nextSwpConnections=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
    thisSwpConnection=`echo $standartSwpConnection | sed "s/(/$currentLetter/g" | sed "s/)/$nextSwpConnections/g" | sed "s/&/$currentPort/g" | sed "s/!/$nextPort/g"`
    currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
    echo $thisSwpConnection >> topology.dot
  done
fi

echo "" >> topology.dot


####CREATE CONNECTIONS BETWEEN TOR AND SERVERS
currentLetter=A

if [[ $spineOn =  "3" ]]; then
  for (( everySpine=0; everySpine < 2; everySpine++)); do
    currentLetter=A
    if [[ $everySpine == 0 ]]; then
      direction=L
    else
      direction=R
    fi
    for (( everyTor=0; everyTor < $allTors; everyTor++)); do
      thisMacTor=$(($everyTor +1))
      for (( everyServer=0; everyServer < $allServers; everyServer++)); do
        thisMacServer=$(($everyServer +1))
        thisConnection=`echo $standartServerConnection | sed "s/(/$direction$currentLetter$everyServer/g" | sed "s/&/$thisMacServer/g" | sed "s/)/$direction$currentLetter/g" | sed "s/!/$thisMacTor/g" | sed "s/@/$thisMacServer/g"`
        echo $thisConnection >> topology.dot
      done
      currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
    done
  done
else
  for (( everyTor=0; everyTor < $allTors; everyTor++)); do
    thisMacTor=$(($everyTor +1))
    for (( everyServer=0; everyServer < $allServers; everyServer++)); do
      thisMacServer=$(($everyServer +1))
      thisConnection=`echo $standartServerConnection | sed "s/(/$currentLetter$everyServer/g" | sed "s/&/$thisMacServer/g" | sed "s/)/$currentLetter/g" | sed "s/!/$thisMacTor/g" | sed "s/@/$thisMacServer/g"`
      echo $thisConnection >> topology.dot
    done
    currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  done
fi

echo "}" >> topology.dot


python ./topology_converter.py ./topology.dot -p libvirt  &> /dev/null

sed -i "/$hatedLine/d" ./Vagrantfile
