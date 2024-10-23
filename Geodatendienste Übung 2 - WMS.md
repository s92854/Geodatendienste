# Geodatendienste Übung 2 - WMS

## Vollständiger Code

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