#!/bin/bash
# Copia incremental diaria (registros binarios). Cron: 23:30
 
DEST="/backup"
BINLOGS="/var/log/mysql-binlog"
REMOTO="usuario@vm2:/backup"
 
# Cierra el binlog actual: los anteriores quedan completos
mysql -e "FLUSH BINARY LOGS;"
 
rsync -a "$BINLOGS"/mysql-bin.[0-9]* "$DEST/incremental/"
 
# Rotacion: 30 dias
find "$DEST/incremental" -name "mysql-bin.*" -mtime +30 -delete
 
rsync -a --delete "$DEST/" "$REMOTO"