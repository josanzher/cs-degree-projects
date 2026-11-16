DROP DATABASE IF EXISTS PRABD26;
CREATE DATABASE PRABD26;
USE PRABD26;

-- ---------- Catálogos ----------
CREATE TABLE Compania (
  codCompania  CHAR(3)      NOT NULL,
  nombre       VARCHAR(80)  NOT NULL,
  pais         VARCHAR(50),
  PRIMARY KEY (codCompania)
);

CREATE TABLE Aeropuerto (
  codIATA      CHAR(3)      NOT NULL,
  nombre       VARCHAR(80)  NOT NULL,
  ciudad       VARCHAR(50)  NOT NULL,
  pais         VARCHAR(50)  NOT NULL,
  continente   VARCHAR(20)  NOT NULL,
  PRIMARY KEY (codIATA)
);-- ---------- Documento (API) ----------
CREATE TABLE API (
  numeroDocumento VARCHAR(20) NOT NULL,
  tipoDocumento   VARCHAR(30) NOT NULL,
  paisEmision     VARCHAR(50),
  nacionalidad    VARCHAR(50),
  PRIMARY KEY (numeroDocumento)
);

-- ---------- Vuelos ----------
CREATE TABLE Vuelo (
  idVuelo            INT         NOT NULL      AUTO_INCREMENT,
  numeroVuelo        VARCHAR(10) NOT NULL,
  codCompania        CHAR(3)     NOT NULL,
  fechaSalida        DATETIME    NOT NULL,
  fechaLlegada       DATETIME    NOT NULL,
  aeropuertoSalida   CHAR(3)     NOT NULL,
  aeropuertoLlegada  CHAR(3)     NOT NULL,
  estadoVuelo        VARCHAR(30) NOT NULL DEFAULT 'PROGRAMADO',
  PRIMARY KEY (idVuelo),
  CONSTRAINT fk_vuelo_compania FOREIGN KEY (codCompania)       REFERENCES Compania(codCompania),
  CONSTRAINT fk_vuelo_origen   FOREIGN KEY (aeropuertoSalida)  REFERENCES Aeropuerto(codIATA),
  CONSTRAINT fk_vuelo_destino  FOREIGN KEY (aeropuertoLlegada) REFERENCES Aeropuerto(codIATA),
  CONSTRAINT ck_vuelo_fechas   CHECK (fechaLlegada > fechaSalida),
  CONSTRAINT ck_vuelo_aerop    CHECK (aeropuertoSalida <> aeropuertoLlegada),
  UNIQUE KEY uq_vuelo_numero_fecha (numeroVuelo, fechaSalida)
);-- ---------- Tripulación ----------
CREATE TABLE Tripulacion (
  NSS             BIGINT      NOT NULL,
  nombre          VARCHAR(30) NOT NULL,
  apellidos       VARCHAR(30) NOT NULL,
  rol             VARCHAR(30) NOT NULL,
  numeroDocumento VARCHAR(20),
  PRIMARY KEY (NSS),
  UNIQUE KEY uq_trip_doc (numeroDocumento),
  CONSTRAINT fk_trip_api FOREIGN KEY (numeroDocumento) REFERENCES API(numeroDocumento)
);

CREATE TABLE Vuelo_Tripulacion (
  idVuelo     INT         NOT NULL,
  NSS         BIGINT      NOT NULL,
  PRIMARY KEY (idVuelo, NSS),
  CONSTRAINT fk_vt_vuelo FOREIGN KEY (idVuelo) REFERENCES Vuelo(idVuelo),
  CONSTRAINT fk_vt_trip  FOREIGN KEY (NSS)         REFERENCES Tripulacion(NSS)
);

CREATE TABLE EquipajeTripulacion (
  idEquipajeT   INT         NOT NULL AUTO_INCREMENT,
  NSS           BIGINT      NOT NULL,
  descripcion   VARCHAR(30),
  numeroBultos  INT         NOT NULL DEFAULT 0,
  PRIMARY KEY (idEquipajeT),
  CONSTRAINT fk_eqt_trip FOREIGN KEY (NSS) REFERENCES Tripulacion(NSS),
  CONSTRAINT ck_eqt_bultos CHECK (numeroBultos >= 0)
);-- ---------- Pasajeros ----------
CREATE TABLE Pasajero (
  idPasajero      INT          NOT NULL AUTO_INCREMENT,
  numeroDocumento VARCHAR(20)  UNIQUE,
  nombre          VARCHAR(50)  NOT NULL,
  apellidos       VARCHAR(80)  NOT NULL,
  numeroTelefono  VARCHAR(15),
  direccion       VARCHAR(100),
  correoElectronico VARCHAR(100),
  PRIMARY KEY (idPasajero),
  CONSTRAINT fk_pasajero_api FOREIGN KEY (numeroDocumento) REFERENCES API(numeroDocumento)
);

CREATE TABLE Menor (
  idPasajero                 INT          NOT NULL,
  sexo                       CHAR(1),
  datosAcompananteSalida     VARCHAR(100),
  datosAcompananteLlegada    VARCHAR(100),
  vinculoAcompananteSalida   VARCHAR(50),
  vinculoAcompananteLlegada  VARCHAR(50),
  agenteSalida               VARCHAR(50),
  agenteLlegada              VARCHAR(50),
  PRIMARY KEY (idPasajero),
  CONSTRAINT fk_menor_pasajero FOREIGN KEY (idPasajero) REFERENCES Pasajero(idPasajero) ON DELETE CASCADE
);
-- ---------- Pago, PNR, Billete ----------
CREATE TABLE Pago (
  idPago              INT          NOT NULL AUTO_INCREMENT,
  metodoPago          VARCHAR(30),
  direccionFacturacion VARCHAR(150),
  PRIMARY KEY (idPago)
);

CREATE TABLE PNR (
  localizador          VARCHAR(20) NOT NULL,
  fechaReservaBillete  DATE        NOT NULL,
  fechaEmisionBillete  DATE,
  fechaPrevistaViaje   DATE,
  idPago               INT,
  idPasajero           INT NOT NULL,
  PRIMARY KEY (localizador),
  CONSTRAINT fk_pnr_pago FOREIGN KEY (idPago) REFERENCES Pago(idPago),
  CONSTRAINT fk_pnr_pasajero FOREIGN KEY (idPasajero) REFERENCES Pasajero(idPasajero)

);

CREATE TABLE Billete (
  idBillete      INT          NOT NULL AUTO_INCREMENT,
  localizadorPNR VARCHAR(20)  NOT NULL,
  idPasajero     INT          NOT NULL,
  idVuelo        INT          NOT NULL,
  fechaEmision   DATE,
  soloIda        INT   NOT NULL DEFAULT 1,
  tarifa         VARCHAR(30),
  estadoPasaje   VARCHAR(30),
  PRIMARY KEY (idBillete),
  CONSTRAINT fk_billete_pnr       FOREIGN KEY (localizadorPNR) REFERENCES PNR(localizador),
  CONSTRAINT fk_billete_pasajero  FOREIGN KEY (idPasajero)     REFERENCES Pasajero(idPasajero),
  CONSTRAINT fk_billete_vuelo  FOREIGN KEY (idVuelo)     REFERENCES Vuelo(idVuelo)
);

CREATE TABLE Equipaje (
  idEquipaje   INT         NOT NULL AUTO_INCREMENT,
  idBillete    INT         NOT NULL,
  descripcion  VARCHAR(30),
  numeroBultos INT         NOT NULL DEFAULT 0,
  PRIMARY KEY (idEquipaje),
  CONSTRAINT fk_equipaje_billete FOREIGN KEY (idBillete) REFERENCES Billete(idBillete),
  CONSTRAINT ck_equipaje_bultos CHECK (numeroBultos >= 0)
);