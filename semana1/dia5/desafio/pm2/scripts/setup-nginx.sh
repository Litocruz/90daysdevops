#!/bin/bash

# eCommerce DevOps - Setup Nginx Simple
# 90 Days of DevOps Challenge by Roxs

echo "🌐 Configurando Nginx..."

export DEBIAN_FRONTEND=noninteractive

apt-get install -y nginx

cat > /etc/nginx/sites-available/ecommerce-app << 'EOF'
server {
    listen 80;
    server_name localhost 192.168.56.12;
    
    # Agregar header personalizado
    add_header X-DevOps-Challenge "90-Days-by-Roxs";
    
    # Frontend React (ruta principal)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Backend Produtos (ruta /products)
    location /products/ {
        proxy_pass http://localhost:3001/products/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # Backend shopping-cart (ruta /shopping-cart)
    location /shopping-cart/ {
        proxy_pass http://localhost:3002/shopping-cart/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # Backend mercandise (ruta /mercandise)
    location /mercandise/ {
        proxy_pass http://localhost:3003/mercandise/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # API Docs
    location /docs {
        proxy_pass http://localhost:8000/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:8000/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

ln -sf /etc/nginx/sites-available/ecommerce-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t

systemctl enable nginx
systemctl start nginx

echo "✅ Nginx configurado en puerto 80"
echo "🌐 URLs:"
echo "  • App completa: http://192.168.56.12"
echo "  • Productos: http://192.168.56.12/products/"
echo "  • Shopping cart: http://192.168.56.12/shopping-cart/"
echo "  • Merchandise: http://192.168.56.12/mercandise/"
echo "  • Docs: http://192.168.56.12/docs"
