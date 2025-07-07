#!/bin/bash

LOG=/.ecommerce.log
declare -A services

deploy-services(){  
  echo "🐍 Setup services" | tee -a $LOG
  
  services[frontend]="3000"
  services[products]="3001"
  services[shopping-cart]="3002"
  services[merchandise]="3003"
  
  for service in "${!services[@]}"; do
      echo "$service: ${services[$service]}" | tee -a $LOG
      cd /vagrant/$service >> $LOG 2>&1
      npm install >> ../$LOG 2>&1
      pm2 start server.js --name $service -- -p ${services[$service]} >> ../$LOG 2>&1
  done
  echo "Aplicaciones configuradas y lanzadas" | tee -a $LOG#
}

save-services(){
  echo "Guardando servicios pm2" | tee -a $LOG
  pm2 save >> $LOG 2>&1
  pm2 startup systemd -u $USER --hp $HOME >> $LOG 2>&1
}

service-check(){
  echo "Estado de los servicios "| tee -a $LOG
#  pm2 monitor >> $LOG 2>&1
}

deploy-services
save-services
service-check

echo "✅ Backends configurado" | tee -a $LOG
