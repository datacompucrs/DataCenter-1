para criação da topologia requisitada, necessário rodar o comando

./converter.sh <Numero de TORs> <Numero de Servers> <memoria>

Note que é importante conferir a quantidade de memória alocada para cada máquina. Para topologia com 2 tors,
cada um com dois servidores, foram alocados 700Mb por máquina.
Para mudar a quantidade de memória, atualmente é necessário atualizar o script .sh

o script converter.sh gera um arquivo topology.dot.
Arquivos .dot podem ser abertos pelo programa Dot Viewer, o qual desenha em formato de grafo a topologia descrita.
Este arquivo é lido pelo por topology_converter.py para a geração do Vagrantfile


Para rodar o Vagrantfile é necessário estar na pasta e rodar o comando.
Vagrant up

e em seguida,

Vagrant ssh <Nome da máquina>

Vagrant destroy -f deleta a topologia criada

Em caso de erro envolvendo nome de dominio é importante notar que existe a possibilidade do nome já ter sido usado
por outro Vagrantfile, neste caso:

Lista nomes
virsh list --all

deleta nomes
virsh undefine <id> <name>
