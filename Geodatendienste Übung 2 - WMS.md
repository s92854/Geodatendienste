# Geodatendienste Übung 2 - WMS

## Vollständiger Code

Der Pfad zu persönlichen Datenspeicherorten wurde hier durch %sp% ersetzt und ist maschinenabhängig zu ändern. Über eine weitere Variable kann dieser Pfad auch in den Batchdateien gesetzt bzw. geändert werden.

### 1. a)

* erstellt Datenbanken "gdd" und "rdmg" im Loop
* verwendet .pgpass Datei, um Passwortabfrage zu umgehen




````bash
@echo off
set ppath="C:\Program Files\PostgreSQL\17\bin"
REM Setze die Fächer als kommaseparierte Liste
set Faecher=gdd,rdmg

REM Lege den Benutzer und die Passwortdatei fest (falls notwendig)
set USER=postgres
set PGPASSFILE="%ppath%\data\pw.pgpass"

REM Durchlaufe jedes Fach im Loop
for %%F in (%FAEcher%) do (
    echo Erstelle Datenbank für Modul: %%F

    REM Befehl zum Erstellen der Datenbank
    %ppath%\psql -U %USER% -h localhost -c "CREATE DATABASE %%F WITH OWNER %USER%;"

    REM Berechtigung für den Superuser setzen (optional)
    %ppath%\psql -U %USER% -h localhost -c "GRANT ALL PRIVILEGES ON DATABASE %%F TO %USER%;"
)

echo Alle Datenbanken wurden erstellt.
pause
````



### 1. b)

````bash
@echo off
setlocal

set ppath=C:\Program Files\PostgreSQL\17\bin

:: Fächer als Variable setzen
set modules=gdd,rdmg

:: PostgreSQL Superuser und Host-Konfiguration
set PGUSER=postgres
set PGHOST=localhost

:: Passwort zur Umgebungsvariable hinzufügen (optional, falls pgpass nicht verwendet wird)
set PGPASSFILE="%ppath%\data\pw.pgpass"

:: Loop für alle Module
for %%M in (%modules%) do (

    echo Lösche Datenbank %%M falls sie existiert...
    "%ppath%\psql" -U %PGUSER% -h %PGHOST% -c "DROP DATABASE IF EXISTS %%M;" 

    echo Erstelle neue Datenbank %%M...
    "%ppath%\psql" -U %PGUSER% -h %PGHOST% -c "CREATE DATABASE %%M WITH ENCODING='UTF8' TEMPLATE=postgis_35_sample;" 

    :: Falls es Probleme mit LATIN1 gibt, kannst du hier UTF8 nutzen:
    :: "%ppath%\psql" -U %PGUSER% -h %PGHOST% -c "CREATE DATABASE %%M WITH ENCODING='UTF8' TEMPLATE=postgis_35_sample;"

    echo Lösche Rolle %%M falls sie existiert...
    "%ppath%\psql" -U %PGUSER% -h %PGHOST% -c "DROP ROLE IF EXISTS %%M;"

    echo Erstelle Rolle %%M mit Passwort und setze als SUPERUSER...
    "%ppath%\psql" -U %PGUSER% -h %PGHOST% -c "CREATE ROLE %%M WITH LOGIN PASSWORD '%%M' SUPERUSER;"

    echo Bewillige alle Rechte der Rolle %%M für die Datenbank %%M...
    "%ppath%\psql" -U %PGUSER% -h %PGHOST% -c "GRANT ALL PRIVILEGES ON DATABASE %%M TO %%M;"

)

:: Pause zum Anzeigen von Fehlermeldungen
pause
````



### 1. c)

````bash
@echo off
set ppath=C:\Program Files\PostgreSQL\17\bin
set PGPASSFILE="%ppath%\data\pw.pgpass"

:: 1. Login in psql (ersetze "username" und "password" durch deine Zugangsdaten)
"%ppath%\psql" -U postgres -c "\l"

:: 2. Zeige alle Datenbanken an
"%ppath%\psql" -U postgres -c "\l"

:: 3. Lösche die Datenbank "rdmg" (mit Bestätigung)
"%ppath%\psql" -U postgres -c "DROP DATABASE IF EXISTS rdmg;"

:: 4. Verbinde dich mit der Datenbank "gdd"
"%ppath%\psql" -U postgres -d gdd -c "\dt"

:: 5. Zeige alle Tabellen in der Datenbank "gdd" an
"%ppath%\psql" -U postgres -d gdd -c "\dt"

echo Aufgaben erfolgreich abgeschlossen!
pause
````



### 1. d)

````bash
ogr2ogr -f "PGDUMP" output.sql "%sp%\countries.shp" -nln laender -nlt MULTIPOLYGON -a_srs EPSG:4326
psql -U postgres -d gdd -f output.sql
````



### 1. e)

#### Version 1

````sql
CREATE TABLE wgi (
    landid INT,
    jahr INT,
    wgi FLOAT,
    PRIMARY KEY (landid, jahr)
);
````

#### Version 2

````sql
CREATE TABLE wgi (
    landid INT PRIMARY KEY,
    jahr INT,
    wgi FLOAT
);

ALTER TABLE wgi
ADD PRIMARY KEY (landid, jahr);
````



### 1. f)

````sql
CREATE TABLE exports_percent_gdp (
 fid INTEGER,
 iso3 CHAR(3),
 jahr INTEGER,
 value NUMERIC,
 unit_id INTEGER,
 PRIMARY KEY (fid, iso3, jahr, unit_id)
);
````



### 2.

#### In CMD mit Datenbank verbinden

````bash
"%ppath%\psql -U postgres -d gdd"
````



#### Daten in jeweilige Tabelle einfügen

````sql
\copy wgi FROM
'%sp%\wgi.csv' DELIMITER ';' CSV HEADER;
````

````sql
\copy exports_percent_gdp FROM
'%sp%\exports_percent_gdp.csv' DELIMITER ';' CSV HEADER;
````



#### Test auf Vorhandensein der Daten (in PGAdmin)

````sql
SELECT * FROM wgi
SELECT * FROM laender
SELECT * FROM exports_percent_gdp
````



#### JOIN als View erstellen

````sql
CREATE VIEW exports_wgi_join AS
SELECT
 -- Spalten aus Tabelle "exports_percent_gdp"
 exports_percent_gdp.fid,
 exports_percent_gdp.iso3,
 exports_percent_gdp.jahr,
 exports_percent_gdp.value AS value_float, -- Originalwert, Größe der Kreise
 ROUND(exports_percent_gdp.value)::TEXT || '%' AS value_label, -- Gerundeter Wert (String) für die Beschriftung in
Prozent

 -- Spalten aus Tabelle "laender"
 laender.id::INTEGER AS country_id, -- INTEGER konvertierung
 laender.country,
 laender.land,
 laender.wkb_geometry,

 -- Spalte aus Tabelle "wgi"
 wgi.wgi
FROM
 exports_percent_gdp
-- Join mit Tabelle "laender" über die Spalte 'iso3'
LEFT JOIN
 laender
ON
 exports_percent_gdp.iso3 = laender.iso3
-- Join mit Tabelle "wgi" über die Spalten 'landid' und 'jahr'
LEFT JOIN
 wgi
ON
 laender.id = wgi.landid
 AND exports_percent_gdp.jahr = wgi.jahr
WHERE
 -- nur Zeilen mit Geometrie
 laender.wkb_geometry IS NOT NULL

 -- nur Daten aus dem aktuellsten Jahr in Tabelle "wgi"
 AND exports_percent_gdp.jahr = (
 SELECT MAX(jahr)
 FROM wgi
 );
````



#### GeoServer-Umgebung installieren

1. [Java JDK Version 17 installieren](https://adoptium.net/de/temurin/releases/?os=windows&arch=x64&package=jdk&version=17)
2. [GeoServer einrichten](https://sourceforge.net/projects/geoserver/)



#### SQL View erstellen

````sql
SELECT
 exports_percent_gdp.fid,
 exports_percent_gdp.iso3,
 exports_percent_gdp.jahr,
 exports_percent_gdp.value AS value_float,
 ROUND(exports_percent_gdp.value)::TEXT || '%' AS value_label,
 laender.id::INTEGER AS country_id,
 laender.country,
 laender.land,
 laender.wkb_geometry,
 wgi.wgi
FROM
 exports_percent_gdp
LEFT JOIN
 laender
ON
 exports_percent_gdp.iso3 = laender.iso3
LEFT JOIN
 wgi
ON
 laender.id = wgi.landid
 AND exports_percent_gdp.jahr = wgi.jahr
WHERE
 laender.wkb_geometry IS NOT NULL
 AND exports_percent_gdp.jahr = %year%
````

