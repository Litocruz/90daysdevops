#!/bin/bash
#
LOG=booklibrary.log

echo "Configurando Nginx..." | tee -a ../$LOG
  
# NUEVO: Eliminar configuración por defecto
sudo rm -f /etc/nginx/sites-enabled/default

# CORREGIDO: Usar 127.0.0.1:8000 en lugar de 0.0.0.0:8000
sudo tee /etc/nginx/sites-available/booklibrary > /dev/null <<EOF

server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
    }
    
    location /static/ {
        alias $(pwd)/static/;
        expires 30d;
    }
    
    access_log /var/log/nginx/booklibrary_access.log;
    error_log /var/log/nginx/booklibrary_error.log;
}
EOF
sudo systemctl enable nginx >> ../$LOG 2>&1
sudo systemctl start nginx >> ../$LOG 2>&1
sudo ln -sf /etc/nginx/sites-available/booklibrary /etc/nginx/sites-enabled/
sudo nginx -t >> ../$LOG 2>&1 && sudo systemctl reload nginx

echo "=== Despliegue finalizado ===" | tee -a ../$LOG
echo "Revisá $LOG para detalles." | tee -a ../$LOG
echo "La aplicación debería estar disponible en: http://$(hostname -I | awk '{print $1}')" | tee -a ../$LOG
