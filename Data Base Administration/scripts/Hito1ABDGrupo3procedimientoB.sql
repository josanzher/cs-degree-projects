USE PRABD26;

DROP PROCEDURE IF EXISTS estadisticas_destinos_bloqueo;

DELIMITER //

CREATE PROCEDURE estadisticas_destinos_bloqueo(
    IN p_codCompania CHAR(3)
)
BEGIN
    DECLARE v_inicio DATE;
    DECLARE v_fin DATE;
    DECLARE v_cod CHAR(3);

    SET v_inicio = DATE_ADD(LAST_DAY(CURDATE()), INTERVAL 1 DAY);
    SET v_fin = DATE_ADD(v_inicio, INTERVAL 1 MONTH);

    -- 1er recurso: fila de la compania, bloqueo compartido
    SELECT codCompania INTO v_cod
    FROM Compania
    WHERE codCompania = p_codCompania
    FOR SHARE;

    -- 2o recurso: vuelos del mes siguiente, bloqueo compartido
    SELECT c.codCompania, c.nombre AS compania,
           a.codIATA AS codigoDestino, a.nombre AS destino,
           COUNT(*) AS numeroVuelos
    FROM Vuelo v
    JOIN Compania c ON c.codCompania = v.codCompania
    JOIN Aeropuerto a ON a.codIATA = v.aeropuertoLlegada
    WHERE v.codCompania = p_codCompania
      AND v.fechaSalida >= v_inicio
      AND v.fechaSalida < v_fin
    GROUP BY c.codCompania, c.nombre, a.codIATA, a.nombre
    ORDER BY numeroVuelos DESC
    FOR SHARE OF v;
END //

DELIMITER ;