server=$1
tor=$2

cd ./Guest_Scripts/
echo "" > hostnames.txt

currentLetter=A
for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
  for (( everyServer=0; everyServer < $server; everyServer++)); do
    cat IP_List.txt | grep server-$currentLetter$everyServer > ./setup_server-$currentLetter$everyServer.txt

  done;
currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
done;

currentLetter=A
for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
  cat IP_List.txt | grep tor-$currentLetter > ./setup_tor-$currentLetter.txt
  currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
done;

AllServers=`ls | grep server`
for everyServer in $AllServers; do
  read -a arrayIp <<< $(cat $everyServer)
  echo ${arrayIp[2]} ${arrayIp[0]} >> hostnames.txt
done
