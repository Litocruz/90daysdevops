# 🚀 Despliegue de la Aplicación de Votación con Vagrant y Ansible
> Este **README.md** te guiará a través del proceso de clonar el repositorio, configurar el entorno de Vagrant y automatizar el despliegue de la aplicación de votación (Vote, Worker, Result) con Ansible.

# 🚀 Sistema de Votación: Despliegue Automatizado con Vagrant y Ansible

Este proyecto implementa un sistema de votación simple con una arquitectura de microservicios, automatizando su despliegue y configuración en una máquina virtual utilizando Vagrant y Ansible.

---

## 🎯 Arquitectura del Sistema

El sistema se compone de tres servicios principales que interactúan a través de Redis y PostgreSQL:

* **`Vote` (Flask/Python)**: Interfaz de usuario para registrar votos.
* **`Worker` (Node.js)**: Procesador de votos en segundo plano.
* **`Result` (Node.js)**: Interfaz de usuario para visualizar resultados.

### Flujo de Datos

1.  El usuario envía un voto a **`Vote` (Flask)** (accesible en el puerto `5000` de la VM, mapeado al `80` del host).
2.  **`Vote`** guarda el voto en una cola en **Redis** (puerto `6379` en la VM).
3.  **`Worker`** (puerto `3000` en la VM para métricas) consume votos de la cola de **Redis**.
4.  **`Worker`** procesa y persiste los votos en la tabla `votes` de **PostgreSQL** (puerto `5432` en la VM).
5.  **`Result`** (puerto `3001` en la VM) consulta **PostgreSQL** para obtener y exponer los resultados.

### Esquema de la Tabla `votes` en PostgreSQL

```sql
+------------------------+
|       votes            |
+------------------------+
| id (PK)       VARCHAR  |  <- Identificador único del votante
| vote          VARCHAR  |  <- Voto realizado por el usuario (ej. 'a' o 'b')
| created_at    TIMESTAMP|  <- Marca de tiempo del voto
+------------------------+
```

## 📋 Pre-requisitos
Asegúrate de tener lo siguiente instalado en tu máquina anfitriona (tu notebook):

✅ *Git*: Para clonar el repositorio.
✅*Vagrant*: Para provisionar y gestionar la máquina virtual.
✅*VirtualBox*: El proveedor de virtualización para Vagrant.
✅*Ansible*: Para automatizar el despliegue y la configuración.
✅*Python 3 y pip*: Para las colecciones de Ansible y gestión de dependencias.

### Colecciones de Ansible:

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
mkdir -p ansible/inventario ansible/group_vars ansible/roles/{common/{tasks,handlers,templates},postgresql/tasks,redis/tasks,flask_vote/{tasks,handlers,templates},nodejs_worker/tasks,nodejs_result/tasks}
```
Paso 2: Configurar Archivos Clave
Ahora, crea y edita los archivos esenciales de configuración de Vagrant y Ansible.

**Vagrantfile:** Define tu máquina virtual. Crea este archivo en la raíz del repositorio (roxs-devops-project90/Vagrantfile).

```Ruby

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04" # ¡Importante: Usar 22.04 para estabilidad!
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.network "forwarded_port", guest: 3001, host: 3001, id: "result_app" # App Result
  config.vm.network "forwarded_port", guest: 3000, host: 3000, id: "worker_metrics" # App Worker metrics
  config.vm.network "forwarded_port", guest: 5000, host: 80, id: "vote_app" # App Vote (Guest 5000 -> Host 80)

  config.vm.provider "virtualbox" do |vb|
    vb.name = "devops-voting-app-vm"
    vb.memory = "4096" # Recomendado: 4GB para todos los servicios
    vb.cpus = 2        # Recomendado: 2 núcleos de CPU
  end

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "ansible/playbook.yml"
    ansible.verbose = "v"
    ansible.inventory_path = "ansible/inventario/hosts"
    ansible.limit = "192.168.56.10"
    ansible.config_file = "ansible/ansible.cfg"
  end

  config.vm.post_up_message = <<-MSG
🔴 ¡VM de la Aplicación de Votación lista!
Para acceder a la app Vote: https://www.google.com/url?sa=E&source=gmail&q=http://192.168.56.10:5000
Para acceder a la app Result: https://www.google.com/url?sa=E&source=gmail&q=http://192.168.56.10:8000
MSG
end
```

**ansible/ansible.cfg:** Configuración global de Ansible. Crea este archivo en la raíz del repositorio (roxs-devops-project90/ansible/ansible.cfg).

```Ini, TOML

[defaults]
inventory = inventario/hosts
roles_path = roles
collections_path = /usr/lib/python3/dist-packages/ # Ruta ABSOLUTA donde ansible-galaxy instala colecciones

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
_tee_use_sudo_nopasswd = False # Solución para 'chmod: invalid mode'
```
ansible/inventario/hosts (en ansible/inventario/):
```YAML
[webservers]
192.168.56.10

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_user=vagrant
# La clave privada por defecto de Vagrant. Vagrant la gestiona, pero es buena práctica tenerla para depuración.
ansible_ssh_private_key_file=~/.vagrant.d/insecure_private_key
```
ansible/group_vars/webservers.yml: Variables para el grupo webservers.
```YAML
---
# Variables de paquetes del sistema
system_packages:
  - git
  - curl
  - build-essential
  - python3-venv
  - python3-virtualenv # Para entornos virtuales Python (pip module)
  - postgresql-client
  - net-tools
  - python3-psycopg2   # Para que Ansible se conecte a PostgreSQL
  - acl                # Para ayudar con manejo de permisos avanzados

# Configuración de PostgreSQL
pg_version: "14"
pg_user: "postgres" # Usuario por defecto de PostgreSQL en Ubuntu
pg_password: "postgres" # Contraseña por defecto (cambiar en producción)
pg_db: "votes"      # Nombre de la base de datos
pg_host: "127.0.0.1"
pg_port: 5432

# Configuración de Redis
redis_port: 6379
redis_host: "127.0.0.1"

# Configuración de Node.js
node_version: "18.x"
pm2_version: "latest"

# Rutas de la aplicación dentro de la VM
app_base_path: /home/vagrant/app # Directorio base donde se clonará el repo
app_base_name: roxs-voting-app # Nombre de la carpeta del repo clonado

# Puertos de los servicios (acceso desde el HOST)
vote_app_port: 5000   # Puerto de Gunicorn/Flask dentro de la VM
worker_app_port: 3000 # Puerto del Worker (para métricas, si aplica)
result_app_port: 3001 # Puerto de la app Result
```
ansible/playbook.yml (en ansible/):
```YAML

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
```

## Paso 3: Definir los Roles de Ansible
Crea los archivos main.yml dentro de la carpeta tasks/ de cada rol, y si aplica, los templates/ y handlers/.

ansible/roles/common/tasks/main.yml:

```YAML
---
- name: Actualizar caché de apt
  ansible.builtin.apt:
    update_cache: yes

- name: Instalar paquetes básicos del sistema
  ansible.builtin.apt:
    name: "{{ system_packages }}"
    state: present

- name: Asegurar que el paquete 'acl' esté instalado
  ansible.builtin.apt:
    name: acl
    state: present

- name: Instalar Node.js y npm (usando NodeSource PPA)
  ansible.builtin.shell: |
    curl -fsSL [https://deb.nodesource.com/setup](https://deb.nodesource.com/setup)_{{ node_version }} | sudo -E bash -
    sudo apt-get install -y nodejs
  args:
    executable: /bin/bash
  when: ansible_distribution == 'Ubuntu'

- name: Instalar PM2 globalmente
  community.general.npm:
    name: pm2
    global: yes
    state: present

- name: Clonar el repositorio de la app
  ansible.builtin.git:
    repo: "{{ repo }}" # Variable 'repo' de group_vars
    dest: "{{ app_base_path }}/{{ app_base_name }}" # Clona en /home/vagrant/app/roxs-voting-app
    version: main # Asegúrate de que esta sea la rama correcta (o 'master')
    force: yes
  become_user: "{{ ansible_user }}" # Usuario 'vagrant'
```
ansible/roles/postgresql/tasks/main.yml:

```YAML
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
  community.postgresql.postgresql_user:
    db: postgres
    name: "{{ pg_user }}"
    password: "{{ pg_password }}"
    state: present
  become_user: postgres # Ejecuta esta tarea como el usuario 'postgres'

- name: Crear base de datos para la app
  community.postgresql.postgresql_db:
    name: "{{ pg_db }}"
    owner: "{{ pg_user }}"
    state: present
  become_user: postgres # Ejecuta esta tarea como el usuario 'postgres'
```
ansible/roles/redis/tasks/main.yml:

```YAML

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
```
ansible/roles/flask_vote/tasks/main.yml:

```YAML---
- name: Instalar dependencias de Python para Flask Vote
  ansible.builtin.pip:
    requirements: "{{ app_base_path }}/{{ app_base_name }}/vote/requirements.txt"
    virtualenv: "{{ app_base_path }}/{{ app_base_name }}/vote/.venv"
    virtualenv_python: python3
  become_user: "{{ ansible_user }}"

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
```
Crea la plantilla para el servicio Flask Vote:
ansible/roles/flask_vote/templates/vote_app.service.j2:
>
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
<
ansible/roles/flask_vote/handlers/main.yml:

```YAML

---
- name: Reload systemd
  ansible.builtin.systemd:
    daemon_reload: yes

- name: Restart Flask Vote
  ansible.builtin.systemd:
    name: vote_app
    state: restarted
```
ansible/roles/nodejs_worker/tasks/main.yml:

```YAML
---
- name: Instalar dependencias de Node.js para Worker
  ansible.builtin.community.general.npm:
    path: "{{ app_base_path }}/{{ app_base_name }}/worker"
    state: present
    ci: no # Asegura que use 'npm install' en lugar de 'npm ci' si package-lock.json no existe

- name: Crear script de inicio para Node.js Worker con PM2
  ansible.builtin.shell: |
    pm2 start main.js --name worker-app
    pm2 save
  args:
    chdir: "{{ app_base_path }}/{{ app_base_name }}/worker"
    executable: /bin/bash
  environment:
    PGHOST: "{{ pg_host }}"
    PGUSER: "{{ pg_user }}"
    PGPASSWORD: "{{ pg_password }}"
    PGDATABASE: "{{ pg_db }}"
    PGPORT: "{{ pg_port }}" # Añadido PGPORT
    REDIS_HOST: "{{ redis_host }}"
    REDIS_PORT: "{{ redis_port }}"
  become_user: "{{ ansible_user }}" # Usar el usuario 'vagrant'
```
ansible/roles/nodejs_result/tasks/main.yml:

```YAML
---
- name: Instalar dependencias de Node.js para Result
  ansible.builtin.community.general.npm:
    path: "{{ app_base_path }}/{{ app_base_name }}/result"
    state: present
    ci: no # Asegura que use 'npm install' en lugar de 'npm ci' si package-lock.json no existe

- name: Crear script de inicio para Node.js Result con PM2
  ansible.builtin.shell: |
    pm2 start main.js --name result-app -- -p {{ result_app_port }} # El puerto se pasa como ENV, no CLI
    pm2 save
  args:
    chdir: "{{ app_base_path }}/{{ app_base_name }}/result"
    executable: /bin/bash
  environment:
    PGHOST: "{{ pg_host }}"
    PGUSER: "{{ pg_user }}"
    PGPASSWORD: "{{ pg_password }}"
    PGDATABASE: "{{ pg_db }}"
    PGPORT: "{{ pg_port }}" # Añadido PGPORT
    APP_PORT: "{{ result_app_port }}" # Puerto de la aplicación Result
  become_user: "{{ ansible_user }}" # Usar el usuario 'vagrant'
```
## Paso 4: Levantar y Provisionar la VM
Desde la raíz de tu repositorio (roxs-devops-project90), ejecuta el siguiente comando:

```Bash

vagrant up
```

Este comando levantará la máquina virtual y ejecutará automáticamente el playbook de Ansible para provisionarla con todos los servicios.

## Paso 5: Validar el Flujo de Datos
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
```
```Bash

vagrant ssh
```

Dentro de la VM, puedes usar:

sudo systemctl status postgresql

sudo systemctl status redis-server

sudo systemctl status vote_app

## TODO

I've identified several key points and inconsistencies that need to be addressed to ensure a smooth deployment. These include:

VM Resource Allocation: Your Vagrantfile's memory and CPU are a bit low for all services.

Application Pathing: There's an inconsistency in how app_base_path and app_base_name are used for cloning the repository and then referencing the sub-applications.

Node.js Port Handling: Passing ports directly to pm2 start via -p can be problematic if the Node.js apps expect them as environment variables.

PostgreSQL Port for Worker: The nodejs_worker role's environment variables were missing PGPORT.

Forwarded Ports in Vagrantfile: Clarified the mapping for better understanding.

pm2 list (para ver las apps worker-app y result-app)

pm2 logs (para ver los logs consolidados)

¡Felicidades! Has completado un despliegue DevOps automatizado para una aplicación de microservicios.
