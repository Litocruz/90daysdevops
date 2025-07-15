# 🚀 Despliegue de la Aplicación de Votación con Vagrant y Ansible
> Este **README.md** te guiará a través del proceso de clonar el repositorio, configurar el entorno de Vagrant y automatizar el despliegue de la aplicación de votación (Vote, Worker, Result) con Ansible.

## 📋 Pre-requisitos
Asegúrate de tener lo siguiente instalado en tu máquina anfitriona (tu notebook):

✅ *Git*: Para clonar el repositorio.
✅*Vagrant*: Para provisionar y gestionar la máquina virtual.
✅*VirtualBox*: El proveedor de virtualización para Vagrant.
✅*Ansible*: Para automatizar el despliegue y la configuración.
✅*Python 3 y pip*: Para las colecciones de Ansible y gestión de dependencias.

Colecciones de Ansible:

```Bash
ansible-galaxy collection install community.general
ansible-galaxy collection install community.postgresql
```

## 🏗️ Estructura del Proyecto
La estructura de tu proyecto será la siguiente, lo que facilita la co-localización de la aplicación y la infraestructura como código:

```Bash
roxs-devops-project90/           <-- Raíz del repositorio
├── .git/
├── Vagrantfile                  <-- Define tu VM de desarrollo
├── ansible/                     <-- DIRECTORIO PRINCIPAL DE ANSIBLE
│   ├── ansible.cfg              <-- Configuración global de Ansible
│   ├── playbook.yml             <-- Playbook principal para desplegar la app
│   ├── inventario/
│   │   └── hosts                <-- Tu inventario de hosts
│   ├── group_vars/
│   │   └── webservers.yml       <-- Variables para el grupo 'webservers'
│   └── roles/                   <-- Directorio de roles
│       ├── common/              <-- Rol: Configuraciones básicas del SO, Node.js, PM2
│       │   ├── tasks/
│       │   └── ...
│       ├── postgresql/          <-- Rol: Instalación y configuración de PostgreSQL
│       │   ├── tasks/
│       │   └── ...
│       ├── redis/               <-- Rol: Instalación y configuración de Redis
│       │   ├── tasks/
│       │   └── ...
│       ├── flask_vote/          <-- Rol: Despliegue de la app Flask 'Vote'
│       │   ├── tasks/
│       │   ├── templates/
│       │   └── handlers/
│       ├── nodejs_worker/       <-- Rol: Despliegue de la app Node.js 'Worker'
│       │   ├── tasks/
│       │   └── ...
│       └── nodejs_result/       <-- Rol: Despliegue de la app Node.js 'Result'
│           ├── tasks/
│           └── ...
├── vote/                        <-- Código de la aplicación Flask
├── worker/                      <-- Código de la aplicación Node.js Worker
├── result/                      <-- Código de la aplicación Node.js Result
└── README.md
```
## ⚙️ Paso a Paso para la Configuración del Entorno
Sigue estos pasos para levantar y configurar tu aplicación:

Paso 1: Clonar el Repositorio e Inicializar la Estructura
Clona el repositorio en tu máquina anfitriona:

```Bash

git clone https://github.com/roxsross/roxs-devops-project90.git
Navega al directorio del proyecto:
```
```Bash

cd roxs-devops-project90
Crea la estructura de directorios para Ansible (si no existe ya):
```
```Bash

mkdir -p ansible/inventario ansible/group_vars ansible/roles/{common,postgresql,redis,flask_vote/{tasks,handlers,templates},nodejs_worker,nodejs_result}
Paso 2: Configurar Archivos Clave
Ahora, crea y edita los archivos esenciales de configuración de Vagrant y Ansible.

Vagrantfile: Define tu máquina virtual. Crea este archivo en la raíz del repositorio (roxs-devops-project90/Vagrantfile).
```
```Ruby

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "devops-voting-app-vm"
    vb.memory = "4096"
    vb.cpus = 2
  end

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "ansible/playbook.yml"
    ansible.verbose = "v"
    ansible.inventory_path = "ansible/inventario/hosts" # Usa tu inventario custom
    ansible.limit = "192.168.56.10" # Limita al host específico de tu inventario
  end

  config.vm.post_up_message = <<-MSG
🔴 ¡VM de la Aplicación de Votación lista!
Para acceder a la app Vote: https://www.google.com/url?sa=E&source=gmail&q=http://192.168.56.10:5000
Para acceder a la app Result: https://www.google.com/url?sa=E&source=gmail&q=http://192.168.56.10:8000
MSG
end
```

ansible.cfg: Configuración global de Ansible. Crea este archivo en la raíz del repositorio (roxs-devops-project90/ansible.cfg).

Ini, TOML

[defaults]
inventory = ansible/inventario/hosts
roles_path = ansible/roles
# Si group_vars estuviera dentro de 'inventario', necesitarías:
# vars_plugins_path = ansible/inventario
# Pero con la estructura recomendada, 'group_vars' en la raíz del proyecto es suficiente.
ansible/inventario/hosts: Tu inventario de Ansible.

Ini, TOML

[webservers]
192.168.56.10

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_user=vagrant
# La clave privada por defecto de Vagrant. Vagrant la gestiona, pero es buena práctica tenerla para depuración.
ansible_ssh_private_key_file=~/.vagrant.d/insecure_private_key
ansible/group_vars/webservers.yml: Variables para el grupo webservers.

YAML

---
# Variables generales del sistema
system_packages:
  - git
  - curl
  - build-essential
  - python3-venv
  - postgresql-client
  - net-tools

# Configuración de PostgreSQL
pg_version: "14"
pg_user: "dbuser"
pg_password: "dbpassword"
pg_db: "votingapp"

# Configuración de Redis
redis_port: 6379

# Configuración de Node.js (para Worker y Result)
node_version: "18.x"
pm2_version: "latest"

# Rutas de la aplicación
app_base_path: /opt/app

# Puertos de los servicios (accedidos desde el host)
vote_app_port: 5000
worker_app_port: 8001 # Gunicorn/Flask en Vote
result_app_port: 8000 # App Node.js en Result
ansible/playbook.yml: El playbook principal que orquesta los roles.

YAML

---
- name: Desplegar entorno de aplicación de votación
  hosts: webservers
  become: yes # Ejecutar tareas con privilegios de superusuario

  roles:
    - common
    - postgresql
    - redis
    - flask_vote
    - nodejs_worker
    - nodejs_result
Paso 3: Definir los Roles de Ansible
Crea los archivos main.yml dentro de la carpeta tasks/ de cada rol, y si aplica, los templates/ y handlers/.

ansible/roles/common/tasks/main.yml:

YAML

---
- name: Actualizar caché de apt
  ansible.builtin.apt:
    update_cache: yes

- name: Instalar paquetes básicos del sistema
  ansible.builtin.apt:
    name: "{{ system_packages }}"
    state: present

- name: Instalar Node.js y npm (usando NodeSource PPA)
  ansible.builtin.shell: |
    curl -fsSL https://deb.nodesource.com/setup_{{ node_version }} | sudo -E bash -
    sudo apt-get install -y nodejs
  args:
    executable: /bin/bash
  when: ansible_distribution == 'Ubuntu'

- name: Instalar PM2 globalmente
  community.general.npm:
    name: pm2
    global: yes
    state: present
ansible/roles/postgresql/tasks/main.yml:

YAML

---
- name: Instalar PostgreSQL
  ansible.builtin.apt:
    name: "postgresql-{{ pg_version }}"
    state: present
    update_cache: yes

- name: Asegurar que el servicio PostgreSQL esté corriendo
  ansible.builtin.systemd:
    name: postgresql
    state: started
    enabled: yes

- name: Crear usuario de base de datos para la app
  ansible.builtin.community.postgresql.postgresql_user:
    db: postgres
    name: "{{ pg_user }}"
    password: "{{ pg_password }}"
    state: present
  become_user: postgres

- name: Crear base de datos para la app
  ansible.builtin.community.postgresql.postgresql_db:
    name: "{{ pg_db }}"
    owner: "{{ pg_user }}"
    state: present
  become_user: postgres
ansible/roles/redis/tasks/main.yml:

YAML

---
- name: Instalar Redis
  ansible.builtin.apt:
    name: redis-server
    state: present
    update_cache: yes

- name: Asegurar que el servicio Redis esté corriendo y habilitado
  ansible.builtin.systemd:
    name: redis-server
    state: started
    enabled: yes
ansible/roles/flask_vote/tasks/main.yml:

YAML

---
- name: Clonar el repositorio de la aplicación
  ansible.builtin.git:
    repo: https://github.com/roxsross/roxs-devops-project90.git
    dest: "{{ app_base_path }}" # Clona en la ruta base de la app
    version: master
    force: yes
  become_user: vagrant

- name: Instalar dependencias de Python para Flask Vote
  ansible.builtin.pip:
    requirements: "{{ app_base_path }}/vote/requirements.txt"
    virtualenv: "{{ app_base_path }}/vote/.venv"
    virtualenv_python: python3
  become_user: vagrant

- name: Crear script de inicio para Flask Vote (Gunicorn)
  ansible.builtin.template:
    src: vote_app.service.j2
    dest: /etc/systemd/system/vote_app.service
    mode: '0644'
  notify:
    - Reload systemd
    - Restart Flask Vote

- name: Iniciar y habilitar el servicio Flask Vote
  ansible.builtin.systemd:
    name: vote_app
    state: started
    enabled: yes
    daemon_reload: yes
Crea la plantilla para el servicio Flask Vote:
ansible/roles/flask_vote/templates/vote_app.service.j2:

Fragmento de código

[Unit]
Description=Gunicorn instance to serve Flask Vote app
After=network.target postgresql.service redis-server.service # Asegurar que DBs estén antes

[Service]
User=vagrant
Group=vagrant
WorkingDirectory={{ app_base_path }}/vote
Environment="REDIS_HOST=127.0.0.1"
ExecStart={{ app_base_path }}/vote/.venv/bin/gunicorn --workers 4 --bind 0.0.0.0:{{ worker_app_port }} wsgi:app
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=vote-app
PrivateTmp=true

[Install]
WantedBy=multi-user.target
Crea el handler para Flask Vote:
ansible/roles/flask_vote/handlers/main.yml:

YAML

---
- name: Reload systemd
  ansible.builtin.systemd:
    daemon_reload: yes

- name: Restart Flask Vote
  ansible.builtin.systemd:
    name: vote_app
    state: restarted
ansible/roles/nodejs_worker/tasks/main.yml:

YAML

---
- name: Instalar dependencias de Node.js para Worker
  ansible.builtin.community.general.npm:
    path: "{{ app_base_path }}/worker"
    state: present
    # Añadir esto para asegurar la instalación sin interacción
    ci: yes

- name: Crear script de inicio para Node.js Worker con PM2
  ansible.builtin.shell: |
    pm2 start index.js --name worker-app
    pm2 save
  args:
    chdir: "{{ app_base_path }}/worker"
    executable: /bin/bash
  environment:
    PGHOST: 127.0.0.1
    PGUSER: "{{ pg_user }}"
    PGPASSWORD: "{{ pg_password }}"
    PGDATABASE: "{{ pg_db }}"
    REDIS_HOST: 127.0.0.1
    REDIS_PORT: "{{ redis_port }}"
  become_user: vagrant

- name: Asegurar que PM2 esté configurado para iniciar al arranque
  ansible.builtin.shell: |
    pm2 startup systemd -u vagrant --hp /home/vagrant
    pm2 save
  args:
    executable: /bin/bash
  become: yes
ansible/roles/nodejs_result/tasks/main.yml:

YAML

---
- name: Instalar dependencias de Node.js para Result
  ansible.builtin.community.general.npm:
    path: "{{ app_base_path }}/result"
    state: present
    ci: yes

- name: Crear script de inicio para Node.js Result con PM2
  ansible.builtin.shell: |
    pm2 start index.js --name result-app -- -p {{ result_app_port }}
    pm2 save
  args:
    chdir: "{{ app_base_path }}/result"
    executable: /bin/bash
  environment:
    PGHOST: 127.0.0.1
    PGUSER: "{{ pg_user }}"
    PGPASSWORD: "{{ pg_password }}"
    PGDATABASE: "{{ pg_db }}"
  become_user: vagrant
Paso 4: Levantar y Provisionar la VM
Desde la raíz de tu repositorio (roxs-devops-project90), ejecuta el siguiente comando:

Bash

vagrant up
Este comando levantará la máquina virtual y ejecutará automáticamente el playbook de Ansible para provisionarla con todos los servicios.

Paso 5: Validar el Flujo de Datos
Una vez que vagrant up haya terminado exitosamente:

Acceder a la aplicación Vote:
Abre tu navegador web y navega a:
http://192.168.56.10:5000
Deberías ver la interfaz para votar. Ingresa algunas votaciones.

Acceder a la aplicación Result:
Abre otra pestaña en tu navegador y navega a:
http://192.168.56.10:8000
Deberías ver los resultados de las votaciones reflejados. Esto confirma que los datos fluyen desde la aplicación Vote, pasan por Redis al Worker, son guardados en PostgreSQL, y luego leídos por la aplicación Result.

Verificar servicios (Opcional - Vía SSH a la VM):
Puedes conectarte a la VM para inspeccionar el estado de los servicios:

Bash

vagrant ssh
Dentro de la VM, puedes usar:

sudo systemctl status postgresql

sudo systemctl status redis-server

sudo systemctl status vote_app

pm2 list (para ver las apps worker-app y result-app)

pm2 logs (para ver los logs consolidados)

¡Felicidades! Has completado un despliegue DevOps automatizado para una aplicación de microservicios.
