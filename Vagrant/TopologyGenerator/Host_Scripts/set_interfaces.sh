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


for eachServer in $allServers; do
  read -a infoArray <<< $(cat ./Guest_Scripts/$eachServer)
  echo -e ${BLUE}"setting ${GREEN}ip${BLUE} and ${GREEN}hostname${BLUE} information for machine ${GREEN}${infoArray[0]}"${NC}
  vagrant ssh ${infoArray[0]} -c "sudo ifconfig ${infoArray[1]} ${infoArray[2]} up; cat /vagrant/Guest_Scripts/hostnames.txt | sudo tee -a /etc/hosts" &> /dev/null
done;

for eachTor in $alltTors; do
  read -a infoArray <<< $(cat ./Guest_Scripts/$eachTor)
  echo -e ${BLUE}"setting ${GREEN}ip${BLUE} and ${GREEN}hostname${BLUE} information for machine ${GREEN}${infoArray[0]}"${NC}
  vagrant ssh ${infoArray[0]} -c "
  thisText=\`cat /vagrant/Guest_Scripts/${eachTor} |  cut -d\" \" -f2- | sed 's/ /\n/g' | awk '{a=\$0;printf \"%s \",a,\$0}'\`;
  read -a swpArray <<< \$thisText;
  sizeArray=\${#swpArray[@]};
  for (( everyItem=0; everyItem < \$sizeArray /2; everyItem=everyItem+1));
  do sudo ifconfig \${swpArray[(2*\$everyItem)]} \${swpArray[(2*\$everyItem)+1]} up;
  done;" &> /dev/null
done

if [[ $op == "3" ]]; then
  echo -e ${BLUE}"setting ${GREEN}ip${BLUE} and ${GREEN}hostname${BLUE} information for machine ${GREEN}vaspine"${NC}
  vagrant ssh spine -c "
  thisText=\`cat /vagrant/Guest_Scripts/setup_spine.txt |  cut -d\" \" -f2- | sed 's/ /\n/g' | awk '{a=\$0;printf \"%s \",a,\$0}'\`;
  read -a swpArray <<< \$thisText;
  sizeArray=\${#swpArray[@]};
  for (( everyItem=0; everyItem < \$sizeArray /2; everyItem=everyItem+1));
  do sudo ifconfig \${swpArray[(2*\$everyItem)]} \${swpArray[(2*\$everyItem)+1]} up;
  done;" &> /dev/null
fi
