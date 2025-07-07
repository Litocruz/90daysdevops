#!/bin/bash

echo "🐍 Setup services"

#python3 -m venv /home/vagrant/pokemon-env
#source /home/vagrant/pokemon-env/bin/activate

declare -A services
sevices[frontend]="3000"
sevices[products]="3001"
sevices[shopping-cart]="3002"
sevices[merchandise]="3003"

for service in "${!services[@]}"; do
    echo "$service: ${services[$service]}"
    cd /vagrant/$service
    npm install
    pm2 start server.js --name $service -- -p ${services[$service]}
done
echo "Estado Aplicaciones"
pm2 list
pm2 save
#cd /vagrant/backend
#pip install -r requirements.txt

echo "✅ Backends configurado"
