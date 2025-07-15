# 🚀 Despliegue de la Aplicación de Votación con Vagrant y Ansible

Este `README.md` es tu guía completa para desplegar la aplicación de votación (`Vote`, `Worker`, `Result`) utilizando **Vagrant** para el entorno virtual y **Ansible** para la automatización. No solo te mostrará los pasos de despliegue, sino que también documenta los **problemas comunes que encontramos y sus soluciones**, lo que te ahorrará muchísimas horas de depuración.

---

## 🎯 Arquitectura de la Aplicación

La aplicación se compone de varios servicios que se conectan entre sí:

* **Vote (Flask):** Es la interfaz de usuario para que la gente vote. Se comunica con Redis.
* **Redis:** Una base de datos ultrarrápida en memoria que funciona como una cola para almacenar los votos temporalmente.
* **Worker (Node.js):** Toma los votos de Redis, los procesa y los guarda en PostgreSQL.
* **PostgreSQL:** La base de datos persistente que almacena los resultados finales de las votaciones.
* **Result (Node.js):** Otra interfaz de usuario, esta vez para ver los resultados que están en PostgreSQL.

![Arquitectura de la aplicación de votación](docs/app_architecture.png)
*(Aquí iría una imagen que muestre el flujo: Vote -> Redis -> Worker -> PostgreSQL y Result -> PostgreSQL)*

---

## 📋 Pre-requisitos

Antes de empezar, asegúrate de tener todo esto instalado en tu **máquina anfitriona** (tu notebook):

* **Git**: Para descargar el código del proyecto.
* **Vagrant**: Para crear y gestionar tu máquina virtual de desarrollo.
* **VirtualBox**: El programa que Vagrant usa para crear la máquina virtual.
* **Ansible**: La herramienta de automatización.
* **Python 3** y **pip**: Necesarios para que Ansible funcione correctamente y para gestionar librerías.
* **Colecciones de Ansible**: ¡Súper importantes! Instálalas **en tu máquina anfitriona** (donde ejecutas los comandos):
    ```bash
    ansible-galaxy collection install community.general
    ansible-galaxy collection install community.postgresql
    ```

---

## 🏗️ Estructura del Proyecto

Mantener una buena estructura de directorios es clave. Así es como se organiza el proyecto para que todo funcione sin problemas:

oxs-devops-project90/           <-- La carpeta principal que clonas
├── .git/
├── Vagrantfile                  <-- Define tu máquina virtual (VM)
├── ansible/                     <-- Aquí va toda la configuración de Ansible
│   ├── ansible.cfg              <-- Archivo de configuración global de Ansible para este proyecto
│   ├── playbook.yml             <-- El "guion" principal de Ansible para desplegar la app
│   ├── inventario/
│   │   ├── hosts                <-- Tu lista de servidores (VMs)
│   │   └── ssh_config_for_ansible # Archivo SSH generado por Vagrant (no lo tocas)
│   ├── group_vars/
│   │   └── webservers.yml       <-- Variables específicas para tu grupo de servidores web
│   └── roles/                   <-- Aquí se organizan las tareas por funciones
│       ├── common/              <-- Rol: Configura el sistema base, Node.js, PM2, etc.
│       │   ├── tasks/main.yml
│       │   └── ...
│       ├── postgresql/          <-- Rol: Instala y configura PostgreSQL
│       │   ├── tasks/main.yml
│       │   └── ...
│       ├── redis/               <-- Rol: Instala y configura Redis
│       │   └── tasks/main.yml
│       ├── flask_vote/          <-- Rol: Despliega la app Flask 'Vote'
│       │   ├── tasks/main.yml
│       │   ├── templates/vote_app.service.j2 # Plantilla para el servicio systemd
│       │   └── handlers/main.yml
│       ├── nodejs_worker/       <-- Rol: Despliega la app Node.js 'Worker'
│       │   └── tasks/main.yml
│       └── nodejs_result/       <-- Rol: Despliega la app Node.js 'Result'
│           └── tasks/main.yml
├── vote/                        <-- Código de la aplicación Flask
├── worker/                      <-- Código de la aplicación Node.js Worker
├── result/                      <-- Código de la aplicación Node.js Result
└── README.md

## ⚙️ Paso a Paso para el Despliegue Automatizado

¡Vamos a configurar todo!

### Paso 1: Clonar el Repositorio y Preparar Carpetas

1.  **Clona el repositorio** en tu máquina anfitriona:
    ```bash
    git clone [https://github.com/roxsross/roxs-devops-project90.git](https://github.com/roxsross/roxs-devops-project90.git)
    ```

2.  **Entra al directorio** del proyecto:
    ```bash
    cd roxs-devops-project90
    ```

3.  **Crea las carpetas de Ansible** (si no existen):
    ```bash
    mkdir -p ansible/inventario ansible/group_vars ansible/roles/{common/{tasks,handlers,templates},postgresql/tasks,redis/tasks,flask_vote/{tasks,handlers,templates},nodejs_worker/tasks,nodejs_result/tasks}
    ```

### Paso 2: Configurar Archivos Clave

Aquí es donde le decimos a Vagrant y Ansible cómo trabajar juntos.

1.  **`Vagrantfile`**: Crea este archivo en la **raíz del repositorio**.
    ```ruby
    Vagrant.configure("2") do |config|
      config.vm.box = "bento/ubuntu-22.04" # Usa la versión 22.04 para mayor estabilidad
      config.vm.network "private_network", ip: "192.168.56.10" # IP de tu VM

      config.vm.provider "virtualbox" do |vb|
        vb.name = "devops-voting-app-vm"
        vb.memory = "4096" # 4GB de RAM para todos los servicios
        vb.cpus = 2        # 2 núcleos de CPU
      end

      config.vm.provision "ansible" do |ansible|
        ansible.playbook = "ansible/playbook.yml"
        ansible.verbose = "v"
        ansible.inventory_path = "ansible/inventario/hosts" # Usa tu inventario custom
        ansible.limit = "192.168.56.10" # Limita al host específico de tu inventario
        ansible.config_file = "ansible/ansible.cfg" # Apunta a tu ansible.cfg del proyecto
      end

      config.vm.post_up_message = <<-MSG
🔴 ¡VM de la Aplicación de Votación lista!
======================================
Para acceder a la app Vote: [http://192.168.56.10:5000](http://192.168.56.10:5000)
Para acceder a la app Result: [http://192.168.56.10:8000](http://192.168.56.10:8000)
MSG
    end
    ```

2.  **`ansible/ansible.cfg`**: Crea este archivo en la carpeta `ansible/`.
    ```ini
    [defaults]
    inventory = inventario/hosts
    roles_path = roles
    collections_path = /usr/lib/python3/dist-packages/ # Ruta ABSOLUTA donde ansible-galaxy instala colecciones

    [privilege_escalation]
    become = True
    become_method = sudo
    become_user = root
    become_ask_pass = False
    _tee_use_sudo_nopasswd = False # Solución clave para el error 'chmod: invalid mode'
    ```

3.  **`ansible/inventario/hosts`**: Crea este archivo en `ansible/inventario/`.
    ```ini
    [webservers]
    192.168.56.10

    [all:vars]
    ansible_python_interpreter=/usr/bin/python3
    ansible_user=vagrant
    ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key # Ruta relativa a la raíz del proyecto
    # ansible_become_flags='-H -T /var/tmp' # Descomentar solo si el error 'chmod: invalid mode' persiste
    ```

4.  **`ansible/group_vars/webservers.yml`**: Crea este archivo en `ansible/group_vars/`. Aquí definimos las variables para los servicios.
    ```yaml
    ---
    # Variables generales del sistema
    system_packages:
      - git
      - curl
      - build-essential
      - python3-venv
      - python3-virtualenv # Para el módulo pip de Ansible
      - postgresql-client
      - net-tools
      - python3-psycopg2   # Para que Ansible pueda hablar con PostgreSQL
      - acl                # Para ayudar con permisos de archivos temporales

    # Configuración de PostgreSQL
    pg_version: "14"
    pg_user: "dbuser"
    pg_password: "dbpassword"
    pg_db: "votingapp"
    pg_host: "127.0.0.1" # Host de la DB (PostgreSQL corre en la misma VM)
    pg_port: 5432        # Puerto por defecto de PostgreSQL

    # Configuración de Redis
    redis_port: 6379
    redis_host: "127.0.0.1" # Host de Redis (Redis corre en la misma VM)

    # Configuración de Node.js (para Worker y Result)
    node_version: "18.x"
    pm2_version: "latest"

    # Rutas de la aplicación dentro de la VM
    app_base_path: /opt/app

    # Puertos de los servicios (accedidos desde el host)
    vote_app_port: 5000   # Puerto para la app Flask Vote
    worker_app_port: 8001 # Puerto interno para Gunicorn/Flask
    result_app_port: 8000 # Puerto para la app Node.js Result
    ```

5.  **`ansible/playbook.yml`**: Crea este archivo en la carpeta `ansible/`. Este es el guion principal que orquesta todos los roles.
    ```yaml
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

### Paso 3: Definir los Roles de Ansible (Archivos de Tareas y Plantillas)

Crea estos archivos dentro de las carpetas `tasks/main.yml`, `templates/*.j2` y `handlers/main.yml` de cada rol, según corresponda.

#### `ansible/roles/common/tasks/main.yml`
```yaml
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
