server=$1
tor=$2

cd ./Guest_Scripts/
echo "" > hostnames.txt

cat IP_List.txt | grep spine > ./setup_spine.txt

currentLetter=A
for (( everySpine=0; everySpine < 2; everySpine++)); do
  currentLetter=A
  if [[ $everySpine == 0 ]]; then
    direction=L
  else
    direction=R
  fi
  for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
    for (( everyServer=0; everyServer < $server; everyServer++)); do
      cat IP_List.txt | grep server-$direction$currentLetter$everyServer > ./setup_server-$direction$currentLetter$everyServer.txt
    done;
    currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  done
done


for (( everySpine=0; everySpine < 2; everySpine++)); do
  currentLetter=A
  if [[ $everySpine == 0 ]]; then
    direction=L
  else
    direction=R
  fi
  for (( everyTor=1; everyTor < $tor+1; everyTor++)); do
    cat IP_List.txt | grep tor-$direction$currentLetter > ./setup_tor-$direction$currentLetter.txt
    currentLetter=$(echo "$currentLetter" | tr "0-9A-Z" "1-9A-Z_")
  done
done

AllServers=`ls | grep server`
for everyServer in $AllServers; do
  read -a arrayIp <<< $(cat $everyServer)
  echo $everyServer ${arrayIp[0]}
  echo ${arrayIp[2]} ${arrayIp[0]} >> hostnames.txt
done
AllTors=`ls | grep tor`
for everyTor in $AllTors; do
  torSwpNumber=`cat $everyTor | wc | awk '{print $1}'`
  for (( eachLine=0; eachLine < $torSwpNumber; eachLine++)); do
    read -a arrayIp <<< $(cat $everyTor | head -n $((eachLine+1)) | tail -n 1)
    echo ${arrayIp[2]} ${arrayIp[0]}$eachLine >> hostnames.txt
  done
done

spineSwpNumber=`cat setup_spine.txt | wc | awk '{print $1}'`
for (( eachLine=0; eachLine < $spineSwpNumber; eachLine++)); do
  read -a arrayIp <<< $(cat setup_spine.txt | head -n $((eachLine+1)) | tail -n 1)
  echo ${arrayIp[2]} ${arrayIp[0]}$eachLine >> hostnames.txt
done
