# Update sources.list with mirrors configuration
#mv /etc/apt/sources.list /etc/apt/sources.list.old

#cat > /etc/apt/sources.list << EOF
#deb mirror://mirrors.ubuntu.com/mirrors.txt xenial main restricted universe multiverse
#deb mirror://mirrors.ubuntu.com/mirrors.txt xenial-updates main restricted universe multiverse
#deb mirror://mirrors.ubuntu.com/mirrors.txt xenial-backports main restricted universe multiverse
#deb mirror://mirrors.ubuntu.com/mirrors.txt xenial-security main restricted universe multiverse
#EOF

# Update apt cache
apt update

# Generic packages
apt -y install wget
# sudo apt -y install debconf-utils
# sudo apt -y install xauth
# sudo apt -y install bridge-utils ebtables iproute libev-dev

# Following instructions from http://coreemu.github.io/core/install.html

# Python requirements
apt -y install python3-pip

CORESRC=https://github.com/coreemu/core/archive/release-5.3.1.tar.gz
wget -c $CORESRC
mv release-5.3.1.tar.gz core-5.3.1.tar.gz
tar -zxf core-5.3.1.tar.gz

python3 -m pip install -r core-release-5.3.1/daemon/requirements.txt

# URLs to download core
COREPKG=https://github.com/coreemu/core/releases/download/release-5.3.1/core_python3_5.3.1_amd64.deb
wget -c $COREPKG
apt -f -y install ./core_python3_5.3.1_amd64.deb

# Install wireshark enabled for non-root users
DEBIAN_FRONTEND=noninteractive apt-get -y install wireshark
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure wireshark-common
usermod -a -G wireshark vagrant

# Install other packages
apt -y install mgen traceroute snmpd snmp-mibs-downloader snmptrapd \
  mgen-doc autoconf automake make pkg-config python-dev libreadline-dev imagemagick help2man \
  apache2 quagga

# Start core-daemon
service core-daemon start
