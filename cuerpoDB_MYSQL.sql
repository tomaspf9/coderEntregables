DROP DATABASE IF EXISTS streamingDB;
CREATE DATABASE IF NOT EXISTS streamingDB;
USE streamingDB;

-- CREACION DE TABLAS --


CREATE TABLE IF NOT EXISTS albumes(
id_album INT NOT NULL AUTO_INCREMENT,
titulo_album VARCHAR(60) NOT NULL,
fecha_publicacion DATE,
PRIMARY KEY (id_album)
);
CREATE TABLE artistas(
id_artista INT NOT NULL AUTO_INCREMENT,
nombre_artista VARCHAR(60) NOT NULL,
business_mail VARCHAR(60),
seguidores_actuales INT DEFAULT 0,
PRIMARY KEY (id_artista)
);
CREATE TABLE IF NOT EXISTS canciones(
id_cancion INT NOT NULL AUTO_INCREMENT,
track INT NOT NULL,
titulo_cancion VARCHAR(60) NOT NULL,
duracion REAL NOT NULL,
titulo_album VARCHAR(60) NOT NULL,
PRIMARY KEY(id_cancion)
);
CREATE TABLE IF NOT EXISTS planes(
id_plan INT NOT NULL AUTO_INCREMENT,
tipo_suscripcion VARCHAR(60) NOT NULL,
precio DECIMAL NOT NULL,
PRIMARY KEY (id_plan)
);


CREATE TABLE IF NOT EXISTS usuarios(
id INT NOT NULL AUTO_INCREMENT,
username VARCHAR(60) NOT NULL,
mail VARCHAR(60) NOT NULL,
nombre VARCHAR(60) NOT NULL,
PRIMARY KEY(id)
);

CREATE TABLE seguidores(
id_seguidor INT NOT NULL AUTO_INCREMENT,
artistas_favoritos VARCHAR(200) ,
usuario VARCHAR(60) NOT NULL,
PRIMARY KEY(id_seguidor)
);

CREATE TABLE IF NOT EXISTS suscripciones(
id_plan INT NOT NULL,
id_artista INT NOT NULL AUTO_INCREMENT,
alta_suscripcion TIMESTAMP NOT NULL,
baja_suscripcion TIMESTAMP ,
FOREIGN KEY(id_plan) REFERENCES planes(id_plan),
FOREIGN KEY(id_artista) REFERENCES artistas(id_artista)
);

CREATE TABLE IF NOT EXISTS new_suscripciones(
id_plan INT PRIMARY KEY,
id_artista VARCHAR(25),
alta_suscripcion TIMESTAMP,
baja_suscripcion TIMESTAMP)
;

-- Alter Table -- 

ALTER TABLE planes
ADD COLUMN id_artista INT,
ADD CONSTRAINT fk_id_artista_planes
FOREIGN KEY(id_artista) REFERENCES artistas(id_artista)
ON DELETE CASCADE
ON UPDATE CASCADE;

-- Creacion de Procedures -- 

-- Dropea todo record del artista -- 
DROP PROCEDURE IF EXISTS delete_artista;
DELIMITER $$
CREATE PROCEDURE delete_artist
(IN ingresar_nombre VARCHAR(100))
BEGIN
	DELETE FROM artistas WHERE nombre_artista = ingresar_nombre;
END$$
DELIMITER ;

-- Dropea datos tales como canciones --
DROP PROCEDURE IF EXISTS delete_canciones;
DELIMITER $$
CREATE PROCEDURE delete_canciones
(IN album_ingresado VARCHAR(100), cancion_ingresada VARCHAR(100))
BEGIN
	DELETE FROM canciones WHERE titulo_album = album_ingresado AND titulo_cancion = cancion_ingresada;
END$$
DELIMITER ;

-- Inserts de data para la tabla canciones --
DELIMITER $$

CREATE PROCEDURE sp_insert (IN sp_id_cancion INT,
							IN sp_track INT,
                            IN sp_titulo_cancion VARCHAR(20),
                            IN sp_duracion REAL,
                            IN sp_titulo_album VARCHAR(20))
                            
BEGIN
INSERT INTO canciones(id_cancion, track, titulo_cancion, duracion, titulo_album) #-- INSERT DE DATOS EN LAS COLUMNAS YA TRABAJADAS
VALUES (sp_id_cancion, sp_track, sp_titulo_cancion, sp_duracion, sp_titulo_album); #-- LOS VALORES QUE SE DAN COMO PARAMETROS 
END $$

DELIMITER ;

-- Funcion que nos permite visualizar cuantos artistas hay registrados -- 
SELECT COUNT(id_artista) FROM artistas;
-- Funciones basicas que nos permiten saber cuanto dura cada album ingresado en la DB --
SELECT SUM(duracion) FROM canciones WHERE titulo_album LIKE '%Stadium Arcadium%';
SELECT SUM(duracion) FROM canciones WHERE titulo_album LIKE '%Meteora%';
SELECT SUM(duracion) FROM canciones WHERE titulo_album LIKE '%Blood Sugar%';
SELECT SUM(duracion) FROM canciones WHERE titulo_album LIKE '%The Resistance%';
SELECT SUM(duracion) FROM canciones WHERE titulo_album LIKE '%Darkside%';
SELECT SUM(duracion) FROM canciones WHERE titulo_album LIKE '%Is this%';
SELECT SUM(duracion) FROM canciones WHERE titulo_album LIKE '%Motomami%';

-- Funcion que nos permite distinguir que artista ha dejado de ser miembro --
SELECT * FROM suscripciones WHERE baja_suscripcion IS NOT NULL;

-- Con esta vista generada es posible diferenciar las canciones que duren 4 minutos 

CREATE OR REPLACE VIEW duracion_canciontitulo_canciones AS
SELECT duracion,id_cancion,track,titulo_cancion
FROM canciones
WHERE duracion LIKE('%4.%');

-- Con esta vista generada es posible encontrar los mails que son arrobados de la misma forma --
CREATE OR REPLACE VIEW contacto_view AS
SELECT business_mail,nombre_artista
FROM artistas
WHERE business_mail LIKE ('%@gmail%');

-- 
CREATE OR REPLACE VIEW numero_canciones AS
SELECT
n.titulo_cancion
FROM canciones n
JOIN artistas a ON n.id_cancion = a.id_artista;

-- Con esta vista podemos observar los álbumes publicados en por ejemplo los 2000
CREATE OR REPLACE VIEW albumes_fecha AS
SELECT fecha_publicacion,titulo_album
FROM albumes
WHERE fecha_publicacion LIKE '%2000%';


-- Con esta vista ordenamos a nuestros clientes de manera alfabética ascendente, con el objetivo de encontrar rapido sus datos
CREATE OR REPLACE VIEW nom_artistas_asc AS
SELECT nombre_artista,business_mail
FROM artistas
ORDER BY nombre_artista ASC;
-- Con esta vista generamos el orden de nuestros clientes sabiendo quienes son miembros hace mas tiempo
CREATE OR REPLACE VIEW mem_clientes_orden_asc AS
SELECT id_artista, alta_suscripcion
FROM suscripciones
ORDER BY alta_suscripcion ASC;
-- Con esta vista generamos el orden de nuestros clientes conociendo su id
CREATE OR REPLACE VIEW nom_artista_id_asc AS
SELECT id_artista,nombre_artista
FROM artistas
ORDER BY id_artista;
-- Creamos Trigger que nos permite interactuar con los inserts de nuevos usuarios que se van sumando -- 
DELIMITER $$
CREATE TRIGGER tr_ai_usuarios
AFTER INSERT ON usuarios
FOR EACH ROW
BEGIN
	UPDATE artistas SET seguidores_actuales = seguidores_actuales +1 WHERE id_artista = id_artista;
END$$
DELIMITER ;

-- Trigger que nos sirve de base para mantener un log de suscripciones

DELIMITER $$
CREATE TRIGGER `tr_add_new_suscripciones`
AFTER INSERT ON `suscripciones`
FOR EACH ROW
INSERT INTO `new_suscripciones` (alta_suscripcion,baja_suscripcion) VALUES (NEW.alta_suscripcion, NEW.baja_suscripcion);
END$$
DELIMITER ;

--
--                Espacio para FUNCIONES             --



--   Funcion creada para traer un promedio de la cantidad de canciones por 
--   album Stadium Arcadium siendo este el album con más canciones en la DB

DELIMITER $$
CREATE FUNCTION get_AverageCanciones()
RETURNS INT
DETERMINISTIC
BEGIN
DECLARE VALUE INT;
SELECT AVG (track) INTO VALUE FROM canciones WHERE titulo_album = "Stadium Arcadium";
RETURN VALUE;
END$$
DELIMITER ;
-- 3 Funciones que nos permiten conocer cuantos miembros de tal suscripción hay para cada rango
DELIMITER $$
CREATE FUNCTION get_CountGoldM()
RETURNS INT
DETERMINISTIC
BEGIN
DECLARE VALUE INT;
SELECT COUNT(tipo_suscripcion) INTO VALUE FROM planes WHERE tipo_suscripcion ="Gold" ;
RETURN VALUE;
END$$
DELIMITER ;
DELIMITER $$
CREATE FUNCTION get_CountBronzeM()
RETURNS INT
DETERMINISTIC
BEGIN
DECLARE VALUE INT;
SELECT COUNT(tipo_suscripcion) INTO VALUE FROM planes WHERE tipo_suscripcion ="Bronze" ;
RETURN VALUE;
END$$
DELIMITER ;
DELIMITER $$
CREATE FUNCTION get_CountSilverM()
RETURNS INT
DETERMINISTIC
BEGIN
DECLARE VALUE INT;
SELECT COUNT(tipo_suscripcion) INTO VALUE FROM planes WHERE tipo_suscripcion ="Silver" ;
RETURN VALUE;
END$$
DELIMITER ;

