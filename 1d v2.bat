ogr2ogr -f "PGDUMP" output.sql "E:\CloudStation\Studium\Semester 5\Geodatendienste\Vector\countries.shp" -nln laender -nlt MULTIPOLYGON -a_srs EPSG:4326
psql -U postgres -d gdd -f output.sql