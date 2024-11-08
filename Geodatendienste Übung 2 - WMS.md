# Geodatendienste Übung 2: WMS
> 09.11.2024
>
> Christoph Lazik (956219),
> Nico Haupt (956450),
> Tara Richter (934172)

Der Pfad zu persönlichen Datenspeicherorten wurde hier durch %sp% ersetzt und ist maschinenabhängig zu ändern.

## 1. a)

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



## 1. b)

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



## 1. c)

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



## 1. d)

````bash
ogr2ogr -f "PGDUMP" output.sql "%sp%\countries.shp" -nln laender -nlt MULTIPOLYGON -a_srs EPSG:4326
psql -U postgres -d gdd -f output.sql
````



## 1. e)

### Version 1 - Setzen des PK beim Erstellen der Tabelle

````sql
CREATE TABLE wgi (
    landid INT,
    jahr INT,
    wgi FLOAT,
    PRIMARY KEY (landid, jahr)
);
````

### Version 2 - Setzen des PK nach dem Erstellen der Tabelle

````sql
CREATE TABLE wgi (
    landid INT,
    jahr INT,
    wgi FLOAT
);

ALTER TABLE wgi
ADD PRIMARY KEY (landid, jahr);
````

#### Alternative
Neben ````ALTER TABLE wgi ADD PRIMARY KEY(landid,jahr)```` ist auch diese Variante noch möglich:

````sql
ALTER TABLE wgi
ADD CONSTRAINT pk_wgi PRIMARY KEY (landid,jahr);
````



## 1. f)

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



## 2.

### In CMD mit Datenbank verbinden

````bash
"%ppath%\psql -U postgres -d gdd"
````



### Daten in jeweilige Tabelle einfügen

````sql
\copy wgi FROM '%sp%\wgi.csv' DELIMITER ';' CSV HEADER;
````

````sql
\copy exports_percent_gdp FROM '%sp%\exports_percent_gdp.csv' DELIMITER ';' CSV HEADER;
````



### Test auf Vorhandensein der Daten (in PGAdmin)

````sql
SELECT * FROM wgi
SELECT * FROM laender
SELECT * FROM exports_percent_gdp
````



### JOIN als View erstellen

````sql
CREATE VIEW exports_wgi_join AS
SELECT
 -- Spalten aus Tabelle "exports_percent_gdp"
 exports_percent_gdp.fid,
 exports_percent_gdp.iso3,
 exports_percent_gdp.jahr,
 exports_percent_gdp.value AS value_float, -- Originalwert, Größe der Kreise
 ROUND(exports_percent_gdp.value)::TEXT || '%' AS value_label, -- Gerundeter Wert (String) für die Beschriftung in Prozent

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



### GeoServer-Umgebung installieren

1. [Java JDK Version 17 installieren](https://adoptium.net/de/temurin/releases/?os=windows&arch=x64&package=jdk&version=17)
2. [GeoServer einrichten](https://sourceforge.net/projects/geoserver/)



### SQL View erstellen

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
<img title="Open Layers Vorschau auf dem Geoservers" src="https://github.com/user-attachments/assets/558e4f7b-712e-44d5-bddf-ddc6f235a1f1">



## 3. Format der GetCapabilities Abfrage, sowie GetFeatureInfo-URL erstellen und Koordinaten für die Boundingbox festlegen
Die Abfrage ist als **XML-Dokument** formatiert. Dies erkennt man an den xml-typischen Tags, wie z.B. ````<Name>gdd:exports_percent_gdp</Name>```` oder ````<Title>exports_percent_gdp</Title>````. Außerdem wird ein XML-Dokument, wie hier, immer mit ````<?xml version="1.0" encoding="UTF-8"?>```` begonnen.

&nbsp;

````xml
SERVICE=WMS&
VERSION=1.1.1&
REQUEST=GetFeatureInfo&
FORMAT=image/png&
TRANSPARENT=true&
QUERY_LAYERS=gdd:exports_percent_gdp&
STYLES=&
LAYERS=gdd:exports_percent_gdp&
exceptions=application/vnd.ogc.se_inimage&
INFO_FORMAT=text/html&
FEATURE_COUNT=50&
X=50&
Y=50&
SRS=EPSG:3857&
WIDTH=101&
HEIGHT=101&
BBOX=652888.8293406211,5987030.898794127,1673556.9874144716,7372844.607748471
````



## 4. Geometry erstellen
> in PGAdmin folgenden Code eingeben, um eine Boundingbox um Deutschland zu erstellen

````sql
SELECT ST_AsText(
  ST_Envelope(
    ST_Transform(wkb_geometry, 3857)
  )
) AS bbox
FROM laender
WHERE LAND = 'Deutschland';
````



## 5. Koordinaten der Boundingbox

Als Ergebnis kommt folgendes Polygon raus: *POLYGON((652888.8293406211 5987030.898794127,652888.8293406211 7372844.607748471,1673556.9874144716 7372844.607748471,1673556.9874144716 5987030.898794127,652888.8293406211 5987030.898794127))*




## 6. URL für exports_percent_gdp
````html
http://localhost:8080/geoserver/gdd/wms
````



## 7. Einladen des WMS in QGIS
1. WMS-URL erstellen und in QGIS als Quelle einladen
2. WMS-Layer der Karte hinzufügen + Namen eingeben
3. Auf "Verbinden" klicken
4. Ändern der Projektion auf das "Angegebene Koordinatenreferenzsystem" (EPSG:3857)

<img title="WMS Dienst in QGIS geladen" src="https://github.com/user-attachments/assets/cdc5f781-3724-4935-8b51-75a7e21872b9">



## 8. GetCapabilities Abfrage

````html
http://localhost:8080/geoserver/wms?service=WMS&request=GetCapabilities
````



## 9. Abfrage und Deckungskraft
````queryable=”1“```` &rarr; abfragbar

````Opaque=“0“```` &rarr; undurchsichtig



## 10. Styling / Visualisierung
````xml
<?xml version="1.0" encoding="UTF-8"?>
<sld:UserStyle xmlns="http://www.opengis.net/sld" 
               xmlns:sld="http://www.opengis.net/sld" 
               xmlns:ogc="http://www.opengis.net/ogc" 
               xmlns:gml="http://www.opengis.net/gml">
  <sld:Title/>
  <FeatureTypeStyle>
    <Rule>
      <Name>high</Name>
      <Title>WGI &lt; -0.5</Title>
      <ogc:Filter>
        <ogc:PropertyIsLessThan>
          <ogc:PropertyName>wgi</ogc:PropertyName>
          <ogc:Literal>-0.5</ogc:Literal>
        </ogc:PropertyIsLessThan>
      </ogc:Filter>
      <PolygonSymbolizer>
        <Fill>
          <CssParameter name="fill">#fc8d59</CssParameter>
        </Fill>
      </PolygonSymbolizer>
    </Rule>

    <Rule>
      <Name>medium</Name>
      <Title>WGI &gt; -0.5 und &lt; 0.5</Title>
      <ogc:Filter>
        <ogc:And>
          <ogc:PropertyIsGreaterThanOrEqualTo>
            <ogc:PropertyName>wgi</ogc:PropertyName>
            <ogc:Literal>-0.5</ogc:Literal>
          </ogc:PropertyIsGreaterThanOrEqualTo>
          <ogc:PropertyIsLessThan>
            <ogc:PropertyName>wgi</ogc:PropertyName>
            <ogc:Literal>0.5</ogc:Literal>
          </ogc:PropertyIsLessThan>
        </ogc:And>
      </ogc:Filter>
      <PolygonSymbolizer>
        <Fill>
          <CssParameter name="fill">#ffffbf</CssParameter>
        </Fill>
      </PolygonSymbolizer>
    </Rule>

    <Rule>
      <Name>low</Name>
      <Title>WGI &gt; 0.5</Title>
      <ogc:Filter>
        <ogc:PropertyIsGreaterThan>
          <ogc:PropertyName>wgi</ogc:PropertyName>
          <ogc:Literal>0.5</ogc:Literal>
        </ogc:PropertyIsGreaterThan>
      </ogc:Filter>
      <PolygonSymbolizer>
        <Fill>
          <CssParameter name="fill">#91cf60</CssParameter>
        </Fill>
      </PolygonSymbolizer>
    </Rule>

    <Rule>
      <Title>Boundary</Title>
      <LineSymbolizer>
        <Stroke>
          <CssParameter name="stroke">#e2e2e2</CssParameter>
        </Stroke>
      </LineSymbolizer>
      <TextSymbolizer>
        <sld:Geometry>
          <ogc:Function name="centroid">
            <ogc:PropertyName>wkb_geometry</ogc:PropertyName>
          </ogc:Function>
        </sld:Geometry>
        <Label>
          <ogc:PropertyName>land</ogc:PropertyName>
        </Label>
        <Font>
          <CssParameter name="font-family">Times New Roman</CssParameter>
          <CssParameter name="font-style">Normal</CssParameter>
          <CssParameter name="font-size">14</CssParameter>
        </Font>
        <LabelPlacement>
          <PointPlacement>
            <AnchorPoint>
              <AnchorPointX>-0.5</AnchorPointX>
              <AnchorPointY>0.5</AnchorPointY>
            </AnchorPoint>
          </PointPlacement>
        </LabelPlacement>
      </TextSymbolizer>
    </Rule>
    <Rule>
      <Name>export_low</Name>
      <Title>Exporte &lt; 20 % vom BSP</Title>
      <ogc:Filter>
        <ogc:PropertyIsLessThan>
          <ogc:PropertyName>value_label</ogc:PropertyName>
          <ogc:Literal>20</ogc:Literal>
        </ogc:PropertyIsLessThan>
      </ogc:Filter>
      <TextSymbolizer>
        <sld:Geometry>
          <ogc:Function name="centroid">
            <ogc:PropertyName>wkb_geometry</ogc:PropertyName>
          </ogc:Function>
        </sld:Geometry>
        <Label>
          <ogc:PropertyName>value_label</ogc:PropertyName>
        </Label>
        <Font>
          <CssParameter name="font-family">Arial</CssParameter>
          <CssParameter name="font-style">normal</CssParameter>
          <CssParameter name="font-weight">bold</CssParameter>
          <CssParameter name="font-size">6</CssParameter>
          <CssParameter name="fill">#FFFFFF</CssParameter>
        </Font>
        <LabelPlacement>
          <PointPlacement>
            <AnchorPoint>
              <AnchorPointX>0.5</AnchorPointX>
              <AnchorPointY>0.5</AnchorPointY>
            </AnchorPoint>
          </PointPlacement>
        </LabelPlacement>
      </TextSymbolizer>
      <PointSymbolizer>
        <sld:Geometry>
          <ogc:Function name="centroid">
            <ogc:PropertyName>wkb_geometry</ogc:PropertyName>
          </ogc:Function>
        </sld:Geometry>
        <Graphic>
          <Mark>
            <WellKnownName>circle</WellKnownName>
            <Fill>
              <CssParameter name="fill">#0033CC</CssParameter>
            </Fill>
          </Mark>
          <Size>10</Size>
        </Graphic>
      </PointSymbolizer>
    </Rule>
    <Rule>
      <Name>export_medium</Name>
      <Title>Exporte 20-40% vom BSP</Title>
      <ogc:Filter>
        <ogc:And>
          <ogc:PropertyIsGreaterThanOrEqualTo>
            <ogc:PropertyName>value_label</ogc:PropertyName>
            <ogc:Literal>20</ogc:Literal>
          </ogc:PropertyIsGreaterThanOrEqualTo>
          <ogc:PropertyIsLessThanOrEqualTo>
            <ogc:PropertyName>value_label</ogc:PropertyName>
            <ogc:Literal>40</ogc:Literal>
          </ogc:PropertyIsLessThanOrEqualTo>
        </ogc:And>
      </ogc:Filter>
      <TextSymbolizer>
        <sld:Geometry>
          <ogc:Function name="centroid">
            <ogc:PropertyName>wkb_geometry</ogc:PropertyName>
          </ogc:Function>
        </sld:Geometry>
        <Label>
          <ogc:PropertyName>value_label</ogc:PropertyName>
        </Label>
        <Font>
          <CssParameter name="font-family">Arial</CssParameter>
          <CssParameter name="font-style">normal</CssParameter>
          <CssParameter name="font-weight">bold</CssParameter>
          <CssParameter name="font-size">10</CssParameter>
          <CssParameter name="fill">#ffffff</CssParameter>
        </Font>
        <LabelPlacement>
          <PointPlacement>
            <AnchorPoint>
              <AnchorPointX>0.5</AnchorPointX>
              <AnchorPointY>0.5</AnchorPointY>
            </AnchorPoint>
          </PointPlacement>
        </LabelPlacement>
      </TextSymbolizer>
      <PointSymbolizer>
        <sld:Geometry>
          <ogc:Function name="centroid">
            <ogc:PropertyName>wkb_geometry</ogc:PropertyName>
          </ogc:Function>
        </sld:Geometry>
        <Graphic>
          <Mark>
            <WellKnownName>circle</WellKnownName>
            <Fill>
              <CssParameter name="fill">#0033CC</CssParameter>
            </Fill>
          </Mark>
          <Size>20</Size>
        </Graphic>
      </PointSymbolizer>
    </Rule>
    <Rule>
      <Name>export_high</Name>
      <Title>Exporte &gt; 40% vom BSP</Title>
      <ogc:Filter>
        <ogc:PropertyIsGreaterThan>
          <ogc:PropertyName>value_label</ogc:PropertyName>
          <ogc:Literal>40</ogc:Literal>
        </ogc:PropertyIsGreaterThan>
      </ogc:Filter>
      <TextSymbolizer>
        <sld:Geometry>
          <ogc:Function name="centroid">
            <ogc:PropertyName>wkb_geometry</ogc:PropertyName>
          </ogc:Function>
        </sld:Geometry>
        <Label>
          <ogc:PropertyName>value_label</ogc:PropertyName>
        </Label>
        <Font>
          <CssParameter name="font-family">Arial</CssParameter>
          <CssParameter name="font-style">normal</CssParameter>
          <CssParameter name="font-weight">bold</CssParameter>
          <CssParameter name="font-size">14</CssParameter>
          <CssParameter name="fill">#FFFFFF</CssParameter>
        </Font>
        <LabelPlacement>
          <PointPlacement>
            <AnchorPoint>
              <AnchorPointX>0.5</AnchorPointX>
              <AnchorPointY>0.5</AnchorPointY>
            </AnchorPoint>
          </PointPlacement>
        </LabelPlacement>
      </TextSymbolizer>
      <PointSymbolizer>
        <sld:Geometry>
          <ogc:Function name="centroid">
            <ogc:PropertyName>wkb_geometry</ogc:PropertyName>
          </ogc:Function>
        </sld:Geometry>
        <Graphic>
          <Mark>
            <WellKnownName>circle</WellKnownName>
            <Fill>
              <CssParameter name="fill">#0033CC</CssParameter>
            </Fill>
          </Mark>
          <Size>35</Size>
        </Graphic>
      </PointSymbolizer>
    </Rule>
  </FeatureTypeStyle>
</sld:UserStyle>
````

**Grafisch  sieht das Ergebnis wie folgt aus:**
<img title="Gestylte Karte" src="https://github.com/user-attachments/assets/b604a2a1-9e06-406f-91c1-613e5a0962a6">

> Nach vielen erfolglosen Versuchen, lies sich die Schriftfarbe innherhalb der blauen Kreise leider nicht ändern. Die Ursache dafür ist uns leider nicht bekannt. Ebenso war es uns nicht möglich die Umlaute korrekt darzustellen oder wenigstens in nicht-Umlaute zu ändern.


## 11. GetLegendGraphic

````http://localhost:8080/geoserver/wms?REQUEST=GetLegendGraphic&VERSION=1.0.0&FORMAT=image/png&WIDTH=20&HEIGHT=20&LAYER=exports_percent_gdp````

<img title="Legende der gestylten Karte" src="https://github.com/user-attachments/assets/c80ae53a-8185-4d2e-ad8a-663a9fbb8505">


## 12. Standardjahr auf 2000 einstellen
````http://localhost:8080/geoserver/gdd/wms?service=WMS&version=1.1.0&request=GetMap&layers=gdd%3Aexports_percent_gdp&bbox=-2.0037508342789244E7%2C-7538976.357111702%2C2.003750838011201E7%2C1.7926778564476732E7&width=768&height=488&srs=EPSG%3A3857&styles=&format=application/openlayers&viewparams:jahr=2000````
