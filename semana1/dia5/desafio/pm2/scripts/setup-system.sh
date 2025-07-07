#!/bin/bash

LOG="ecommerce.log"
export DEBIAN_FRONTEND=noninteractive

install-dependencies(){
  echo "🔴 Ecommerce - Setup Sistema" | tee -a $LOG
  echo "90 Days of DevOps by Roxs" | tee -a $LOG
  apt-get update -y >> $LOG 2>&1
  apt-get install -y curl wget git vim htop python3 python3-pip python3-venv >> $LOG 2>&1
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >> $LOG 2>&1
  apt-get install -y nodejs >> $LOG 2>&1
  npm install -g npm@11.4.2 >> $LOG 2>&1
  sudo npm install -g pm2 >> $LOG 2>&1

  echo "✅ Sistema configurado" | tee -a $LOG
}

install-dependencies

