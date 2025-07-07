#!/bin/bash

echo "🔴 Book Library - Instalacion de Dependencias"
echo "90 Days of DevOps by Roxs"
export DEBIAN_FRONTEND=noninteractive

LOG="booklibrary.log"

instalar_dependencias() {
  echo "Instalando dependencias..." | tee -a $LOG
  sudo apt update && sudo apt install -y python3 python3-pip python3-venv nginx git net-tools >> $LOG 2>&1
  sudo systemctl enable nginx >> $LOG 2>&1
  sudo systemctl start nginx >> $LOG 2>&1
  echo "✅ Dependencias instaladas." | tee -a $LOG
}

clonar_app() {
  echo "Clonando la aplicación..." | tee -a $LOG
  git clone -b booklibrary https://github.com/roxsross/devops-static-web.git >> $LOG 2>&1
  cd devops-static-web
}

configurar_entorno() {
  echo "Configurando entorno virtual..." | tee -a ../$LOG
  python3 -m venv venv && source venv/bin/activate
  pip install -r requirements.txt >> ../$LOG 2>&1
  pip install gunicorn >> ../$LOG 2>&1
}

configurar_gunicorn() {
  echo "Iniciando Gunicorn..." | tee -a ../$LOG
  # CORREGIDO: Eliminar el :app extra
  nohup venv/bin/gunicorn -w 4 -b 0.0.0.0:8000 library_site:app >> ../$LOG 2>&1 &
  sleep 3  # Dar tiempo a que Gunicorn inicie
}

  echo "=== Iniciando despliegue de Book Library ===" | tee $LOG
  instalar_dependencias
  clonar_app
  configurar_entorno
  configurar_gunicorn
  
  echo "=== Despliegue finalizado ===" | tee -a ../$LOG
  echo "Revisá $LOG para detalles." | tee -a ../$LOG
  echo "La aplicación debería estar disponible en: http://$(hostname -I | awk '{print $1}')" | tee -a ../$LOG

