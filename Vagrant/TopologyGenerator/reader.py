# -*- coding: utf-8 -*-
## Rafael Basso
## .dot --> vagrantfile
## ~$ python3 reader.py [topology.dot] [-option]
##

##	OK = '\033[92m'
##	FAIL = '\033[93m'

#
#IMPORTS
#

import argparse
import sys
import pydotplus
import jinja2
import bcolors

#
#GLOBAL VARS
#

VERSION = "0.1.0"
VAGRANT_FILE_TEMPLATE = "vagrantfile_template.j2"
VAGRANT_FILE = "Vagrantfile"
ARG_STRING = ""
TOPOLOGY_FILE = ""
PROVIDER = ""
STATS = 0

START_MAC = "443839000000"
TUNNEL_IP = ""
START_PORT = 8000
PORT_GAP = 1000

#
#FUNCTIONS
#

##
#Funcao responsavel por ler o template do vagrantfile e
#renderizar o arquivo com as configuracoes da topologia desejada
##
def jinja2_template(devices):
	print(bcolors.OK + "\t#  " + bcolors.END + "RENDERING: " + VAGRANT_FILE_TEMPLATE +  " --> " + VAGRANT_FILE)
	#le arquivo do template
	template = jinja2.Template(open(VAGRANT_FILE_TEMPLATE).read())
	#renderiza o template lido previamente com as informacoes extraidas da topologia
	with open(VAGRANT_FILE, 'w') as outfile:
		outfile.write(template.render(devices=devices,
                                          synced_folder=False,
                                          provider=PROVIDER,
                                          version=VERSION,
                                          topology_file=TOPOLOGY_FILE,
                                          arg_string=ARG_STRING,
                                          #epoch_time=epoch_time,
                                          #script_storage=script_storage,
                                          #generate_ansible_hostfile=generate_ansible_hostfile,
                                          #create_mgmt_device=create_mgmt_device,
                                          #function_group=function_group,
                                          #network_functions=network_functions,
                                          )
                         )
##
#Funcao responsavel por ordenar a lista de dispositivos da topologia
##
def sort_key(device):
	if device['function'] == "leaf": return 1
	elif device['function'] == "tor":return 2
	elif device['function'] == "host":return 3
	else: return 4

##
#Funcao responsavel por adicionar dispositvos que estao armazenados em um inventario
#em uma lista. Isso facilita a renderizacao do arquivo de saida
##
def add_to_list(inv):
	devices = []

	print(bcolors.OK + "\t#  " + bcolors.END + "PUTTING INVENTORY DEVICES INTO A LIST")
	for device in inv:
		devices.append(inv[device])
	print(bcolors.OK + "\t#  " + bcolors.END + "SORTING LIST")
	devices.sort(key=sort_key)

	##########################
	if STATS == 1:
		print_devices(devices)

	return devices

##
#Funcao responsavel por printar a lista de ports utilizados
##
def print_port_list(port_list):
	print("\n**".ljust(10) + "**".rjust(20))
	print("*".ljust(10) + "PORT LIST" + "*".rjust(10))
	print("**".ljust(10) + "**\n".rjust(20))
	print(port_list)

##
#Funcao responsavel por printar a lista de macs utilizados
##
def print_mac_list(mac_list):
	print("\n**".ljust(10) + "**".rjust(20))
	print("*".ljust(10) + "MAC LIST" + "*".rjust(11))
	print("**".ljust(10) + "**\n".rjust(20))
	print(mac_list)

##
#Funcao responsavel por formatar o endereco de mac
#ex.: "443839000000" --> "44:38:39:00:00:00"
##
def add_mac_div(mac_addr):
	index = 0
	new_mac = ""

	for char in mac_addr:
		if index % 2 == 0 and index != 0:
			new_mac = new_mac + ":"
		new_mac = new_mac + char
		index+=1

	return new_mac

##
#Funcao responsavel por gerar um endereco de mac para o dispositvo
##
def mac_fecth(mac_list):
	global START_MAC

	while 1:
		#transforma uma string (start_mac) em um inteiro de base 16
		#soma 1 e transforma novamente em string
		new_mac = ("%x" % (int(START_MAC, 16)+1)).lower()
		START_MAC  = new_mac
		if new_mac not in mac_list:
			new_mac = add_mac_div(new_mac)
			mac_list.append(new_mac)
			break

	return new_mac

##
#Funcao responsavel por extrair o dispositivo e sua interface
##
def extract_device(edge_str):
	vet = {}

	edge_str = edge_str.replace('"' or "'", "")
	idx = edge_str.find(":")
	#vet[0] contem o nome do dispositivo vet[1] contem a interface desse dispositivo
	vet = [edge_str[0:idx], edge_str[idx+1:]]

	return vet

##
#Funcao responsavel por linkar um dispositivo no outro
##
def link(left_device, left_mac, left_port, right_device, right_interface, right_port):
	inv = {}

	inv['local_interface'] = left_device
	inv['local_ip'] = TUNNEL_IP
	inv['local_port'] = left_port
	inv['mac'] = left_mac
	inv['remote_device'] = right_device
	inv['remote_interface'] = right_interface
	inv['remote_ip'] = TUNNEL_IP
	inv['remote_port'] = right_port

	return inv

##
#Funcao responsavel por extrair as conexoes dos dispositivos e montar estrutura de interfaces
#ex.: "server-A0":"eth1" -- "tor-A":"swp1"
##
def parse_edge_list(edge_list, inv):
	mac_list = []
	port_list = []

	net_num = 1
	#percorre lista de edges
	for edg in edge_list:
		left_device = extract_device(edg.get_source())
		right_device = extract_device(edg.get_destination())

		left_port = START_PORT + net_num
		right_port = START_PORT + PORT_GAP + net_num

		left_mac = mac_fecth(mac_list)
		source_link = link(left_device[1], left_mac, left_port, right_device[0], right_device[1],  right_port)

		right_mac = mac_fecth(mac_list)
		destination_link = link(right_device[1], right_mac, right_port, left_device[0], left_device[1], left_port)

		inv[left_device[0]]['interfaces'].append(source_link)
		inv[right_device[0]]['interfaces'].append(destination_link)

		port_list.append(left_port)
		port_list.append(right_port)
		net_num+=1

	#adc interface eth0 para leafs
	for device in inv:
		if inv[device]['function'] != 'leaf': continue

		left_port = START_PORT + net_num
		right_port = START_PORT + PORT_GAP + net_num
		mac_eth0 = mac_fecth(mac_list)
		link_eth0 = link('eth0', mac_eth0, left_port, 'NOTHING', 'NOTHING', right_port)
		inv[device]['interfaces'].append(link_eth0)

		port_list.append(left_port)
		port_list.append(right_port)
		net_num+=1

	##############################
	if STATS == 1:
		print_mac_list(mac_list)
		print_port_list(port_list)

##
#Funcao responsavel por printar o inventario de dispositivos
##
def print_inventory(inv):
	print("\n**".ljust(10) + "**".rjust(20))
	print("*".ljust(10) + "INVENTORY" + "*".rjust(10))
	print("**".ljust(10) + "**\n".rjust(20))


	for node in inv:
		print(node)
		for attr in inv[node]:
			if attr != 'interfaces':
				frt = 10 - len(attr)
				print("- " + attr + ":".ljust(frt + 10) + inv[node][attr])
			else:
				print("- " + attr + ":".ljust(11))
				for interface_list in inv[node][attr]:
					for int_attr in interface_list:
						frt2 = 10 - len(int_attr)
						print("".ljust(21), int_attr + ":".ljust(frt2 + 10), interface_list[int_attr])
					print("\n")

		print("\n")

##
#Funcao responsavel por printar a lista de dispositivos
##
def print_devices(devices):
	print("\n**".ljust(10) + "**".rjust(20))
	print("*".ljust(9) + "DEVICE LIST" + "*".rjust(9))
	print("**".ljust(10) + "**\n".rjust(20))
	for device in devices:
		print(device['host_name'])
	print("\n")

##
#Funcao responsavel por extrair as configuracoes de cada dispositivo
#ex.: "tor-A" [function="leaf" vagrant="eth1" os="hashicorp/bionic64" version="1.0.282" memory="500" ]
##
def parse_node_list(node_list, inv):
	#percorre lista de nodos
	for nd in node_list:
		nd_name = nd.get_name().replace('"' or "'", "")
		inv[nd_name] = {}
		attr_list = nd.get_attributes()

		#percorre lista de atributos dos nodos
		for attr in attr_list:
			inv[nd_name][attr] = nd.get(attr).replace('"' or "'", "")

		inv[nd_name]['host_name'] = nd_name

		#if provider == libvirt
		inv[nd_name]['tunnel_ip'] = TUNNEL_IP
		#inicializa a lista de interfaces
		inv[nd_name]['interfaces'] = []

def read_dot_file():
	with open(TOPOLOGY_FILE,"r") as topo_file:
		line_list=topo_file.readlines()
		count=0
		for line in line_list:
			count +=1

##
#Funcao responsavel por extrair as informacoes das topologias (topology.dot)
##
def parse_dot_file():
	print(bcolors.OK + "\t#  " + bcolors.ENDC + "EXTRACTING GRAPH FROM DOT FILE")
	try:
		topology = pydotplus.graphviz.graph_from_dot_file(TOPOLOGY_FILE)
	except Exception as e:
		print(bcolors.FAIL + "\t#  " + bcolors.END + "ERROR: " + "(%s)", e)
		exit(1)

	try:
		node_list = topology.get_node_list()
	except Exception as e:
		print(bcolors.FAIL + "\t#  " + bcolors.END + "ERROR: " + "(%s)", e)
		exit(1)

	try:
		edge_list = topology.get_edge_list()
	except Exception as e:
		print(bcolors.FAIL + "\t#  " + bcolors.END + "ERROR: " + "(%s)", e)
		exit(1)

	inv = {}
	print(bcolors.OK + "\t#  " + bcolors.END + "PARSING NODES")
	parse_node_list(node_list, inv)
	print(bcolors.OK + "\t#  " + bcolors.END + "PARSING EDGES")
	parse_edge_list(edge_list, inv)

	########################
	if STATS == 1:
		print_inventory(inv)

	return inv

##
#Funcao responsavel por identificar o provider passado por parametro.
#Por enquanto suporta apenas libvirt
##
def set_provider():
	global TUNNEL_IP
	if PROVIDER == "libvirt":
		TUNNEL_IP = "127.0.0.1"

##
#Funcao responsavel por testar se o argumento passado por parametro tem sufixo .dot
##
def is_dot_file(dot_file):
	index = dot_file.find(".dot")
	if index != -1: return 0
	else: return -1

##
#Funcao responsavel por fazer o parser dos argumentos
##
def parser():
	global TOPOLOGY_FILE
	global STATS
	global ARG_STRING
	global PROVIDER

	parser = argparse.ArgumentParser(description='Topology Converter -- Convert topology.dot files into Vagrantfiles')

	parser.add_argument('dot_file', help='Choose the topology file')

	parser.add_argument('-p', '--provider', choices=["libvirt"],
				help='Choose the provider \{libvirt}')

	parser.add_argument('-st','--stats', action="store_true",
                help='Show all data recovered and all preocess')

	parser.add_argument('--version', action='version', version="Topology Converter version is v%s" % VERSION,
                help='Using this option displays the version of Topology Converter')

	args = parser.parse_args()
	ARG_STRING = " ".join(sys.argv)

	if args.stats: STATS = 1

	if args.provider: PROVIDER = args.provider

	if args.dot_file:
		if is_dot_file(args.dot_file) == 0:
			TOPOLOGY_FILE = args.dot_file
		else:
			print(bcolors.FAIL + "\t#  " + bcolors.END + "ERROR: " + "Invalid File")
			exit(1)

##
#Funcao responsavel por printar o cabecalho da Ferramenta
##
def print_header():
	print("\n")
	print("**".ljust(5) + "**".rjust(44))
	print("*".ljust(5) + "LAB DATACOM-PUCRS -- TOPOLOGY CONVERTER" + "*".rjust(5))
	print("*".ljust(5) + "Desenvolvido por: Rafael Basso" + "*".rjust(14))
	print("**".ljust(5) + "**".rjust(44))

	print("*".ljust(5) + "*".rjust(44))
	print("*".ljust(5) + "Ferramenta desenvolvida para converter " + "*".rjust(5))
	print("*".ljust(5) + "uma topologia (arquivo.dot) em um arqui" + "*".rjust(5))
	print("*".ljust(5) + "vo Vagrant (Vagrantfile).              " + "*".rjust(5))
	print("*".ljust(5) + "*".rjust(44))
	print("**".ljust(5) + "**".rjust(44))

##
#MAIN
##
def main():
	print_header()
	parser()
	set_provider()
	inv = parse_dot_file()
	devices = add_to_list(inv)
	jinja2_template(devices)

if __name__ == "__main__":
	main()
exit(0)
