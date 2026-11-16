USE PRABD26;
CREATE TABLE IF NOT EXISTS stg_vuelos_planificacion (
    linea INT AUTO_INCREMENT PRIMARY KEY,
    numeroVuelo VARCHAR(10) NOT NULL,
    codCompania CHAR(3) NOT NULL,
    iataSalida CHAR(3) NOT NULL,
    iataLlegada CHAR(3) NOT NULL,
    fechaSalida DATETIME NOT NULL,
    fechaLlegada DATETIME NOT NULL
);
CREATE TABLE IF NOT EXISTS log_carga_planificacion (
    id INT AUTO_INCREMENT PRIMARY KEY,
    momento DATETIME DEFAULT CURRENT_TIMESTAMP,
    codCompania CHAR(3),
    resultado VARCHAR(10),
    insertadas INT,
    rechazadas INT
);

DROP PROCEDURE IF EXISTS sp_carga_planificacion;

DELIMITER $$

CREATE PROCEDURE sp_carga_planificacion()
BEGIN
    DECLARE v_comp  CHAR(3);
    DECLARE v_fin   INT DEFAULT 0;
    DECLARE v_err   INT DEFAULT 0;
    DECLARE v_ins   INT DEFAULT 0;
    DECLARE v_total INT DEFAULT 0;

    DECLARE cur CURSOR FOR
        SELECT DISTINCT codCompania
        FROM stg_vuelos_planificacion
        ORDER BY codCompania;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_fin = 1;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        SET v_err = 1;

    SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

    OPEN cur;

    bucle: LOOP
        FETCH cur INTO v_comp;

        IF v_fin = 1 THEN
            LEAVE bucle;
        END IF;

        SET v_err = 0;
        SET v_ins = 0;

        SELECT COUNT(*)
        INTO v_total
        FROM stg_vuelos_planificacion
        WHERE codCompania = v_comp;

        START TRANSACTION;

        INSERT INTO Vuelo (
            numeroVuelo,
            codCompania,
            fechaSalida,
            fechaLlegada,
            aeropuertoSalida,
            aeropuertoLlegada,
            estadoVuelo
        )
        SELECT
            s.numeroVuelo,
            s.codCompania,
            s.fechaSalida,
            s.fechaLlegada,
            s.iataSalida,
            s.iataLlegada,
            'PROGRAMADO'
        FROM stg_vuelos_planificacion s
        JOIN Compania c
            ON c.codCompania = s.codCompania
        JOIN Aeropuerto a1
            ON a1.codIATA = s.iataSalida
        JOIN Aeropuerto a2
            ON a2.codIATA = s.iataLlegada
        WHERE s.codCompania = v_comp
          AND s.fechaLlegada > s.fechaSalida
          AND s.iataSalida <> s.iataLlegada
          AND NOT EXISTS (
              SELECT 1
              FROM Vuelo v
              WHERE v.numeroVuelo = s.numeroVuelo
                AND v.fechaSalida = s.fechaSalida
          )
        ORDER BY s.numeroVuelo, s.fechaSalida;

        IF v_err = 0 THEN
            SET v_ins = ROW_COUNT();

            COMMIT;

            INSERT INTO log_carga_planificacion
                (codCompania, resultado, insertadas, rechazadas)
            VALUES
                (v_comp, 'OK', v_ins, v_total - v_ins);
        ELSE
            ROLLBACK;

            INSERT INTO log_carga_planificacion
                (codCompania, resultado, insertadas, rechazadas)
            VALUES
                (v_comp, 'ERROR', 0, v_total);
        END IF;

    END LOOP;

    CLOSE cur;
END$$

DELIMITER ;

INSERT INTO stg_vuelos_planificacion
    (numeroVuelo, codCompania, iataSalida, iataLlegada,
     fechaSalida, fechaLlegada)
VALUES
    ('TEST101', 'IBE', 'MAD', 'CDG',
     '2026-11-10 08:00:00', '2026-11-10 09:00:00'),
    ('TEST102', 'IBE', 'MAD', 'BCN',
     '2026-11-10 10:00:00', '2026-11-10 11:00:00');

CALL sp_carga_planificacion();

SELECT * FROM Vuelo
WHERE numeroVuelo IN ('TEST101', 'TEST102');

SELECT * FROM log_carga_planificacion
ORDER BY id DESC;