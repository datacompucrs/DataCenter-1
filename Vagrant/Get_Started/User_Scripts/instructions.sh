RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
echo -e ${BLUE}"testing machine ${GREEN}server-A0${BLUE}"${NC}
vagrant ssh server-A0 -c  " /vagrant/User_Scripts/test_vlan_server.sh"
echo -e ${BLUE}"testing machine ${GREEN}server-A1${BLUE}"${NC}
vagrant ssh server-A2 -c  " /vagrant/User_Scripts/test_vlan_server.sh"
