#!/bin/bash
# Copia parcial diaria. Uso: backup_parcial.sh vuelo | viajeros
# Cron: 03:30 (vuelo) y 04:30 (viajeros)
 
BD="PRABD26"
DEST="/backup"
REMOTO="usuario@vm2:/backup"
FECHA=$(date +%F)
 
case "$1" in
  vuelo)    TABLAS="Vuelo log_carga_planificacion" ;;
  viajeros) TABLAS="Billete Pasajero PNR Equipaje Pago API Menor" ;;
  *) echo "Uso: $0 vuelo | viajeros"; exit 1 ;;
esac
 
mysqldump --single-transaction "$BD" $TABLAS | gzip > "$DEST/parcial/${1}_$FECHA.sql.gz"
 
# Rotacion: 7 dias
find "$DEST/parcial" -name "${1}_*" -mtime +7 -delete
 
rsync -a --delete "$DEST/" "$REMOTO"