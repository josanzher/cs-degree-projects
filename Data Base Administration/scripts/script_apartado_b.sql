DELIMITER //

CREATE PROCEDURE ImportarDatosABD()
BEGIN

-- Eliminamos la tabla temporal de volcado, en caso de que existan para evitar conflictos --
DROP TEMPORARY TABLE IF EXISTS TempImportacion;

-- Creamos la tabla temporal para volcar el contenido del .txt
CREATE TEMPORARY TABLE TempImportacion (
        tipo_registro VARCHAR(50),
        col1 VARCHAR(255),
        col2 VARCHAR(255),
        col3 VARCHAR(255),
        col4 VARCHAR(255),
        col5 VARCHAR(255),
        col6 VARCHAR(255),
        col7 VARCHAR(255),
        col8 VARCHAR(255)
);

-- Cargmos el fichero datosABD.txt (debe estar en la mismo directorio que este script)
LOAD DATA INFILE '/var/lib/mysql-files/datosABD.txt'
INTO TABLE TempImportacion
CHARACTER SET utf8mb4                   -- Codificacion !!
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(tipo_registro, col1, col2, col3, col4, col5, col6, col7, col8);

-- Iniciamos transacción
START TRANSACTION;

-- Insertar compañias
INSERT IGNORE INTO Compania (codCompania, nombre, pais)
SELECT col1, col2, col3
FROM TempImportacion
WHERE tipo_registro = 'COMPANIA';

-- Insertar Aeropuertos

INSERT IGNORE INTO Aeropuerto (codIATA, nombre, ciudad, pais, continente)
SELECT col1, col2, col3, col4, col5
FROM TempImportacion
WHERE tipo_registro = 'AEROPUERTO';


-- Insertar Vuelos
INSERT IGNORE INTO Vuelo (idVuelo, numeroVuelo, codCompania, fechaSalida, fechaLlegada, aeropuertoSalida, aeropuertoLlegada, estadoVuelo)
SELECT col1, col2, col3, col4, col5, col6, col7, col8
FROM TempImportacion
WHERE tipo_registro = 'VUELO';

-- Insertar Pasajeros
INSERT IGNORE INTO Pasajero (idPasajero, numeroDocumento, nombre, apellidos, numeroTelefono, direccion, correoElectronico)
SELECT col1, col2, col3, col4, col5, col6, col7
FROM TempImportacion
WHERE tipo_registro = 'PASAJERO';


-- Insertar Tripulacion
INSERT IGNORE INTO Tripulacion (NSS, nombre, apellidos, rol, numeroDocumento)
SELECT col1, col2, col3, col4, col5
FROM TempImportacion
WHERE tipo_registro = 'TRIPULACION';

-- Insertar API
INSERT IGNORE INTO API (numeroDocumento, tipoDocumento, paisEmision, nacionalidad)
SELECT col1, col2, col3, col4
FROM TempImportacion
WHERE tipo_registro = 'API';

-- Insertar Billete
INSERT IGNORE INTO Billete (idBillete, localizadorPNR, idPasajero, fechaEmision, soloIda, tarifa, estadoPasaje)
SELECT col1, col2, col3, col4, col5, col6, col7
FROM TempImportacion
WHERE tipo_registro = 'BILLETE';

-- Insertar Billete_Vuelo
INSERT IGNORE INTO Billete_Vuelo (idBillete, idVuelo, orden, numAsiento)
SELECT col1, col2, col3, col4
FROM TempImportacion
WHERE tipo_registro = 'BILLETE_VUELO';

-- Insertar Equipaje
INSERT IGNORE INTO Equipaje (idEquipaje, idBillete, descripcion, numeroBultos)
SELECT col1, col2, col3, col4
FROM TempImportacion
WHERE tipo_registro = 'EQUIPAJE';

-- Insertar EquipajeTripulacion
INSERT IGNORE INTO EquipajeTripulacion (idEquipajeT, NSS, descripcion, numeroBultos)
SELECT col1, col2, col3, col4
FROM TempImportacion
WHERE tipo_registro = 'EQUIPAJE_TRIPULACION';

-- Insertar Menor
INSERT IGNORE INTO MENOR (idPasajero, sexo, datosAcompananteSalida, datosAcompananteLlegada, vinculoAcompananteSalida, vinculoAcompananteLlegada, agenteSalida, agenteLlegada)
SELECT col1, col2, col3, col4, col5, col6, col7, col8
FROM TempImportacion
WHERE tipo_registro = 'MENOR';

-- Insertar PNR
INSERT IGNORE INTO PNR (localizador, fechaReservaBillete, fechaEmisionBillete, fechaPrevistaViaje, idPago)
SELECT col1, col2, col3, col4, col5
FROM TempImportacion
WHERE tipo_registro = 'PNR';

-- Insertar Pago
INSERT IGNORE INTO Pago (idPago, metodoPago, direccionFacturacion)
SELECT col1, col2, col3
FROM TempImportacion
WHERE tipo_registro = 'PAGO';


-- Insertar Vuelo_Tripulacion
INSERT IGNORE INTO Vuelo_Tripulacion (idVuelo, NSS)
SELECT col1, col2
FROM TempImportacion
WHERE tipo_registro = 'VUELO_TRIPULACION';


COMMIT;

DROP TEMPORARY TABLE IF EXISTS TempImportacion;
END //

DELIMITER ;