#!/bin/bash

echo "🔴 Book Library - Instalacion de Dependencias"
echo "90 Days of DevOps by Roxs"
export DEBIAN_FRONTEND=noninteractive

LOG=booklibrary.log

echo "Instalando dependencias..." | tee -a $LOG
sudo apt update && sudo apt install -y python3 python3-pip python3-venv nginx git >> $LOG 2>&1

