USE PRABD26;

-- 1. Crear tabla temporal para importar el fichero
DROP TEMPORARY TABLE IF EXISTS TempImportacion;

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

LOAD DATA INFILE '/var/lib/mysql-files/datosABD.txt'
INTO TABLE TempImportacion
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(tipo_registro, col1, col2, col3, col4, col5, col6, col7, col8);

-- 3. Asegurar que existen las compañías necesarias
INSERT IGNORE INTO Compania (codCompania, nombre, pais)
VALUES
('IBE', 'Iberia', 'España'),
('AEA', 'Air Europa', 'España'),
('VLG', 'Vueling', 'España'),
('AFR', 'Air France', 'Francia'),
('BAW', 'British Airways', 'Reino Unido'),
('DLH', 'Lufthansa', 'Alemania'),
('KLM', 'KLM', 'Países Bajos'),
('AAL', 'American Airlines', 'Estados Unidos'),
('DAL', 'Delta Air Lines', 'Estados Unidos');

-- 4. Asegurar que existen los aeropuertos necesarios
INSERT IGNORE INTO Aeropuerto
    (codIATA, nombre, ciudad, pais, continente)
VALUES
('MAD', 'Aeropuerto de Madrid-Barajas',
 'Madrid', 'España', 'Europa'),
('BCN', 'Aeropuerto de Barcelona-El Prat',
 'Barcelona', 'España', 'Europa'),
('CDG', 'Aeropuerto Charles de Gaulle',
 'París', 'Francia', 'Europa'),
('LHR', 'Aeropuerto de Heathrow',
 'Londres', 'Reino Unido', 'Europa'),
('VLL', 'Aeropuerto de Valladolid',
 'Valladolid', 'España', 'Europa'),
('FRA', 'Aeropuerto de Frankfurt',
 'Frankfurt', 'Alemania', 'Europa'),
('AMS', 'Aeropuerto de Schiphol',
 'Ámsterdam', 'Países Bajos', 'Europa'),
('JFK', 'Aeropuerto John F. Kennedy',
 'Nueva York', 'Estados Unidos', 'América'),
('ATL', 'Aeropuerto Hartsfield-Jackson',
 'Atlanta', 'Estados Unidos', 'América');

START TRANSACTION;

-- 5. Insertar API
INSERT IGNORE INTO API
    (numeroDocumento, tipoDocumento, paisEmision, nacionalidad)
SELECT
    col1, col2, col3, col4
FROM TempImportacion
WHERE tipo_registro = 'API';

-- 6. Insertar pasajeros
INSERT IGNORE INTO Pasajero
    (numeroTelefono, nombre, apellidos,
             direccion, correoElectronico, numeroDocumento)
SELECT
    col1, col2, col3, col4, col5, col6
FROM TempImportacion
WHERE tipo_registro = 'PASAJERO';

-- 7. Insertar vuelos
-- Se obtiene el código de compañía a partir del prefijo
-- del número de vuelo.
INSERT INTO Vuelo
    (numeroVuelo, codCompania, fechaSalida, fechaLlegada,
     aeropuertoSalida, aeropuertoLlegada, estadoVuelo)
SELECT
    t.col1,
    CASE LEFT(t.col1, 2)
        WHEN 'IB' THEN 'IBE'
        WHEN 'UX' THEN 'AEA'
        WHEN 'VY' THEN 'VLG'
        WHEN 'AF' THEN 'AFR'
        WHEN 'BA' THEN 'BAW'
        WHEN 'LH' THEN 'DLH'
        WHEN 'KL' THEN 'KLM'
        WHEN 'AA' THEN 'AAL'
        WHEN 'DL' THEN 'DAL'
    END,
    t.col2,
    t.col3,
    t.col4,
    t.col5,
    UPPER(t.col6)
FROM TempImportacion AS t
INNER JOIN Compania AS c
        ON c.codCompania =
        CASE LEFT(t.col1, 2)
            WHEN 'IB' THEN 'IBE'
            WHEN 'UX' THEN 'AEA'
            WHEN 'VY' THEN 'VLG'
            WHEN 'AF' THEN 'AFR'
            WHEN 'BA' THEN 'BAW'
            WHEN 'LH' THEN 'DLH'
            WHEN 'KL' THEN 'KLM'
            WHEN 'AA' THEN 'AAL'
            WHEN 'DL' THEN 'DAL'
        END
INNER JOIN Aeropuerto AS a1
    ON a1.codIATA = t.col4
INNER JOIN Aeropuerto AS a2
    ON a2.codIATA = t.col5
WHERE t.tipo_registro = 'VUELO'
  AND t.col2 < t.col3
  AND t.col4 <> t.col5
  AND NOT EXISTS (
      SELECT 1
      FROM Vuelo AS v
      WHERE v.numeroVuelo = t.col1
        AND v.fechaSalida = t.col2
  );

-- 8. Insertar tripulación
INSERT IGNORE INTO Tripulacion
    (NSS, nombre, apellidos, rol)
SELECT
    col1, col2, col3, col4
FROM TempImportacion
    WHERE tipo_registro = 'TRIPULACION';

-- 9. Insertar pagos
INSERT IGNORE INTO Pago
    (idPago, direccionFacturacion)
SELECT
    col1, col2
FROM TempImportacion
WHERE tipo_registro = 'PAGO';

-- 10. Insertar PNR
-- Se relaciona cada reserva con su pasajero mediante el teléfono.
INSERT IGNORE INTO PNR
    (localizador, fechaReservaBillete, fechaEmisionBillete,
     fechaPrevistaViaje, idPago, idPasajero)
SELECT
    t.col1,
    t.col2,
    t.col3,
    t.col4,
    p.idPago,
    pa.idPasajero
FROM TempImportacion AS t
INNER JOIN Pago AS p
    ON p.idPago = CAST(t.col5 AS UNSIGNED)
INNER JOIN Pasajero AS pa
    ON pa.numeroTelefono = t.col6
WHERE t.tipo_registro = 'PNR';

-- 11. Insertar billetes
-- Se recuperan los identificadores reales del vuelo y pasajero.
INSERT IGNORE INTO Billete
    (idBillete, localizadorPNR, idPasajero, idVuelo,
     fechaEmision, soloIda, tarifa, estadoPasaje)
SELECT
    CAST(t.col1 AS UNSIGNED),
    pn.localizador,
    pn.idPasajero,
    v.idVuelo,
    t.col2,
    CAST(t.col3 AS UNSIGNED),
    t.col4,
    t.col5
FROM TempImportacion AS t
INNER JOIN PNR AS pn
    ON pn.localizador = t.col7
INNER JOIN Vuelo AS v
    ON v.numeroVuelo = t.col6
WHERE t.tipo_registro = 'BILLETE';

-- 12. Insertar equipaje de pasajeros
INSERT IGNORE INTO Equipaje
    (idEquipaje, idBillete, descripcion, numeroBultos)
SELECT
    CAST(t.col1 AS UNSIGNED),
    CAST(t.col4 AS UNSIGNED),
    t.col2,
    CAST(t.col3 AS UNSIGNED)
FROM TempImportacion AS t
WHERE t.tipo_registro = 'EQUIPAJE';

-- 13. Insertar equipaje de tripulación
INSERT IGNORE INTO EquipajeTripulacion
    (idEquipajeT, NSS, descripcion, numeroBultos)
SELECT
    CAST(t.col1 AS UNSIGNED),
    CAST(t.col2 AS UNSIGNED),
    t.col3,
    CAST(t.col4 AS UNSIGNED)
FROM TempImportacion AS t
WHERE t.tipo_registro = 'EQUIPAJE_TRIPULACION';

-- 14. Insertar menores
-- Se relacionan con Pasajero mediante su número de teléfono.
INSERT IGNORE INTO Menor
    (idPasajero, sexo, datosAcompananteSalida,
     datosAcompananteLlegada, vinculoAcompananteSalida,
     vinculoAcompananteLlegada, agenteSalida, agenteLlegada)
SELECT
    pa.idPasajero,
    t.col2,
    t.col3,
    t.col4,
    t.col5,
    t.col6,
    t.col7,
    t.col8
FROM TempImportacion AS t
INNER JOIN Pasajero AS pa
    ON pa.numeroTelefono = t.col1
WHERE t.tipo_registro = 'MENOR';

COMMIT;

-- 15. Eliminar la tabla temporal
DROP TEMPORARY TABLE IF EXISTS TempImportacion;