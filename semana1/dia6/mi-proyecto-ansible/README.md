Solucionando el Error "Ansible software could not be found" con Vagrant
Este README.md explica un problema común al usar Vagrant con el provisionador de Ansible y cómo resolverlo, basándose en la configuración de tu Vagrantfile.

El Problema: Incompatibilidad entre Provisionadores
El error principal que estás viendo (Vagrant gathered an unknown Ansible version y The Ansible software could not be found!) ocurre porque tu Vagrantfile está intentando hacer dos cosas contradictorias:

Instalar Ansible DENTRO de la máquina virtual: Tu bloque config.vm.provision "shell" descarga e instala Ansible en el sistema operativo de la VM. Esto es lo que permite que, cuando haces vagrant ssh y ejecutas ansible --version, veas la versión 2.10.8.

Usar el provisionador de Ansible del HOST: El bloque config.vm.provision "ansible" le dice a Vagrant que ejecute el playbook.yml usando la instalación de Ansible que espera encontrar en tu máquina anfitriona (tu PC, donde ejecutas vagrant up).

Dado que Ansible no está instalado en tu máquina anfitriona (o no está en el PATH donde Vagrant lo busca), Vagrant no puede encontrarlo y falla al intentar ejecutar el playbook.

La Solución: Elige tu Enfoque
Tienes dos opciones principales para resolver esto. La Opción 1 es la más directa dado cómo tienes configurado actualmente tu Vagrantfile.

Opción 1: Usar el Provisionador ansible_local (Recomendado para tu setup actual)
Esta opción es ideal si quieres que Ansible se instale y ejecute directamente dentro de la máquina virtual. Es muy útil si tu máquina anfitriona no puede o no debe tener Ansible instalado.

Modifica tu Vagrantfile:

Cambia el bloque de provisionamiento de Ansible de ansible a ansible_local. Mantén el provisionador shell que instala Ansible, ya que es necesario para que ansible_local funcione.

Ruby

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.box_version = "202502.21.0"

  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.network "forwarded_port", guest: 3000, host: 3000  
  config.vm.network "forwarded_port", guest: 8000, host: 8000  

  config.vm.provider "virtualbox" do |vb|
    vb.name = "ansible-devops-vm"
    vb.memory = "2048"
    vb.cpus = 2
  end

  # Provisionamiento con Shell (¡Esto instala Ansible DENTRO de la VM!)
  config.vm.provision "shell", inline: <<-SHELL
    echo "¡Hola desde el provisionamiento!" > /tmp/hola.txt
    sudo apt update
    sudo apt install software-properties-common -y
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt install ansible -y
  SHELL

  config.vm.synced_folder ".", "/vagrant"

  # Provisionamiento con Ansible (¡AHORA usando ansible_local!)
  # Esto le dice a Vagrant que use la instalación de Ansible que está DENTRO de la VM.
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "./mi-proyecto-ansible/playbooks/playbook.yml"
    ansible.verbose = "v"
    # Opcional: ansible_local puede instalar Ansible si no lo encuentra.
    # "default" usará apt/yum dentro de la VM.
    ansible.install_mode = "default" 
  end

  config.vm.post_up_message = <<-MSG
🔴 ¡ANSIBLE DevOps VM lista!
📱 90 Days of DevOps by Roxs 🚀
MSG
end
```

Ejecuta Vagrant:
Una vez que hayas guardado los cambios en tu Vagrantfile, ejecuta:

Bash

vagrant reload --provision
Si la VM no está creada, simplemente usa vagrant up.

Vagrant ahora primero instalará Ansible dentro de la VM, y luego usará esa instalación interna para ejecutar tu playbook.

Opción 2: Instalar Ansible en tu Máquina Anfitriona
Esta opción es la forma más tradicional y a menudo preferida si planeas usar Ansible para gestionar múltiples entornos o servidores más allá de solo tus VMs de Vagrant.

Elimina o comenta el provisionador shell de Ansible en tu Vagrantfile:
Ya no es necesario instalar Ansible dentro de la VM si lo vas a ejecutar desde tu host.

Ruby

# Comenta o elimina este bloque:
# config.vm.provision "shell", inline: <<-SHELL
#   echo "¡Hola desde el provisionamiento!" > /tmp/hola.txt
#   sudo apt update
#   sudo apt install software-properties-common -y
#   sudo add-apt-repository --yes --update ppa:ansible/ansible
#   sudo apt install ansible -y
# SHELL
Instala Ansible en tu máquina anfitriona (donde ejecutas vagrant up):
Abre una terminal en tu PC principal (no dentro de la VM de Vagrant) y ejecuta los comandos de instalación de Ansible. Para sistemas basados en Debian/Ubuntu (como el que parece ser tu host jlamadrid@ThinkpadE14):

Bash

sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible -y
Después de la instalación, verifica que Ansible esté disponible ejecutando ansible --version en tu terminal de host.

Mantén tu bloque config.vm.provision "ansible" original:
No es necesario cambiar nada en el bloque ansible de tu Vagrantfile para esta opción.

Ruby

# Provisionamiento con Ansible (Usa el Ansible de tu HOST)
config.vm.provision "ansible" do |ansible|
  ansible.playbook = "./mi-proyecto-ansible/playbooks/playbook.yml"
  ansible.verbose = "v"
end
Ejecuta Vagrant:

Bash

vagrant reload --provision
Ahora Vagrant debería encontrar Ansible en tu host y usarlo para provisionar la VM.

Elige la opción que mejor se adapte a tu flujo de trabajo. ¡La Opción 1 es la más sencilla dado tu Vagrantfile actual!

Resolviendo el Error "passlib must be installed" en Ansible
Has encontrado un error común cuando Ansible necesita trabajar con contraseñas hash: la librería passlib no se encuentra. Este README.md explica la causa y cómo solucionarlo.

El Problema: passlib Necesario en el Host
El error fatal: [192.168.56.10]: FAILED! => {"msg": "Unable to encrypt nor hash, passlib must be installed. No module named 'passlib'."} ocurre porque, aunque hayas instalado passlib dentro de tu VM de Vagrant, la función que genera el hash de la contraseña (como {{ 'tu_contrasena_segura' | password_hash('sha512') }}) se ejecuta en tu máquina local (el "controlador" o "host" de Ansible) antes de que el playbook se envíe a la VM.

Por lo tanto, Ansible necesita tener acceso a la librería passlib en el entorno Python de tu máquina anfitriona, no en la máquina virtual.

La Solución: Instalar passlib en tu Máquina Anfitriona
Aquí tienes las formas recomendadas para instalar passlib en tu máquina anfitriona (donde ejecutas ansible-playbook):

Opción 1: Instalar con apt (Recomendado para Ubuntu/Debian Hosts)
Esta es la forma más limpia y compatible si tu máquina anfitriona es Ubuntu o Debian, ya que integra passlib con el gestor de paquetes de tu sistema.

Abre una terminal en tu máquina anfitriona (no dentro de la VM de Vagrant).

Ejecuta los siguientes comandos:

Bash

sudo apt update
sudo apt install python3-passlib
Opción 2: Usar un Entorno Virtual de Python (Buena Práctica General)
Si prefieres mantener las dependencias de Python separadas de tu sistema principal o si trabajas en varios proyectos con diferentes requisitos de Python, un entorno virtual es la mejor práctica.

Navega al directorio raíz de tu proyecto Ansible en tu máquina anfitriona:

Bash

cd ~/code/90daysdevos/semana1/dia6/mi-proyecto-ansible
Crea un entorno virtual (si aún no tienes uno para este proyecto):

Bash

python3 -m venv .venv
Activa el entorno virtual:

Bash

source .venv/bin/activate
Tu línea de comandos cambiará para indicar que el entorno virtual está activo (ej: (.venv) jlamadrid@ThinkpadE14:...).

Instala passlib dentro de este entorno virtual:

Bash

pip install passlib
Importante: Cada vez que quieras ejecutar tu playbook de Ansible para este proyecto, deberás activar este entorno virtual primero. Cuando hayas terminado, puedes salir del entorno virtual con deactivate.

Después de la Instalación
Una vez que hayas instalado passlib correctamente en tu máquina anfitriona usando cualquiera de las opciones anteriores, vuelve a ejecutar tu playbook de Ansible:

Bash

ansible-playbook playbooks/playbook.yml --check
El error Unable to encrypt nor hash, passlib must be installed debería desaparecer, permitiendo que tu tarea de Crear usuario admin se ejecute sin problemas.
