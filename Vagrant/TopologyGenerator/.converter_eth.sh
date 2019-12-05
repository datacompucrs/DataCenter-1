
standartSpine="\"spine\"   [function=\"leaf\" vagrant=\"eth1\" os=\"$4\" version=\"$5\" memory=\"$3\" config=\"./helper_scripts/config_production_switch.sh\" ]"
standartTor="\"tor-!\"   [function=\"leaf\" vagrant=\"eth1\" os=\"$4\" version=\"$5\" memory=\"$3\" config=\"./helper_scripts/config_production_switch.sh\" ]"
standartServer="\"server-!\" [function=\"host\" vagrant=\"eth3\" os=\"$4\" version=\"$5\" memory=\"$3\" config=\"./helper_scripts/config_production_server.sh\" ] "
standartethConnection="\"tor-(\":\"eth&\" -- \"tor-)\":\"eth!\""
standartSpineConnection="\"tor-(\":\"eth&\" -- \"spine\":\"eth!\""
standartServerConnection="\"server-(\":\"eth1\" -- \"tor-)\":\"eth&\" [left_mac=\"00:0!:00:@@:@@:0@\"]"
hatedLine="Vagrant.require_version \">= 1.8.6\", \"< 2.0.0\""

allTors=$1
allServers=$2
allethConnections=$(($allTors -1))
spineOn=$6



echo "graph vx {" > viewer.dot

####DEFINE SERVERS AND TORS
currentLetter=A

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
    for (( everyethConnection=0; everyethConnection < $allethConnections+1; everyethConnection++)); do
      thisethConnection=`echo $standartSpineConnection | sed "s/(/$direction$currentLetter/g" | sed "s/&/$leafPort/g"  | sed "s/)/$leafPort/g" | sed "s/!/$nextPort/g"`
      nextPort=$((nextPort+1))
      echo $thisethConnection >> viewer.dot
      currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
    done
  done
else
  currentLetter=A
  currentPort=50
  nextPort=49
  for (( everyethConnection=0; everyethConnection < $allethConnections; everyethConnection++)); do
    nextethConnections=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
    thisethConnection=`echo $standartethConnection | sed "s/(/$currentLetter/g" | sed "s/)/$nextethConnections/g" | sed "s/&/$currentPort/g" | sed "s/!/$nextPort/g"`
    currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
    echo $thisethConnection >> viewer.dot
  done
fi

echo "" >> viewer.dot


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
        echo $thisConnection >> viewer.dot
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
      echo $thisConnection >> viewer.dot
    done
    currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  done
fi

echo "}" >> viewer.dot

sed -i "/$hatedLine/d" ./Vagrantfile
