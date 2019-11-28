sudo ip link add name br0 type bridge
sudo ip link add name br1 type bridge
sudo ip link set dev br0 up
sudo ip link set dev br1 up
thisText=`cat /vagrant/Guest_Scripts/setup_tor-B.txt |  cut -d" " -f2- | sed 's/ /\n/g' | awk '{a=$0;printf "%s ",a,$0}'`;
read -a swpArray <<< $thisText;
sizeArray=${#swpArray[@]};
sudo ip link add link ${swpArray[0]} name ${swpArray[0]}.100 type vlan id 100
sudo ip link add link ${swpArray[0]} name ${swpArray[0]}.200 type vlan id 200
sudo ip link set dev ${swpArray[0]}.100 up
sudo ip link set dev ${swpArray[0]}.200 up
servers=2
inc=1
for (( everyItem=1; everyItem < $((servers /2))+1; everyItem=everyItem+1));
do sudo ip link set dev ${swpArray[(2*$inc)]} master br0
inc=$((inc+1))
done;
for (( everyItem=1; everyItem < $((servers /2))+1; everyItem=everyItem+1));
do sudo ip link set dev ${swpArray[(2*$inc)]} master br1
inc=$((inc+1))
done;
sudo ip link set dev ${swpArray[0]}.100 master br0
sudo ip link set dev ${swpArray[0]}.200 master br1
