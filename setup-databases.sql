-- Crea las 10 bases de datos MySQL + usuarios que cada microservicio de
-- LIbrOnline-Backend espera (ver application.properties de cada módulo).
-- Ejecutar UNA VEZ, como root:
--   mysql -u root -p < setup-databases.sql

CREATE DATABASE IF NOT EXISTS usuarios;
CREATE DATABASE IF NOT EXISTS mensajeria;
CREATE DATABASE IF NOT EXISTS gestion_reuniones;
CREATE DATABASE IF NOT EXISTS gestion_cursos;
CREATE DATABASE IF NOT EXISTS creacion_eventos;
CREATE DATABASE IF NOT EXISTS asistencia;
CREATE DATABASE IF NOT EXISTS anotaciones;
CREATE DATABASE IF NOT EXISTS direccion;
CREATE DATABASE IF NOT EXISTS notas;
CREATE DATABASE IF NOT EXISTS matriculas;

-- "microservicio" es compartido por Usuarios, Gestion_Reuniones y Gestion_Cursos
CREATE USER IF NOT EXISTS 'microservicio'@'localhost' IDENTIFIED BY 'system';
GRANT ALL PRIVILEGES ON usuarios.* TO 'microservicio'@'localhost';
GRANT ALL PRIVILEGES ON gestion_reuniones.* TO 'microservicio'@'localhost';
GRANT ALL PRIVILEGES ON gestion_cursos.* TO 'microservicio'@'localhost';

CREATE USER IF NOT EXISTS 'mensajeria'@'localhost' IDENTIFIED BY 'system';
GRANT ALL PRIVILEGES ON mensajeria.* TO 'mensajeria'@'localhost';

CREATE USER IF NOT EXISTS 'creacion_eventos'@'localhost' IDENTIFIED BY 'system';
GRANT ALL PRIVILEGES ON creacion_eventos.* TO 'creacion_eventos'@'localhost';

CREATE USER IF NOT EXISTS 'asistencia'@'localhost' IDENTIFIED BY 'system';
GRANT ALL PRIVILEGES ON asistencia.* TO 'asistencia'@'localhost';

CREATE USER IF NOT EXISTS 'anotaciones'@'localhost' IDENTIFIED BY 'system';
GRANT ALL PRIVILEGES ON anotaciones.* TO 'anotaciones'@'localhost';

CREATE USER IF NOT EXISTS 'direcciones'@'localhost' IDENTIFIED BY 'system';
GRANT ALL PRIVILEGES ON direccion.* TO 'direcciones'@'localhost';

CREATE USER IF NOT EXISTS 'notas'@'localhost' IDENTIFIED BY 'system';
GRANT ALL PRIVILEGES ON notas.* TO 'notas'@'localhost';

CREATE USER IF NOT EXISTS 'matriculas'@'localhost' IDENTIFIED BY 'system';
GRANT ALL PRIVILEGES ON matriculas.* TO 'matriculas'@'localhost';

FLUSH PRIVILEGES;
