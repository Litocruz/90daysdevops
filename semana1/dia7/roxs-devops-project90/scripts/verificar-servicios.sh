#!/bin/bash
LOG="booklibrary.log"

verificar_servicios() {
SALIDA=4
while [ $SALIDA -ne 0 ];do
  echo "Verificando servicios..." | tee -a $LOG
  
  # Verificar Nginx
  if systemctl is-active --quiet nginx; then
    echo "✓ Nginx está activo" | tee -a $LOG
    SALIDA=$((SALIDA -1))
  else
    echo "✗ Nginx no está activo" | tee -a $LOG
    sudo systemctl restart nginx
  fi
  
  # Verificar Gunicorn
  if pgrep -f "gunicorn.*library_site" > /dev/null; then
    echo "✓ Gunicorn está corriendo" | tee -a $LOG
    SALIDA=$((SALIDA -1))
  else
    echo "✗ Gunicorn no está corriendo" | tee -a $LOG
    nohup venv/bin/gunicorn -w 4 -b 0.0.0.0:8000 library_site:app >> $LOG 2>&1 &
  fi
  
  # Verificar puerto 8000
  if netstat -tlnp | grep -q ":8000"; then
    echo "✓ Puerto 8000 está en uso" | tee -a $LOG
    SALIDA=$((SALIDA -1))
  else
    echo "✗ Puerto 8000 no está en uso" | tee -a $LOG
  fi
  
  # Probar conexión directa a Gunicorn
  if curl -s http://127.0.0.1:8000 > /dev/null; then
    echo "✓ Gunicorn responde correctamente" | tee -a $LOG
    SALIDA=$((SALIDA -1))
  else
    echo "✗ Gunicorn no responde" | tee -a $LOG
  fi
done
}
verificar_servicios
echo "$date - Servicio Corriendo correctamente" | tee -a $LOG
