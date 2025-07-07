#!/bin/bash

source ./app.sh

main() {
  echo "=== Iniciando despliegue de Book Library ===" | tee $LOG
  instalar_dependencias
  clonar_app
  configurar_entorno
  configurar_gunicorn
  
  echo "=== Despliegue finalizado ===" | tee -a ../$LOG
  echo "Revisá $LOG para detalles." | tee -a ../$LOG
  echo "La aplicación debería estar disponible en: http://$(hostname -I | awk '{print $1}')" | tee -a ../$LOG
}

main
