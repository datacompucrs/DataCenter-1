#!/bin/bash
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
echo -e ${YELLOW}Running ${BLUE}converter.sh${NC}

###CRIA ARRAY COM OS ARGUMENTOS DA FUNCAO
everyCommand=$*
read -a commandArray <<< $everyCommand
sizeArray=${#commandArray[@]}

####DEFINE VARIAVEIS VAZIAS PARA COMPARACAO
server="";switch="";router="";oob=""; protocols=""; machineType="";

createSwitchs=0
createRouters=0
vxlan=0
vlan=0
bgp=0

####PROCURA POR ARGUMENTOS
echo -e "${YELLOW}Parsing arguments"${NC}
for (( everyCommand=0; everyCommand < $sizeArray; everyCommand=everyCommand+1)); do
  if [[ ${commandArray[$everyCommand]} == --l0 ]];       then server=${commandArray[$everyCommand+1]};      fi
  if [[ ${commandArray[$everyCommand]} == --l1 ]];       then switch=${commandArray[$everyCommand+1]};      fi
  if [[ ${commandArray[$everyCommand]} == --l2 ]];       then router=${commandArray[$everyCommand+1]};      fi
  if [[ ${commandArray[$everyCommand]} == --l3 ]];       then oob=${commandArray[$everyCommand+1]};         fi
  if [[ ${commandArray[$everyCommand]} == -m ]]; then
    if [[ ${commandArray[$everyCommand+1]} == *r* ]]; then
      createRouters=1
    fi
    if [[ ${commandArray[$everyCommand+1]} == *s* ]]; then
      createSwitchs=1
    fi
  fi

  if [[ ${commandArray[$everyCommand]} == -p ]]; then
    if [[ ${commandArray[$everyCommand+1]} == *x* ]]; then
      vxlan=1
    fi
    if [[ ${commandArray[$everyCommand+1]} == *l* ]]; then
      vlan=1
    fi
    if [[ ${commandArray[$everyCommand+1]} == *b* ]]; then
      bgp=1
    fi
  fi
done


if [[ $server == "" ]];           then server=1;  echo no server definied, using server equal to 1;           fi
if [[ $switch == "" ]];           then switch=0;  echo no switch definied, using switch equal to 0;           fi
if [[ $router == "" ]];           then router=0;  echo no router definied, using router equal to 0;           fi
if [[ $oob == "" ]];              then oob=0;     echo no out of bound switch definied, using oob equal to 0; fi
if [[ $vxlan == 1 ]];             then            echo vxlan will be configured ;                             fi
if [[ $vlan == 1 ]];              then            echo vlan will be configured ;                              fi
if [[ $bgp == 1 ]];               then            echo bgp will be configured ;                               fi
if [[ $createRouters == 1 ]];     then            echo routers machines vxlan will be configured as routers;  fi
if [[ $createSwitchs == 1 ]];     then            echo switch machines will be configured as switchs;         fi

echo -e "${YELLOW}Running ${BLUE}converter.py, ${YELLOW}creating network topology"${NC}
python converter.py --l0 $server --l1 $switch --l2 $router --l3 $oob

allMachines=`cat ipList.txt | awk '{print $1}' | sort | uniq`

cd ./Guest_Scripts/ && rm -rf *.txt && cd ./Interface_Information/ && rm -rf *

#CRIA ARQUIVOS CONTENDO IPS
echo -e ${YELLOW}Creating machine config files${NC}
for eachMachine in $allMachines; do
  cat ../../ipList.txt | grep $eachMachine >> $eachMachine.txt
done

#LEVANTA INTERFACES
echo -e "${YELLOW}Setting interfaces"${NC}
listOfFiles=`ls`
for eachFile in $listOfFiles; do
while read line; do
  thisFile=${eachFile}_setup.txt
  ip=`echo $line | awk '{print $2}'`
  interface=`echo $line | awk '{print $3}'`
  echo sudo ifconfig $interface $ip up >> ../$thisFile
done<$eachFile
done

#ADICIONA ROTA PADRAO PARA SERVIDORES
echo -e ${YELLOW}"Creating ${BLUE} default gateway ${YELLOW}for routers"${NC}
allServers=`ls | grep server`
for eachServer in $allServers; do
    thisFile=${eachServer}_setup.txt
    echo sudo ip route del 0/0 >> ../$thisFile
    ip=`cat $eachServer | awk '{print $2}'`
    currentNetwork=`echo $ip | sed -r 's/(([0-9]{1,3}\.){3})[0-9]{1,3}/\11/g' | sed 's/\/24//g'`
    echo sudo ip route add 0/0 via $currentNetwork dev eth50 >> ../$thisFile
done

if [[ $vlan == 1 ]]; then
  echo -e ${YELLOW}"Adding ${BLUE}vlan ${YELLOW}protocol" ${NC}
  ##CRIA SWITCHS COM VLAN ADICIONADA
  allSwitchs=`ls | grep switch`       #encontra todos os switchs disponiveis
  for eachSwitch in $allSwitchs; do   #para cada switch da lista de switchs
    thisFile=${eachSwitch}_setup.txt
    echo sudo ip link add name br1 type bridge >> ../$thisFile
    read -a allInterfaces <<< $(cat $eachSwitch | awk '{print $3}' | tac)
    sizeArray=${#allInterfaces[@]}
    for (( i=0; i < 2; i=i+1 )); do
      echo sudo ip link add name br$i type bridge >> ../$thisFile  #cria uma bridge para linkar interfaces
      echo sudo ip link set dev br$i up >> ../$thisFile            #levanta as interfaces bridges
      echo sudo ip link add link ${allInterfaces[0]} name ${allInterfaces[0]}.$((i+1))00 type vlan id $((i+1))00 >> ../$thisFile #cria nova interface ethy.x como vlan
      echo sudo ip link set dev ${allInterfaces[0]}.$((i+1))00 up >> ../$thisFile      #levanta a nova interface
      echo sudo ip link set dev ${allInterfaces[0]}.$((i+1))00 master br$i >> ../$thisFile  #linka interface com a bridge. Essa é a interface entre roteadores 50/49
    done
    interfaces=`cat $eachSwitch | awk '{print $3}' | tac` #pega a lista de todas as interfaces ao contrario, para a interface entre switchs ficar na frente
    interfaces=`echo $interfaces  | cut -d " " -f2- `     #retira a interface 50/49
    read -a allInterfaces <<< $(echo $interfaces)         #transforma em array
    sizeArray=${#allInterfaces[@]}
    index=0     #numero da interface a ser atribuida
    for (( i=0; i < $((sizeArray/2)); i=i+1 )); do
      echo sudo ip link set dev ${allInterfaces[$index]} master br0 >> ../$thisFile  #coloca metade das maquinas na bridge br0
      index=$((index+1))
    done
    for (( i=0; i < $((sizeArray/2)); i=i+1 )); do
      echo sudo ip link set dev ${allInterfaces[$index]} master br1 >> ../$thisFile  #e a outra metade na bridge br1
      index=$((index+1))
    done
  done
else
##CRIA SWITCHS QUANDO REQUISITADO
  if [[ $createSwitchs == 1 ]]; then
    echo -e ${YELLOW}"Setting switch machines as ${BLUE}switchs"${NC}
    allSwitchs=`ls | grep switch`
    for eachSwitch in $allSwitchs; do
      thisFile=${eachSwitch}_setup.txt
      echo sudo ip link add name br0 type bridge >> ../$thisFile
      echo sudo ip link set dev br0 up  >> ../$thisFile
      allInterfaces=`cat $eachSwitch | awk '{print $3}'`
      for eachInterface in $allInterfaces; do
        echo sudo ip link set dev $eachInterface master br0 >> ../$thisFile
      done
    done
  fi
fi

##CRIA ROUTERS QUANDO REQUISITADO
if [[ $createRouters == 1 ]]; then
  echo -e ${YELLOW}"Setting routers machines as ${BLUE}routers"${NC}
  allRouters=`ls | grep router`
  allOob=`ls | grep oob`
  totalRouters=$allRouters" "$allOob
  turno=0
    for eachRouter in $totalRouters; do
        thisFile=${eachRouter}_setup.txt
        echo sudo sysctl -w net.ipv4.ip_forward=1 >> ../$thisFile  #habilita forward
        echo sudo ip route del 0/0 >> ../$thisFile                 #deleta default gateway
        read -a allInterfaces <<< $(cat $eachRouter | awk '{print $3}')    #bash cria array assim
        read -a allIps <<< $(cat $eachRouter | awk '{print $2}')
        sizeArray=${#allInterfaces[@]}
        for (( index=0; index < $sizeArray; index=index+1 )); do  #varre o array de ips para configurar a tabela de roteamento
          currentNetwork=`echo ${allIps[index]} | sed -r 's/(([0-9]{1,3}\.){3})[0-9]{1,3}/\10/g'`
          echo sudo ip route add $currentNetwork dev ${allInterfaces[index]} >> ../$thisFile
        done
        for (( index=0; index < $sizeArray; index=index+1 )); do #cria default gateway para os roteadores e oobs
          if [[ ${allInterfaces[index]} == eth50 ]]; then        #testa se é porta 50, que é a porta de comunicação entre intralevels com a 49, ou entre router e oob
            if [[ $eachRouter == *router* && $oob == 0 ]]; then  #se não existe oob então meu vizinho vai ter ip 2, pois eu sou o 1
              currentNetwork=`echo ${allIps[index]} | sed -r 's/(([0-9]{1,3}\.){3})[0-9]{1,3}/\12/g' | sed 's/\/24//'`
            elif  [[ $eachRouter == *router* ]]; then            #no cenario que existe oob, se eu sou o roteador, então o vizinho da porta 50 tera ip 1
               currentNetwork=`echo ${allIps[index]} | sed -r 's/(([0-9]{1,3}\.){3})[0-9]{1,3}/\11/g' | sed 's/\/24//'`
            else                                                 #entretanto, se sou o oob, então meu vizinho terá ip 2
               currentNetwork=`echo ${allIps[index]} | sed -r 's/(([0-9]{1,3}\.){3})[0-9]{1,3}/\12/g' | sed 's/\/24//'`
            fi
            echo sudo ip route add 0/0 via $currentNetwork dev eth50 >> ../$thisFile
            turno=1                                              #cria pares de maquinas 49 - 50 para evitar maquina no meio com dois enlaces
          fi
          if [[ ${allInterfaces[index]} == eth49 && $turno == 1 ]]; then #quando encontro uma porta 49, meu vizinho 50 sempre terá ip terminado em 1
            currentNetwork=`echo ${allIps[index]} | sed -r 's/(([0-9]{1,3}\.){3})[0-9]{1,3}/\11/g' | sed 's/\/24//'`
            echo sudo ip route add 0/0 via $currentNetwork dev eth49 >> ../$thisFile
            index=$sizeArray;
            turno=0
          fi
        done
    done
fi

##CRIA BGP
if [[ $bgp == 1 ]]; then
	echo -e ${YELLOW}"Setting ${BLUE}bgp ${YELLOW}protocol"${NC}
  allRouters=`ls | grep router`
  allOob=`ls | grep oob`
  totalRouters=$allRouters" "$allOob     #encontra todos as maquinas roteadoras
	for eachRouter in $totalRouters; do    #para cada maquina encontrada, implementar os comandos de bgp
		thisFile=${eachRouter}_setup.txt     #arquivo no qual os comandos serão salvos
    read -a allInterfaces <<< $(cat $eachRouter | awk '{print $3}')    #bash cria array assim
    read -a allIps <<< $(cat $eachRouter | awk '{print $2}')
    sizeArray=${#allInterfaces[@]}
		cp ../../Host_Scripts/bgpd.conf_template.txt ../BGP_Information/${eachRouter}bgpd.conf #copia para a pasta BGP_information uma copia do tamplate para cada roteador
		cp ../../Host_Scripts/zebra.conf_template.txt ../BGP_Information/${eachRouter}zebra.conf
		thisBGPFile="../BGP_Information/${eachRouter}bgpd.conf"        #determina o arquivo que será copiado pelo roteador assim como arquivos auxiliares
		auxBGPFile="../BGP_Information/${eachRouter}bgpd.confAux"
		thisZebraFile="../BGP_Information/${eachRouter}zebra.conf"
		auxZebraFile="../BGP_Information/${eachRouter}zebra.confAux"
		for (( index=0; index < $sizeArray; index=index+1 )); do  #para cada interface de rede
				bgpFileLineBase=`cat ../BGP_Information/${eachRouter}bgpd.conf | grep -n router-id | sed 's/:.*//'` #encontra a linha cujas infos de rede se encontram abaixo
				bgpFileLineTarget=$((bgpFileLineBase+1))                                                            #incrementa uma linha para escrever na linha de baixo
				currentNetwork=`echo ${allIps[index]} | sed -r 's/(([0-9]{1,3}\.){3})[0-9]{1,3}/\10/g'`				      #encontra a rede correspondente a porta e a nomeia com .0
				thisText="network $currentNetwork"                                                                  #determina o texto a ser escrito
				sed "$bgpFileLineTarget i $thisText" $thisBGPFile > $auxBGPFile                                     #escreve no arquivo auxiliar na linha determinada
				mv $auxBGPFile $thisBGPFile                                                                         #arquivo auxiliar se torna arquivo principal

				zebraFileLineBase=`cat ../BGP_Information/${eachRouter}zebra.conf | grep -n enable | sed 's/:.*//'` #procedimento abaixo é o mesmo que o acima, mas para zebra
				zebraFileLineTarget=$((zebraFileLineBase+1))
				currentNetwork=${allIps[index]}
				thisText="interface ${allInterfaces[index]}"				
				sed "$zebraFileLineTarget i $thisText" $thisZebraFile > $auxZebraFile
				mv $auxZebraFile $thisZebraFile				 

				thisText="ip address $currentNetwork"
				zebraFileLineTarget=$((zebraFileLineBase+2))
				sed "$zebraFileLineTarget i $thisText" $thisZebraFile > $auxZebraFile
				mv $auxZebraFile $thisZebraFile			

		done
		echo apt-get install quagga >> ../$thisFile                  #escreve no arquivo de config para baixar o quagga
		echo sudo sysctl -w net.ipv4.ip_forward=1 >> ../$thisFile    #habilita forward
		echo "sudo cat $thisBGPFile > /etc/quagga/bgpd.conf" >> ../$thisFile #escreve o arquivo gerado por cima do arquivo default do quagga 
		echo "sudo cat $thisZebraFile > /etc/quagga/zebra.conf" >> ../$thisFile
		echo sudo service zebra start >> ../$thisFile                #inicia os daemons
		echo sudo service bgpd start >> ../$thisFile
	done 
fi

#CRIA VXLAN 
if [[ $vxlan == 1 ]]; then
  echo -e ${YELLOW}"Setting ${BLUE}vxlan ${YELLOW}protocol"${NC}
  allRouters=`ls | grep router` #recupera lista de todas as maquinas roteadores (por definição, maquinas oob não devem ter nenhuma configuração)
  i=1
  for eachRouter in $allRouters; do
    thisFile=${eachRouter}_setup.txt
    echo sudo ip link add br0 type bridge >> ../$thisFile  #cria a bridge na qual vai ser ligada a interface vxlan de saída com a interface local de entrada
    echo sudo ip link set br0 up  >> ../$thisFile          #levanta a interface
    read -a allInterfaces <<< $(cat $eachRouter | awk '{print $3}' | tac)
    echo sudo ip link add name vxlan10 type vxlan id 10 dev ${allInterfaces[0]} group 239.1.1.1 dstport 4789  >> ../$thisFile #cria uma interface vxlan ligada a eth50
    #necessario criar ip?
    echo sudo ip link set dev eth1 master br0 >> ../$thisFile   #linka via bridge a eth de saida com a eth de entrada
    echo sudo ip link set dev vxlan10 master br0 >> ../$thisFile
    echo sudo ip link set vxlan10 up  >> ../$thisFile     #levanta interface de saída
    myId=`echo $eachRouter | sed 's/router//' | sed 's/txt//'` #depois de ter configurado vxlan nos roteadores, é necessario configurar novo ip para servidores
    if [ -e ./server${myId}1.1.txt ]; then                     #existem duas possibilidades, ou abaixo do router tem switch ou não. Testamos isso pelo nome do servidor
      for (( index = 1; index < $((server+1)) ; index=index+1 )); do #caso exista roteadores, é preciso mudar todos os membros abaixo do switch.x.1.1
        serverId=server${myId}1.$index                               #é descoberto o nome das maquinas contidas abaixo da eth1 do router
        thisFile=${serverId}.txt_setup.txt
        echo sudo ip addr add 100.100.100.$i/24 dev eth50 >> ../$thisFile #criado novo range de ip que servira para vms abaixo do switch1 dos routers
        i=$((i+1))
      done
    else       #no caso de existir somente um servidor abaixo da eth1
      serverId=server${myId}1  #é descoberto o nome da maquina
      thisFile=${serverId}.txt_setup.txt
      echo sudo ip addr add 100.100.100.$i/24 dev eth50 >> ../$thisFile #é criado um novo range de ip
      i=$((i+1))
    fi
  done
fi

#CRIA ARQUIVO DE HOSTNAME
echo -e ${YELLOW}"Setting ${BLUE}hostnames"${NC}
while read line; do
  ip=`echo $line | awk '{print $2}' | sed 's/\/24//'`
  hostname=`echo $line | awk '{print $1}'`
  echo $ip $hostname >> ./hostnames.txt
done<../../ipList.txt
for eachFile in $listOfFiles; do
  thisFile=${eachFile}_setup.txt
  echo "cat /vagrant/Guest_Scripts/Interface_Information/hostnames.txt > /etc/hosts" >> ../$thisFile
done

#CRIA ARQUIVO VAGRANT FILE
cd ../../ && chmod -R 777 ./
echo "Creating Vagrantfile"
python ./reader.py ./topology.dot -p libvirt

#LEVANTA AS MAQUINAS
echo -e ${YELLOW}"Creating machines"${NC}
vagrant up
sleep 20

#CONFIGURA AS MAQUINAS
allMachines=`ls Guest_Scripts/Interface_Information/ | grep -v hostname | sed 's/.txt//'`
for eachMachine in $allMachines; do
  thisfile=${eachMachine}.txt_setup.txt
  echo -e ${YELLOW}"Running machine ${BLUE}${eachMachine} ${YELLOW}configs"${NC}
  vagrant ssh $eachMachine -c "sudo /vagrant/Guest_Scripts/$thisfile"
done
