-- ============================================================================
-- PROYECTO: TPC - TUS PISTAS DE CONFI
-- MOTOR: MySQL 8.0+
-- ============================================================================

DROP DATABASE IF EXISTS tpc_tus_pistas_de_confi;
CREATE DATABASE tpc_tus_pistas_de_confi
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE tpc_tus_pistas_de_confi;

-- ============================================================================
-- 1. DEFINICIÓN DE TABLAS (DDL)
-- ============================================================================

-- 1.1. Tabla CENTRO_DEPORTIVO
CREATE TABLE CENTRO_DEPORTIVO (
    id_centro INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    ciudad VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    descripcion TEXT,
    INDEX idx_centro_ciudad (ciudad)
) ENGINE=InnoDB;

-- 1.2. Tabla DEPORTE
CREATE TABLE DEPORTE (
    id_deporte INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 1.3. Tabla USUARIO
CREATE TABLE USUARIO (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    rol ENUM('Cliente', 'Admin') NOT NULL DEFAULT 'Cliente',
    INDEX idx_usuario_rol (rol)
) ENGINE=InnoDB;

-- 1.4. Tabla PISTA
CREATE TABLE PISTA (
    id_pista INT AUTO_INCREMENT PRIMARY KEY,
    id_centro INT NOT NULL,
    id_deporte INT NOT NULL,
    nombre_numero VARCHAR(100) NOT NULL,
    precio_por_hora DECIMAL(8, 2) NOT NULL,
    CONSTRAINT fk_pista_centro
        FOREIGN KEY (id_centro) REFERENCES CENTRO_DEPORTIVO(id_centro)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pista_deporte
        FOREIGN KEY (id_deporte) REFERENCES DEPORTE(id_deporte)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_pista_precio CHECK (precio_por_hora >= 0),
    INDEX idx_pista_centro_deporte (id_centro, id_deporte)
) ENGINE=InnoDB;

-- 1.5. Tabla RESERVA
CREATE TABLE RESERVA (
    id_reserva INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_pista INT NOT NULL,
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    estado ENUM('Confirmada', 'Cancelada', 'Pendiente') NOT NULL DEFAULT 'Pendiente',
    precio_total DECIMAL(8, 2) NOT NULL,
    CONSTRAINT fk_reserva_usuario
        FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reserva_pista
        FOREIGN KEY (id_pista) REFERENCES PISTA(id_pista)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_reserva_horas CHECK (hora_fin > hora_inicio),
    CONSTRAINT chk_reserva_precio CHECK (precio_total >= 0),
    INDEX idx_reserva_disponibilidad (id_pista, fecha, hora_inicio, hora_fin)
) ENGINE=InnoDB;

-- 1.6. Tabla PARTIDO_COMUNIDAD
CREATE TABLE PARTIDO_COMUNIDAD (
    id_partido INT AUTO_INCREMENT PRIMARY KEY,
    id_creador INT NOT NULL,
    id_reserva INT NOT NULL UNIQUE,
    jugadores_necesarios INT NOT NULL,
    estado ENUM('Abierto', 'Cerrado', 'Cancelado') NOT NULL DEFAULT 'Abierto',
    CONSTRAINT fk_partido_creador
        FOREIGN KEY (id_creador) REFERENCES USUARIO(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_partido_reserva
        FOREIGN KEY (id_reserva) REFERENCES RESERVA(id_reserva)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_partido_jugadores CHECK (jugadores_necesarios > 0)
) ENGINE=InnoDB;

-- 1.7. Tabla PARTICIPANTE_PARTIDO
CREATE TABLE PARTICIPANTE_PARTIDO (
    id_participante INT AUTO_INCREMENT PRIMARY KEY,
    id_partido INT NOT NULL,
    id_usuario INT NOT NULL,
    fecha_union DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_participante_partido
        FOREIGN KEY (id_partido) REFERENCES PARTIDO_COMUNIDAD(id_partido)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_participante_usuario
        FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_participante_partido_usuario UNIQUE (id_partido, id_usuario)
) ENGINE=InnoDB;

-- ============================================================================
-- 2. TRIGGER DE REGLA DE NEGOCIO (RN05: PREVENCIÓN DE SOLAPAMIENTOS)
-- ============================================================================

DELIMITER //

CREATE TRIGGER trg_evitar_solapamiento_reserva
BEFORE INSERT ON RESERVA
FOR EACH ROW
BEGIN
    DECLARE v_solapamientos INT DEFAULT 0;

    IF NEW.estado <> 'Cancelada' THEN
        SELECT COUNT(*) INTO v_solapamientos
        FROM RESERVA
        WHERE id_pista = NEW.id_pista
          AND fecha = NEW.fecha
          AND estado <> 'Cancelada'
          AND NEW.hora_inicio < hora_fin
          AND NEW.hora_fin > hora_inicio;

        IF v_solapamientos > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error RN05: La pista ya tiene una reserva activa en esa franja horaria.';
        END IF;
    END IF;
END //

DELIMITER ;

-- ============================================================================
-- 3. INSERCIÓN DE DATOS (DML)
-- ============================================================================

-- 3.1. CENTROS DEPORTIVOS REALES DE LA PROVINCIA DE SEVILLA
INSERT INTO CENTRO_DEPORTIVO (id_centro, nombre, direccion, ciudad, telefono, descripcion) VALUES
(1, 'Centro Deportivo Supera Entrepuentes', 'Av. de Ramón y Cajal, s/n, 41005', 'Sevilla', '954924900', 'Complejo deportivo en Nervión con pistas de pádel de cristal, piscinas climatizadas, sala fitness y actividades dirigidas.'),
(2, 'Instalaciones Deportivas La Cartuja (IMD)', 'Isla de la Cartuja, s/n, 41092', 'Sevilla', '954462299', 'Gran complejo deportivo público con campos de fútbol 11 y fútbol 7 de césped artificial, pistas de tenis, pádel y atletismo.'),
(3, 'Centro Deportivo Hytasa (IMD)', 'Av. de Hytasa, 10, 41006', 'Sevilla', '955475075', 'Instalación deportiva municipal en Cerro-Amate equipada con pabellón cubierto de baloncesto y fútbol sala y pistas exteriores.'),
(4, 'Centro Deportivo San Pablo (IMD)', 'Av. de Kansas City, s/n, 41007', 'Sevilla', '955475020', 'Palacio de los Deportes y complejo polideportivo con pistas de baloncesto, voleibol, fútbol sala, tenis y pádel.'),
(5, 'Centro Deportivo SADUS - Los Bermejales', 'Av. de Dinamarca, s/n, 41012', 'Sevilla', '954487700', 'Complejo deportivo universitario abierto al público con pistas de pádel, tenis, campo de fútbol de césped artificial y pabellón.'),
(6, 'Real Club Pineda de Sevilla', 'Av. de Jerez, s/n, 41012', 'Sevilla', '954611400', 'Club deportivo histórico de Sevilla que dispone de pistas de tenis de tierra batida, pistas de pádel y campos de fútbol.'),
(7, 'Club Bernier', 'Urb. Simón Verde, C. Vía Aurelia, s/n, 41927', 'Mairena del Aljarafe', '954180752', 'Club deportivo en el Aljarafe sevillano especializado en tenis y pádel con pistas de muro y cristal y canchas polideportivas.'),
(8, 'Complejo Deportivo Municipal Pepe Flores', 'Av. de España, s/n, 41704', 'Dos Hermanas', '955664320', 'Instalación deportiva municipal de Dos Hermanas con pistas de pádel, tenis, campos de fútbol 7 y canchas de baloncesto.'),
(9, 'Complejo Deportivo Distrito Sur', 'C. Ntra. Sra. del Águila, s/n, 41500', 'Alcalá de Guadaíra', '955680365', 'Polideportivo municipal en Alcalá de Guadaíra con pistas de pádel, tenis, fútbol sala y pistas exteriores de baloncesto.'),
(10, 'Complejo Deportivo Municipal Vistalegre', 'Paseo de Consolación, s/n, 41710', 'Utrera', '954860050', 'Centro deportivo municipal de Utrera con pabellón cubierto, pistas de pádel, tenis, campo de fútbol y pista de atletismo.'),
(11, 'Centro Deportivo Cavaleri', 'Av. de los Descubrimientos, s/n, 41927', 'Mairena del Aljarafe', '954183900', 'Instalación deportiva municipal en Mairena del Aljarafe con pistas de pádel, tenis, fútbol de césped artificial y pabellón.'),
(12, 'Polideportivo Municipal Francisco Sánchez Castañeda', 'C. Cultura, s/n, 41309', 'La Rinconada', '954790141', 'Complejo polideportivo municipal en La Rinconada dotado de pistas de pádel, tenis, fútbol 7, baloncesto y voleibol.');

-- 3.2. DEPORTES (Datos ficticios / catálogo)
INSERT INTO DEPORTE (id_deporte, nombre) VALUES
(1, 'Pádel'),
(2, 'Tenis'),
(3, 'Fútbol 7'),
(4, 'Fútbol Sala'),
(5, 'Baloncesto'),
(6, 'Voleibol');

-- 3.3. USUARIOS (Datos ficticios - contraseñas simuladas con hash BCrypt)
INSERT INTO USUARIO (id_usuario, nombre, email, password, telefono, rol) VALUES
(1, 'Javier García Rodríguez', 'javi.admin@tuspistasdeconfi.es', 'admin1234', '611200301', 'Admin'),
(2, 'Alexandru Cozaru', 'alex.admin@tuspistasdeconfi.es', 'admin1234', '611200302', 'Admin'),
(3, 'Carlos Mendoza Ruiz', 'carlos.mendoza@email.com', 'usuario1234', '622345110', 'Cliente'),
(4, 'Laura Jiménez Vega', 'laura.jimenez@email.com', 'usuario1234', '633987412', 'Cliente'),
(5, 'Manuel Ortega Solís', 'manu.ortega@email.com', 'usuario1234', '644112233', 'Cliente'),
(6, 'Sofía Navas Morales', 'sofia.navas@email.com', 'usuario1234', '655443322', 'Cliente'),
(7, 'Alejandro Romero Gil', 'ale.romero@email.com', 'usuario1234', '666778899', 'Cliente'),
(8, 'Elena Castillo Domínguez', 'elena.castillo@email.com', 'usuario1234', '677889900', 'Cliente'),
(9, 'David Herrera Lozano', 'david.herrera@email.com', 'usuario1234', '688990011', 'Cliente'),
(10, 'Paula Benítez Serrano', 'paula.benitez@email.com', 'usuario1234', '699102030', 'Cliente'),
(11, 'Pablo Vázquez Carmona', 'pablo.vazquez@email.com', 'usuario1234', '610456789', 'Cliente'),
(12, 'Marta Delgado Pérez', 'marta.delgado@email.com', 'usuario1234', '620987654', 'Cliente');

-- 3.4. PISTAS (Datos ficticios asociados a los centros reales)
INSERT INTO PISTA (id_pista, id_centro, id_deporte, nombre_numero, precio_por_hora) VALUES
-- Centro 1: Supera Entrepuentes
(1, 1, 1, 'Pista Pádel 01 - Cristal Panorámica', 16.00),
(2, 1, 1, 'Pista Pádel 02 - Cristal Central', 16.00),
-- Centro 2: La Cartuja (IMD)
(3, 2, 3, 'Campo Fútbol 7 - Norte', 48.00),
(4, 2, 2, 'Pista Tenis 01 - Rápida', 12.00),
-- Centro 3: CD Hytasa (IMD)
(5, 3, 5, 'Pabellón Central - Cancha Baloncesto A', 22.00),
(6, 3, 4, 'Pista Fútbol Sala Exterior 01', 28.00),
-- Centro 4: CD San Pablo (IMD)
(7, 4, 5, 'Pista Baloncesto Cubierta 02', 25.00),
(8, 4, 6, 'Pista Voleibol Cubierta 01', 20.00),
-- Centro 5: SADUS Bermejales
(9, 5, 1, 'Pista Pádel 03 - Universitaria', 14.00),
(10, 5, 3, 'Campo Fútbol 7 - Césped Artificial', 44.00),
-- Centro 6: Real Club Pineda
(11, 6, 2, 'Pista Tenis 04 - Tierra Batida', 18.00),
(12, 6, 1, 'Pista Pádel Club 01', 20.00),
-- Centro 7: Club Bernier (Mairena del Aljarafe)
(13, 7, 1, 'Pista Pádel Cristal 02', 18.00),
(14, 7, 2, 'Pista Tenis 02 - Aljarafe', 15.00),
-- Centro 8: CDM Pepe Flores (Dos Hermanas)
(15, 8, 1, 'Pista Pádel Municipal 01', 12.00),
(16, 8, 3, 'Campo Fútbol 7 - Dos Hermanas', 36.00),
-- Centro 9: CD Distrito Sur (Alcalá de Guadaíra)
(17, 9, 4, 'Pista Fútbol Sala 01', 24.00),
(18, 9, 1, 'Pista Pádel 02', 12.00),
-- Centro 10: CDM Vistalegre (Utrera)
(19, 10, 2, 'Pista Tenis Vistalegre 01', 10.00),
(20, 10, 5, 'Cancha Baloncesto Exterior 01', 16.00),
-- Centro 11: CD Cavaleri (Mairena del Aljarafe)
(21, 11, 1, 'Pista Pádel Cavaleri 01', 14.00),
(22, 11, 3, 'Campo Fútbol 7 Cavaleri', 40.00),
-- Centro 12: Polideportivo Francisco Sánchez Castañeda (La Rinconada)
(23, 12, 6, 'Pista Voleibol Polideportivo', 15.00),
(24, 12, 1, 'Pista Pádel Rinconada 01', 11.00);

-- 3.5. RESERVAS (Datos ficticios sin solapamientos y con precio_total exacto)
INSERT INTO RESERVA (id_reserva, id_usuario, id_pista, fecha, hora_inicio, hora_fin, estado, precio_total) VALUES
(1, 3, 1, '2026-11-16', '18:00:00', '19:30:00', 'Confirmada', 24.00),
(2, 4, 2, '2026-11-16', '19:30:00', '21:00:00', 'Confirmada', 24.00),
(3, 5, 3, '2026-11-17', '20:00:00', '21:00:00', 'Confirmada', 48.00),
(4, 6, 4, '2026-11-17', '10:00:00', '11:30:00', 'Confirmada', 18.00),
(5, 7, 5, '2026-11-18', '17:00:00', '18:30:00', 'Pendiente', 33.00),
(6, 8, 6, '2026-11-18', '19:00:00', '20:00:00', 'Confirmada', 28.00),
(7, 9, 7, '2026-11-19', '18:00:00', '19:00:00', 'Cancelada', 25.00),
(8, 10, 8, '2026-11-19', '11:00:00', '12:30:00', 'Confirmada', 30.00),
(9, 11, 9, '2026-11-20', '16:30:00', '18:00:00', 'Confirmada', 21.00),
(10, 12, 10, '2026-11-20', '21:00:00', '22:00:00', 'Confirmada', 44.00),
(11, 3, 11, '2026-11-21', '09:30:00', '11:00:00', 'Confirmada', 27.00),
(12, 5, 13, '2026-11-21', '18:30:00', '20:00:00', 'Pendiente', 27.00),
(13, 7, 15, '2026-11-22', '17:30:00', '19:00:00', 'Confirmada', 18.00),
(14, 9, 17, '2026-11-22', '20:00:00', '21:00:00', 'Confirmada', 24.00);

-- 3.6. PARTIDOS DE COMUNIDAD (Datos ficticios vinculados a reservas)
INSERT INTO PARTIDO_COMUNIDAD (id_partido, id_creador, id_reserva, jugadores_necesarios, estado) VALUES
(1, 3, 1, 3, 'Cerrado'),   -- Pádel dobles: creador + 3 jugadores unidos = 4 completos
(2, 4, 2, 3, 'Abierto'),   -- Pádel dobles: creador + 2 jugadores unidos (falta 1 plaza)
(3, 6, 4, 1, 'Cerrado'),   -- Tenis individual: creador + 1 jugador unido = 2 completos
(4, 8, 6, 9, 'Abierto'),   -- Fútbol Sala 5v5: creador + 4 jugadores unidos (faltan 5 plazas)
(5, 10, 8, 11, 'Abierto'), -- Voleibol 6v6: creador + 3 jugadores unidos (faltan 8 plazas)
(6, 12, 10, 13, 'Cancelado'); -- Fútbol 7: partido cancelado por el organizador

-- 3.7. PARTICIPANTES EN PARTIDOS (Datos ficticios)
INSERT INTO PARTICIPANTE_PARTIDO (id_participante, id_partido, id_usuario, fecha_union) VALUES
-- Partido 1 (Cerrado: 3/3 plazas cubiertas)
(1, 1, 4, '2026-11-13 10:15:00'),
(2, 1, 5, '2026-11-13 11:20:00'),
(3, 1, 6, '2026-11-13 12:05:00'),
-- Partido 2 (Abierto: 2/3 plazas cubiertas)
(4, 2, 7, '2026-11-13 13:10:00'),
(5, 2, 8, '2026-11-13 14:45:00'),
-- Partido 3 (Cerrado: 1/1 plaza cubierta)
(6, 3, 9, '2026-11-13 15:00:00'),
-- Partido 4 (Abierto: 4/9 plazas cubiertas)
(7, 4, 3, '2026-11-13 16:00:00'),
(8, 4, 5, '2026-11-13 16:15:00'),
(9, 4, 7, '2026-11-13 16:40:00'),
(10, 4, 11, '2026-11-13 17:10:00'),
-- Partido 5 (Abierto: 3/11 plazas cubiertas)
(11, 5, 4, '2026-11-13 18:00:00'),
(12, 5, 6, '2026-11-13 18:25:00'),
(13, 5, 12, '2026-11-13 19:00:00'),
-- Partido 6 (Cancelado)
(14, 6, 9, '2026-11-13 09:30:00'),
(15, 6, 11, '2026-11-13 09:45:00');