Baixar Virtualbox no site: https://www.virtualbox.org/wiki/Linux_Downloads
- Versão do LabRedes - Debian 9

Instalar .deb com dependências
$ sudo apt -y install ./virtualbox-6.0_6.0.10-132072_Debian_stretch_amd64.deb

Baixar Vagrant no site: https://www.vagrantup.com/downloads.html
- Versão Debian 64 bits

Instalar .deb com dependências
$ sudo apt -y install ./vagrant_2.2.5_x86_64.deb

Entrar no diretório onde está o Vagrantfile

Executar a criação da VM
$ vagrant up

Verificar que a VM está rodando
$ vagrant status

Entrar na VM
$ vagrant ssh

Executar o Core
$ core-gui
