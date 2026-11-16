#!/bin/bash
# Programado con cron: 0 3 * * * /opt/abd/carga_diaria_abd.sh

BD="PRABD26"
FICHERO="/opt/abd/datosABD.txt"

# 1) Cargar el fichero en la tabla de staging
mysql --local-infile=1 "$BD" -e "
TRUNCATE stg_vuelos_planificacion;
LOAD DATA LOCAL INFILE '$FICHERO'
  INTO TABLE stg_vuelos_planificacion
  FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (numeroVuelo, codCompania, iataSalida, iataLlegada, fechaSalida, fechaLlegada);"

# 2) Pasar los datos a produccion
mysql "$BD" -e "CALL sp_carga_planificacion();"