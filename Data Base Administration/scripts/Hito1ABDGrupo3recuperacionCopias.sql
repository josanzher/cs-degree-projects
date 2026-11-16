#!/bin/bash
# Uso:
#   ./recuperacion.sh total <completa.sql.gz> "2026-11-04 10:15:00"
#   ./recuperacion.sh tabla <parcial.sql.gz>
 
BD="PRABD26"
BINLOGS="/backup/incremental"
 
case "$1" in
  total)
    COMPLETA="$2"; PARADA="$3"
 
    # 1) Restaurar la copia completa
    gunzip < "$COMPLETA" | mysql
 
    # 2) Leer el punto del binlog guardado en la copia
    LINEA=$(gunzip < "$COMPLETA" | head -n 60 | grep -m1 "LOG_FILE")
    BIN=$(echo "$LINEA" | grep -oP "LOG_FILE='\K[^']+")
    POS=$(echo "$LINEA" | grep -oP "LOG_POS=\K[0-9]+")
 
    # 3) Reaplicar cambios posteriores hasta justo antes del error
    FICHEROS=$(ls "$BINLOGS"/mysql-bin.[0-9]* | sort | sed -n "/$BIN/,\$p")
    mysqlbinlog --start-position="$POS" --stop-datetime="$PARADA" $FICHEROS | mysql
    ;;
  tabla)
    # Restaurar una tabla desde la copia parcial
    gunzip < "$2" | mysql "$BD"
    ;;
  *)
    echo "Uso: $0 total <completa> \"<fecha hora>\" | tabla <parcial>"
    exit 1
    ;;
esac