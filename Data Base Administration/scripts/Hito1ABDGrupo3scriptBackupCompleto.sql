#!/bin/bash
# Copia completa semanal (logica, online). Cron: domingos 01:00
 
BD="PRABD26"
DEST="/backup"
REMOTO="usuario@vm2:/backup"
EXTERNO="usuario@externo:/backup"
FECHA=$(date +%F)
FICHERO="$DEST/completa/completa_$FECHA.sql.gz"
 
# Volcado consistente sin bloquear (InnoDB), comprimido
mysqldump --single-transaction --routines --triggers --events \
          --source-data=2 --databases "$BD" | gzip > "$FICHERO"
 
# Copia mensual: primer domingo de cada mes (12 meses)
if [ "$(date +%d)" -le 7 ]; then
  cp "$FICHERO" "$DEST/mensual/"
fi
 
# Rotacion: 4 semanales y 12 mensuales
find "$DEST/completa" -name "completa_*" -mtime +28  -delete
find "$DEST/mensual"  -name "completa_*" -mtime +365 -delete
 
# Copias en la 2.a maquina y en el almacenamiento externo
rsync -a --delete "$DEST/" "$REMOTO"
rsync -a "$FICHERO" "$EXTERNO"