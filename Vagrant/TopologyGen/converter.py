# -*- coding: utf-8 -*-
import sys
import os
import time
from collections import namedtuple
from treelib import Tree, Node
import types

possibleNames = ["\"oob$\"", "\"router$\"", "\"switch$\"", "\"server$\""]
texts = " [function=\"leaf\" vagrant=\"eth1\" os=\"hashicorp/bionic64\" version=\"1.0.282\" memory=\"500\" config=\"./helper_scripts/config_production_switch.sh\" ] \n"
connections = "\"!\":\"@\" -- \"$\":\"%\"\n"

tree = Tree();

argNumber = 7

###############################
###############################
##PARSER
###############################
###############################

def getOtherLevels(arguments, lastLevel, i):       #necessario para descobrir se existem outros leveis de comunicacao alem de servidor, switch, roteador
	if (lastLevel == 0) :                          #confere a ultima camada vista, este valor muda caso exista uma opcao como --l3 e em seguida um salto --l5
		newLevels = int(str(sys.argv[i])[-1:]) - 2 #no primeiro instante retira 2 referente as 3 camadas default(0,1,2), isso ajuda a saber quantas camadas foram adicionadas (--l3 e uma camada extra pois 3-2 =1)
		lastLevel = int(str(sys.argv[i])[-1:])     #salva o last level diferente de zero
	else:
		lastLevel = int(str(sys.argv[i])[-1:])
	for eachLevel in range(1, newLevels+1):                #para cada nova camada de maquinas, é adicionado maquinas extras. Por exemplo, no comando -l5 2, serao criadas 1 maquina para l3 uma para l4 e 2 para l5
		if (eachLevel == newLevels):                       #responsavel por colocar o valor setado no argumento para a camada requisitada
			arguments.append(int(str(sys.argv[i+1])))
		else:
			arguments.append(1)
	return arguments, lastLevel

def checkForNullValues(arguments):                 #define valores padroes para variaveis nao setadas
	if (arguments[0] == None): arguments[0] = 500
	if (arguments[1] == None): arguments[1] = "hashicorp/bionic64"
	if (arguments[2] == None): arguments[2] = 0
	if (arguments[3] == None): arguments[3] = 1
	if (arguments[4] == None): arguments[4] = 0
	if (arguments[5] == None): arguments[5] = 0
	if (arguments[6] == None): arguments[6] = 0
	return arguments

def parseArgs():                                      #realiza o parser dos argumentos vindos do prompt
	arguments = [None] * argNumber                    #cria uma lista prenchida com zeros de N posicoes
	lastLevel = 0                                     #valor padrao necessario para permitir insercao de camadas extras pulando as demais, exemplo digitar --l5 sem digitar --l3 e --l4
	for i in range(len(str(sys.argv).split())):
		if (str(sys.argv[i]) == "-m"): arguments [0] = str(sys.argv[i+1])
		elif (str(sys.argv[i]) == "-l"): arguments [1] = str(sys.argv[i+1])
		elif (str(sys.argv[i]) == "-o"): arguments [2] = str(sys.argv[i+1])
		elif (str(sys.argv[i]) == ("--l" + '0')): arguments [3] = int(str(sys.argv[i+1]))
		elif (str(sys.argv[i]) == ("--l" + '1')): arguments [4] = int(str(sys.argv[i+1]))
		elif (str(sys.argv[i]) == ("--l" + '2')): arguments [5] = int(str(sys.argv[i+1]))
		elif (str(sys.argv[i]) == ("--l" + '3')): arguments [6] = int(str(sys.argv[i+1]))
		#elif ("--l" in str(sys.argv[i])) :            #procura se existe mais layers que as padroes
		#	arguments, lastLevel = getOtherLevels(arguments, lastLevel, i)
	arguments = checkForNullValues(arguments)         #preenche valores vazios
	return arguments

###############################
###############################
##CREATE TREE TOPOLOGY
###############################
###############################


def writeTree(machineNumbers, file, baggage, parentName, index):
	while(machineNumbers[index] == 0):    #procura o index aonde comeca a arvore, imaginando que possa nao existir um dos niveis
		index = index +1
	machineName = possibleNames[index]                  #array de strings que contem as possibilidades de nomes de maquinas
	for i in range(1,machineNumbers[index]+1):          #cria a arvore usando i como bagagem do nome (e.g se o pai é .1 o primero filho será .1.1)
		newbaggage = baggage + str('.'+str(i))          #cria a bagagem em relacao ao pai
		thisName = machineName.replace("$",newbaggage)  #replace na string do texto padrao
		tree.create_node(thisName, thisName, parent=parentName) #adiciona um nodo a arvore colocando o novo nome como filho e o nome recebido de cima como pai
		thisText = thisName + texts
		file.write(thisText)                                    #escreve no .dot
		if (index != 3):                                        #caso nao chegou na criacao da folha, inicia recursao
			writeTree(machineNumbers, file, newbaggage, thisName, index+1)

def writeConnections(file, parent):
	i = 1;
	topLevelText = connections.replace("!",str(tree.get_node(parent).tag).replace("\"",""))  #texto padrao colocando o pai como uma das conexoes
	for eachParent in tree.children(parent):                                                 #para cada filho do nodo pai
		topLevelConnection = topLevelText.replace("$",str(eachParent.tag).replace("\"",""))  #cria a string desejada agora alterando o filho
		topLevelConnection = topLevelConnection.replace("@","eth"+str(i))
		topLevelConnection = topLevelConnection.replace("%","eth"+str(50))
		i = i +1
		if(not("root" in topLevelConnection)):                                               #descobre se é uma conexao com o root, a qual eh uma conexao fantasia
			file.write(topLevelConnection)                                                   #adiciona a conexao valida entre pai e filho
		childLevelText = connections.replace("!",str(eachParent.tag).replace("\"",""))       #altera o texto para colocar o filho como pai, criando uma conexao com os netos
		j = 1
		for eachChildren in tree.children(eachParent.tag):
			thisConnection = childLevelText.replace("$",str(eachChildren.tag).replace("\"","")) #cria um novo texto, isso eh necessario pois assim pode-se calcular qual o numero correto da eth
			thisConnection = thisConnection.replace("@","eth"+str(j))
			thisConnection = thisConnection.replace("%","eth"+str(50))
			j=j+1
			file.write(thisConnection)
			writeConnections(file, eachChildren.tag)                                            #se tem filhos, entao faz recursao
	file.write("\n")

def createTopLevelConnection (file, parent):
		allChildren = tree.children(parent)
		if(len(allChildren)-1 == 0): return          #se eh um pai "solteiro" retorna
		for i in range(0, len(allChildren)-1):       #no range de todos os filhos do root, cria ligacao entre irmaos.
			firstConnection = connections.replace("!",str(allChildren[i].tag).replace("\"",""))
			firstConnection = firstConnection.replace("$",str(allChildren[i+1].tag).replace("\"",""))
			firstConnection = firstConnection.replace("@","eth"+str(50))
			firstConnection = firstConnection.replace("%","eth"+str(49))
			file.write(firstConnection)

def createDot(machineNumbers):

	baggage   = ""
	if os.path.exists("topology.dot"): os.remove("topology.dot")
	file = open("topology.dot","w+")
	file.write("graph vx {\n")

	writeTree(machineNumbers, file, "", "root", 0)
	tree.show(key=lambda x: x.tag, reverse=True, line_type='ascii-em')
	writeConnections(file, "root")
	createTopLevelConnection(file, "root")

	file.write("\n}")
	file.close()

###############################
###############################
##CREATE NETWORKS
###############################
###############################


def getNumberOfNetwork(machineNumbers):
	if(machineNumbers[0] == 0 and machineNumbers[1] == 0): #se nao existem roteadores, entao so existe um dominio de ip
		return 1
	else:
		bottomNetworks = machineNumbers[2] if machineNumbers[2] != 0 else machineNumbers[3] #as redes de baixo sao os servidores ou switchs (switchs nao tem ip, mas podem definir "barreiras" entre redes).
		middleNetworks = machineNumbers[1] if machineNumbers[1] != 0 else machineNumbers[0] #as redes do meio sao os roteadores, neste caso out of bounds toma lugar dos roteadores caso eles n existam
		topNetworks = 1 if machineNumbers[0] != 0 else 0                                    #redes que tenho entre roteadores e oob
		oobNetworks = machineNumbers[0] if machineNumbers[0] != 0 else 1                    #quantidade de oob que possuo

		index = 0 if machineNumbers[0] != 0 else 1
		intraNetworks = machineNumbers[index]-1
		allNetworks = (((bottomNetworks * middleNetworks) + (middleNetworks* topNetworks)) * oobNetworks) + intraNetworks #o meu numero de redes, sao as redes inferiores dos roteadores + as redes superiores vezes o numero de redes superiores + a conexao entre essas redes
		return allNetworks

def generateIpNetworks(numberOfNetworks):
	standartIp = "!.!.!.%/24" #ip padrao a ser alterado
	allIPNetworks = []
	for i in range(1, numberOfNetworks+1):
		thisIp = standartIp.replace("!",str(i))
		thisIp = thisIp.replace("%",str(0))
		allIPNetworks.append(thisIp)
	return allIPNetworks

def giveLeafsIp(allIpNetworks, machineNumbers):
	i = 0;
	childList = tree.leaves("root") #salva todos os filhos da raiz
	if (machineNumbers[0] == 0 and machineNumbers[1] == 0): #no caso de nao existirem roteadores, entao todas as maquinas pertencem a mesma rede
		currentIp = allIpNetworks.pop(0)                    #retira o unico dominio criado de ip
		for eachChild in childList:                         #para cada servidor cria um ip novo. Ips nao podem terminar em 0 e nao devem terminar em 1 (reservado ao roteador)
			thisIp = currentIp.replace("0/",str(i+2)+"/");
			i = i +1
			eachChild.data = thisIp
	elif (machineNumbers[2] != 0):                          #caso existam roteadores no meio
		index = 0
		while(machineNumbers[index] == 0): index = index + 1 #procura saber quem eh o nivel acima do switch (router ou oob)
		leavesNetworks =  machineNumbers[0] * machineNumbers[1] * machineNumbers[2] if (machineNumbers[0] != 0 and machineNumbers[1] != 0) else machineNumbers[index] * machineNumbers[2]   #minha quantidade de redes a serem retiradas serao o numero de roteadores pelo numero de switchs
		i = 0
		for j in range(0, leavesNetworks):
			currentIp = allIpNetworks.pop(0)                 #pega o ip a ser utilizado na rede do filho
			currentParent = tree.parent(childList[i].tag)    #guarda o ip no switch, para o pai roteador pegar no futuro
			currentParent.data = currentIp
			for k in range(machineNumbers[3]):               #este laco itera por maquina no dominio de ip, enquanto a maquina e selecionada pela variavel i criada antes dos lacos
				thisIp = currentIp.replace("0/",str(k+2)+"/")
				childList[i].data = thisIp
				i = i + 1
	else:
		routerNumber = machineNumbers[1] if machineNumbers[1] != 0 else 1  #em ambiente com roteadores, descobre a quantidade de routers e oobs
		oobNumber = machineNumbers[0] if machineNumbers[0] != 0 else 1
		for i in range(0, oobNumber * routerNumber * machineNumbers[3]):  #se nao existe switchs, a quantidade de redes sera o numero de servidores vezes numero de roteadores
			currentIp = allIpNetworks.pop(0)
			thisIp = currentIp.replace("0/",str(2)+"/")
			childList[i].data = thisIp

def giveRoutersIp(allIpNetworks, machineNumbers, parent):
	children = tree.children(parent)   #retorna todos os filhos de um determinado pai
	thisNode = tree.get_node(parent)   #retorna o nodo pai
	childrenIpList = []                                             #como existem varias redes conectadas a um roteador, aqui eh criado uma lista vazia para agregar esses valores
	for eachChild in children:
		if("switch" in eachChild.tag or "server" in eachChild.tag): #se os filhos sao switchs ou servidores, isso equivale a chegar nas folhas da arvore
			thisEthIp = eachChild.data                              #o ip de uma determinada eth para um nodo acima das folhas sera o ip contido na folha, criando a conexao entre folha e roteador
			bufferIp = thisEthIp.split('.')[:3]
			thisEthIp = str(bufferIp[0]) + '.' + str(bufferIp[0]) + '.' + str(bufferIp[0]) + ".1/24" #quebra o valor x.x.x.y/24 em um valor x.x.x.1 reservado ao roteador, valendo para as N redes conectadas no router/oob em layers abaixo
			childrenIpList.append(thisEthIp)
		else:
			giveRoutersIp(allIpNetworks, machineNumbers, eachChild.tag) #no caso do nodo nao ter folhas logo abaixo(tratando folhas como server OU switchs), realizamos a recursao, o que significa que existe oob e router nessa topologia
			thisEthIp = eachChild.data
			bufferIp = thisEthIp[-1]
			bufferIp = bufferIp.split('.')[:3]
			thisEthIp = str(bufferIp[0]) + '.' + str(bufferIp[0]) + '.' + str(bufferIp[0]) + ".1/24" #cria a ligacao entre o nodo pai .1 com o nodo filho .2
			childrenIpList.append(thisEthIp)
	if (thisNode.tag != "root"):                                        #aqui eh atribuido o ip entre o nodo filho .2 e o nodo pai .1, mas esse nao existe para o nodo fantasia raiz
		if (tree.parent(thisNode.tag).tag != "root"):	                #linha de cima testa o novo raiz enquanto esta linha testa se o nodo pai eh a raiz
			thisIp = allIpNetworks.pop(0) if len(allIpNetworks) != 0 else allIpNetworks   #testa se valor eh lista o string, para retirar o dominio final de ip
			bufferIp = thisIp.split('.')[:3]
			thisEthIp = str(bufferIp[0]) + '.' + str(bufferIp[0]) + '.' + str(bufferIp[0]) + ".2/24"
			childrenIpList.append(thisEthIp)
		thisNode.data = childrenIpList       #por fim, apos a recursao, adiciona os ips criados ao campo de payload do nodo


def giveIntraConnectionIp(allIpNetworks, machineNumbers, parent):
	child = tree.children(parent)
	for i in range(0, len(child)):  #este laco roda por todos os filhos da raiz indexando por I para poder retirar nodos vizinhos como em um array
		if(i != 0):                 #testa se este eh o primeiro nodo, sem vizinhos a sua esquerda
			bufferIPList = child[i].data     #caso nao seja o primeiro nodo, a ideia eh retirar seu payload e o payload do vizinho
			siblingIPList = child[i-1].data
			bufferIp = siblingIPList[-1]     #retirar o ultimos valor adicionado a este (que sempre sera o ip atribuido a conexao entre os mesmos niveis)
			bufferIp = bufferIp.split('.')[:3]
			thisEthIp = str(bufferIp[0]) + '.' + str(bufferIp[0]) + '.' + str(bufferIp[0]) + ".2/24"
			bufferIPList.append(thisEthIp)  #adiciona o valor criado a lista de payload atual
			child[i].data = bufferIPList
		if (i != len(child)-1):		#testa se este eh o ultimo nodo, sem vizinhos a direita
			bufferIPList = child[i].data #caso nao seja o ultimo, a ideia eh retirar seu payload para adicionar novo valor a este
			thisIp = allIpNetworks.pop(0) if len(allIpNetworks) != 0 else allIpNetworks
			bufferIp = thisIp.split('.')[:3]
			thisEthIp = str(bufferIp[0]) + '.' + str(bufferIp[0]) + '.' + str(bufferIp[0]) + ".1/24"
			bufferIPList.append(thisEthIp)
			child[i].data = bufferIPList
#aqui eh importante notar que um nodo intermediario ira cair nos dois ifs



def provideIp(allIpNetworks, machineNumbers, parent):
	giveLeafsIp(allIpNetworks, machineNumbers)
	if(machineNumbers[0] != 0 or machineNumbers[1] != 0 ): #nao existindo roteadores, nao existe atribuicao de ip entre mesma layers, nem ip entre roteadores
		giveRoutersIp(allIpNetworks, machineNumbers, "root")
		giveIntraConnectionIp(allIpNetworks, machineNumbers, "root")


def matchIpAndEth(parent, file):                    #OK..... esse precisa ser otimizado no futuro....
	children = tree.children(parent)                #recupera todos os nodos filhos de um determinado pai
	thisNode = tree.get_node(parent)                #recupera o nodo deste pai
	l = 0                                           #lenght lateral da arvore no nivel referente as conexoes intra level
	if(len(children) != 0):                         #se ele nao possui nenhum filho, entao o nodo eh uma folha, encerrando a recursao
		k = 0                                       #variavel que calcula qual das maquinas switchs esta se conectando com qual
		for eachChild in children:
			if (isinstance(eachChild.data, types.StringTypes)) :  #procura se o nodo tem somente um filho. isso so ira ocorrer para folhas, e no caso de haver somente um roteador/switch como ramo
				if not ("switch" in eachChild.tag):               # se ele for um switch, entao nao tem ip associado
					currentEth = "eth50" if ("server" in eachChild.tag) else "eth1"	 #se ele for servidor entao a ligacao esta acima, se for outro, a ligacao esta abaixo
					file.write(eachChild.tag.replace("\"","") + " " +  eachChild.data + " " + currentEth + "\n")
				else:                                             #caso a maquina seja um switch, eh necessario criar as N +1 interfaces sem ips
					i = 1
					for eachGrandChild in tree.children(eachChild.tag): #uma interface para cada servidor
						file.write(eachChild.tag.replace("\"","") + " " +  "0.0.0.0/24" + " eth"+ str(i) +"\n")
						i = i+1
					file.write(eachChild.tag.replace("\"","") + " " +  "0.0.0.0/24" + " eth"+ str(50) +"\n") #uma interface extra para a conexao com router
			elif (eachChild.data != None):             #agora, caso a maquina seja um roteador
				i = 1                                  #esta i ira concatenar com o nome eth para gerar as interfaces dos filhos eth1 eth2 ethN
				currentEth = ""
				flagLeftNeigh = True                   #para uma maquina com conexoes entre as layers, havera 3 casos, esta flag controla o caso 3, onde existem maquinas no meio das outras
				for eachData in eachChild.data:  #Each ETH as a network device
					if(i != len(tree.children(eachChild.tag))+1):  #enquanto estiver no dominio dos filhos, a maquina ira criar uma eth menor que 50
						currentEth = "eth"+str(i)
						i = i+1
						file.write(eachChild.tag.replace("\"","") + " " +  eachData + " " + currentEth + "\n")
					else:
						if(tree.parent(eachChild.tag).tag == "root"):  #estando fora no dominio dos filhos, eh testado se a proxima conexao eh entre os levels ou para roteadores acima
							if(l == 0):                                #no primeiro caso, a maquina eh a primeira, entao so tem conexao para direita
								each_eth = "eth50"
							elif(l == len(tree.siblings(eachChild.tag))+1): #no segundo caso, a maquina eh a ultima, entao so tem conexao para esquerda
								each_eth = "eth49"
							elif (flagLeftNeigh == True): #no caso três, existem duas conexoes por maquina, a 49 a esquerda e a 50 a direita
								each_eth = "eth49"
								flagLeftNeigh = False
							else:
								each_eth = "eth50"
								flagLeftNeigh = True
							file.write(eachChild.tag.replace("\"","") + " " +  eachData + " " + each_eth +"\n")
						else:                             #caso a conexao nao seja nenhuma das anteriores, entao eh uma conexao para um roteador num level acima
							currentEth = "eth"+str(50)
							file.write(eachChild.tag.replace("\"","") + " " +  eachData + " " + currentEth + "\n")

			else:                                          #para topologias somente com switchs e servidores
				i = 1
				for eachGrandChild in tree.children(eachChild.tag): #para cada filho do switch, eh criado uma nova interface eth
					file.write(eachChild.tag.replace("\"","") + " " +  "0.0.0.0/24" + " eth"+ str(i) +"\n")
					i = i+1
				if(k != 0):                                          #no caso de so existirem switchs, eh criada conexoes entre switchs
					file.write(eachChild.tag.replace("\"","") + " " +  "0.0.0.0/24" + " eth"+ str(49) +"\n")
				if(k != len(tree.siblings(eachChild.tag))):
					file.write(eachChild.tag.replace("\"","") + " " +  "0.0.0.0/24" + " eth"+ str(50) +"\n")
				k = k+1                                             #busca proxima maquina interconectada com switchs
			matchIpAndEth(eachChild.tag, file)                      #faz o processo de recursao
			l = l +1                                                #busca proximo vizinho no caso de roteadores



def createIps(machineNumbers):
	if os.path.exists("ipList.txt"): os.remove("ipList.txt")
	file = open("ipList.txt","w+")


	numberOfNetworks = getNumberOfNetwork(machineNumbers)
	allIpNetworks = generateIpNetworks(numberOfNetworks)
	provideIp(allIpNetworks, machineNumbers, "root")
	matchIpAndEth("root",file)

	file.close()


###############################
###############################
##MAIN
###############################
###############################


def main():
	arguments = parseArgs()

	memory    = arguments[0]
	linux     = arguments[1]
	oobRouter = arguments[6]        #out of bound routers
	routers   = arguments[5]
	switchs   = arguments[4]
	servers   = arguments[3]
	machineNumbers = []
	tree.create_node("root", "root")
	machineNumbers.extend([oobRouter, routers, switchs, servers])

	createDot(machineNumbers)
	createIps(machineNumbers)


#-----------------------------------------------------
if __name__ == '__main__': # chamada da funcao principal
    main()
