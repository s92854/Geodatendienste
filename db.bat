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