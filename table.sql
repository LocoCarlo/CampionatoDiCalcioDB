--PROGETTAZIONE FISICA

-- DOMINI
CREATE DOMAIN cf AS varchar(16) CHECK (value ~ '^[A-Z]{6}[0-9]{2}[A-Z][0-9]{2}[A-Z][0-9]{3}[A-Z]$');
CREATE DOMAIN tipo AS TEXT CHECK (VALUE IN ('giocata', 'nonGiocata'));
CREATE DOMAIN girone AS TEXT CHECK (VALUE IN ('andata', 'ritorno'));
CREATE DOMAIN indirizzo AS VARCHAR(30) CHECK (VALUE ~ '^Via\s.+');
CREATE DOMAIN SiNo AS TEXT CHECK (VALUE IN ('S', 'N'));
CREATE DOMAIN ruolo AS TEXT CHECK (VALUE IN ('Portiere', 'Difensore', 'Centrocampista', 'Attaccante'));


-- TABELLE BASE (senza dipendenze)
CREATE TABLE "citta" (
    "nome_citta" varchar(30) PRIMARY KEY
);

CREATE TABLE "stadio" (
    "indirizzo" indirizzo UNIQUE,
    "citta" varchar(30),
    "capacita" integer CHECK ("capacita" >= 0),
    "num_partite" integer CHECK ("num_partite" >= 0),
    PRIMARY KEY ("indirizzo", "citta"),
    FOREIGN KEY ("citta") REFERENCES "citta" ("nome_citta") ON DELETE CASCADE
);

CREATE TABLE "giornata" (
    "num_giornata" integer PRIMARY KEY CHECK ("num_giornata" BETWEEN 1 AND 38)
);

CREATE TABLE "squadra" (
    "nome" varchar(30) PRIMARY KEY,
    "punti" integer,
    "indirizzo" varchar(30),
    "citta" varchar(30),
    FOREIGN KEY ("indirizzo", "citta") REFERENCES "stadio" ("indirizzo", "citta"),
    FOREIGN KEY ("citta") REFERENCES "citta" ("nome_citta")
);

CREATE TABLE "persona" (
    "cf" cf PRIMARY KEY,
    "nome" varchar(30),
    "cognome" varchar(30)
);

-- TABELLE DIPENDENTI DA `persona`
CREATE TABLE "giocatore" (
    "cf" cf PRIMARY KEY,
    "data_nascita" date,
    "ruolo_principale" ruolo,
    "squadra" varchar(30) REFERENCES "squadra" ("nome"),
    FOREIGN KEY ("cf") REFERENCES "persona" ("cf") ON DELETE CASCADE
);

CREATE TABLE "allenatore" (
    "cf" cf PRIMARY KEY,
    "squadra" varchar(30) UNIQUE,
    FOREIGN KEY ("squadra") REFERENCES "squadra" ("nome"),
    FOREIGN KEY ("cf") REFERENCES "persona" ("cf") ON DELETE CASCADE
);

CREATE TABLE "arbitro" (
    "cf" cf PRIMARY KEY,
    "citta" varchar(30),
    "regione" varchar(30),
    FOREIGN KEY ("cf") REFERENCES "persona" ("cf") ON DELETE CASCADE
);

-- TABELLE DIPENDENTI DA ALTRE TABELLE

CREATE TABLE "giocata" (
    "id_giocata" integer PRIMARY KEY,
    "data" date NULL,
    "regolare" SiNo,
    "motivo" varchar(50) NULL,
    "stadio_proprieta" SiNo,
    "nome_stadio" varchar(30) NULL,
    "arbitro" cf REFERENCES "arbitro" ("cf")
);

CREATE TABLE "partita" (
    "data" date,
    "tipo" tipo, 
    "girone" girone,
    "squadra_casa" varchar(30),
    "squadra_trasferta" varchar(30),
    "indirizzo" varchar(30),
    "citta_stadio" varchar(30),
    "id_giocata" integer,
    "num_giornata" integer,
    PRIMARY KEY ("data", "squadra_casa"),
    FOREIGN KEY ("squadra_casa") REFERENCES "squadra" ("nome"),
    FOREIGN KEY ("squadra_trasferta") REFERENCES "squadra" ("nome"),
    FOREIGN KEY ("id_giocata") REFERENCES "giocata" ("id_giocata"),
    FOREIGN KEY ("num_giornata") REFERENCES "giornata" ("num_giornata"),
    FOREIGN KEY ("indirizzo") REFERENCES "stadio" ("indirizzo")
);

CREATE TABLE "esito" (
    "squadra" varchar(30),
    "giornata" integer,
    "punti" integer,
    PRIMARY KEY ("squadra", "giornata"),
    FOREIGN KEY ("squadra") REFERENCES "squadra" ("nome") ON DELETE CASCADE,
    FOREIGN KEY ("giornata") REFERENCES "giornata" ("num_giornata") ON DELETE SET NULL
);

CREATE TABLE "ha_giocato" (
    "id_giocata" integer,
    "cf" cf,
    "ruolo_partita" ruolo,
    PRIMARY KEY ("id_giocata", "cf"),
    FOREIGN KEY ("id_giocata") REFERENCES "giocata" ("id_giocata") ON DELETE CASCADE,
    FOREIGN KEY ("cf") REFERENCES "giocatore" ("cf") ON DELETE CASCADE
);


-- INDICI SECONDARI
CREATE INDEX idx_stadio_citta ON stadio(citta);
CREATE INDEX idx_partita_data ON partita(data);

-- ELIMINAZIONE TABELLE
/* 
DROP TABLE IF EXISTS "esito" CASCADE;
DROP TABLE IF EXISTS "ha_giocato" CASCADE;
DROP TABLE IF EXISTS "partita" CASCADE;
DROP TABLE IF EXISTS "giocata" CASCADE;
DROP TABLE IF EXISTS "squadra" CASCADE;
DROP TABLE IF EXISTS "arbitro" CASCADE;
DROP TABLE IF EXISTS "allenatore" CASCADE;
DROP TABLE IF EXISTS "giocatore" CASCADE;
DROP TABLE IF EXISTS "persona" CASCADE;
DROP TABLE IF EXISTS "giornata" CASCADE;
DROP TABLE IF EXISTS "stadio" CASCADE;
DROP TABLE IF EXISTS "citta" CASCADE;
*/
