@echo off

set ppath=C:\Program Files\PostgreSQL\17\bin

:: Setze Umgebungsvariablen für die Verbindung zur PostgreSQL-Datenbank
SET PGUSER=username
set PGPASSFILE="%ppath%\data\pw.pgpass"
SET PGPASSWORD=super
SET PGDATABASE=gdd
SET PGHOST=localhost  :: Ersetze "localhost" durch den tatsächlichen Hostnamen falls nötig

:: Definiere den Pfad zu deiner Shapefile-Datei und dem Zielnamen
SET SHAPEFILE_PATH="E:\CloudStation\Studium\Semester 5\Geodatendienste\Vector\countries.shp"

:: 1. Lade die Shapefile-Datei mit ogr2ogr in die Datenbank
ogr2ogr -f "PostgreSQL" PG:"dbname=%PGDATABASE% user=%PGUSER% password=%PGPASSWORD% host=%PGHOST%" ^
    %SHAPEFILE_PATH% ^
    -nln laender ^
    -nlt MULTIPOLYGON ^
    -a_srs EPSG:4326

echo Shapefile-Daten erfolgreich in die Datenbank geladen!
pause