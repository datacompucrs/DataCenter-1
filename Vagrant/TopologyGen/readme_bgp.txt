sudo su
apt-get install quagga quagga-doc
cp /usr/share/doc/quagga-core/examples/vtysh.conf.sample /etc/quagga/vtysh.conf
cp /usr/share/doc/quagga-core/examples/zebra.conf.sample /etc/quagga/zebra.conf
cp /usr/share/doc/quagga-core/examples/bgpd.conf.sample /etc/quagga/bgpd.conf
sudo chown quagga:quagga /etc/quagga/*.conf
sudo chown quagga:quaggavty /etc/quagga/vtysh.conf
sudo chmod 640 /etc/quagga/*.conf
sudo service zebra start
sudo service bgpd start

sudo sysctl -w net.ipv4.ip_forward=1

sudo telnet localhost zebra //senha zebra
>>en
>>configure terminal
//para cada interface
	>>interface [nome interface]
	>>ip address [addr da interface]
	>>no shutdown
	>>quit
>>wr // salva config
	
sudo telnet localhost bgpd
>>en
>>configure terminal	
>>router bgp [AS NUMBER]
//fazer para todas redes conectadas ou servers
>>network [addr da rede conectada no router/mask]

//fazer para cada vizinho com bgp
>>neighbor [addr do router com bgp] remote-as [AS NUMBER]
>>quit
>>wr //salva config

sudo vagrant scp r1:/etc/quagga/zebra.conf ./zebra_r1.conf // copia arquivo do host para local ex zebra
