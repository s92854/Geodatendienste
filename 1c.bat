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