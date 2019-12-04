BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
echo ""
allServers=`ls /vagrant/Guest_Scripts/ | grep setup_server`
for eachServer in $allServers; do
  read -a arrayIp <<< $(cat /vagrant/Guest_Scripts/$eachServer)
  echo -e ${BLUE}"pinging ${GREEN}${arrayIp[0]}${BLUE}"${NC}
  ping -c 1 -q ${arrayIp[0]} | grep received
done;
exit
