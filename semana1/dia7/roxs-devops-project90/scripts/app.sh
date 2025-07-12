#!/bin/bash

echo "🔴 Desafio Día 7"
echo "90 Days of DevOps by Roxs"
export DEBIAN_FRONTEND=noninteractive

LOG="desafio7.log"
APP=/home/vagrant/app/roxs-voting-app

configurar_entorno_vote() {
  cd $APP/vote || exit 1
  echo "Configurando entorno virtual..." | tee -a ../$LOG
  python3 -m venv venv && source venv/bin/activate
  pip install -r requirements.txt >> ../$LOG 2>&1
  pip install gunicorn >> ../$LOG 2>&1
}

configurar_gunicorn() {
  echo "Iniciando Gunicorn..." | tee -a ../$LOG
  # CORREGIDO: Eliminar el :app extra
  nohup venv/bin/gunicorn -w 4 -b 0.0.0.0:80 app:desafio7 >> ../$LOG 2>&1 &
  sleep 3  # Dar tiempo a que Gunicorn inicie
}

echo "=== Iniciando despliegue de...  ===" | tee $LOG
configurar_entorno_vote
configurar_gunicorn

echo "=== Despliegue finalizado ===" | tee -a ../$LOG
echo "Revisá $LOG para detalles." | tee -a ../$LOG
echo "La aplicación debería estar disponible en: http://$(hostname -I | awk '{print $1}')" | tee -a ../$LOG

