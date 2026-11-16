USE PRABD26;
START TRANSACTION;

INSERT INTO Vuelo
(numeroVuelo, codCompania, fechaSalida, fechaLlegada,
 aeropuertoSalida, aeropuertoLlegada, estadoVuelo)
VALUES
('TEST201', 'IBE', '2026-11-15 08:00:00',
 '2026-11-15 09:00:00', 'MAD', 'CDG', 'PROGRAMADO');

INSERT INTO Vuelo
(numeroVuelo, codCompania, fechaSalida, fechaLlegada,
 aeropuertoSalida, aeropuertoLlegada, estadoVuelo)
VALUES
('TEST202', 'IBE', '2026-11-15 10:00:00',
 '2026-11-15 11:00:00', 'MAD', 'BCN', 'PROGRAMADO');

DO SLEEP(15);

SELECT * FROM Compania WHERE codCompania = 'IBE' FOR UPDATE;

COMMIT;