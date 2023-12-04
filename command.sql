
-- VACUUM

-- MARCAR LAS TUPLAS MUERTAS COMO TUPLAS REUTILIZABLES, REUTILIZA LAS TUPLAS MARCADAS


-- CON ESTE EJEMPLO EXPLICARE COMO SE INGREMENTA EL ESPACIO AL DOBLE DE UNA TABLA POR UN UDATE

tuning=# CREATE TABLE table_test(id int) WITH (autovacuum_enabled = 'off');
CREATE TABLE
tuning=# INSERT INTO table_test SELECT * FROM generate_series(1, 100000);
INSERT 0 100000
tuning=# SELECT pg_size_pretty(pg_relation_size('table_test'));
 pg_size_pretty 
----------------
 3544 kB
(1 fila)

tuning=# UPDATE table_test SET ID = id + 1;
UPDATE 100000
tuning=# SELECT pg_size_pretty(pg_relation_size('table_test'));
 pg_size_pretty 
----------------
 7080 kB
(1 fila)



-- VACUUM


tuning=# vacuum table_test;
VACUUM
tuning=# SELECT pg_size_pretty(pg_relation_size('table_test'));
 pg_size_pretty 
----------------
 7080 kB
(1 fila)


tuning=# select count(*) from table_test;
 count  
--------
 100000
(1 fila)

tuning=# UPDATE table_test SET ID = id + 1;
UPDATE 100000
tuning=# SELECT pg_size_pretty(pg_relation_size('table_test'));
 pg_size_pretty 
----------------
 7080 kB
(1 fila)

tuning=# 

-- VACUUM FULL
-- MARCA LOS BLOQUES LIBRES Y LIBERA EL ESPACIO, PARA HACER ESTA OPERACION SE DEBE BLOQUEAR LAS TABLAS

tuning=# vacuum full table_test;
VACUUM
tuning=# \x
Se ha desactivado el despliegue expandido.
tuning=# select * from pg_stat_user_tables;
tuning=# 
tuning=# \x
Se ha activado el despliegue expandido.
tuning=# select * from pg_stat_user_tables;
-[ RECORD 1 ]-------+------------------------------
relid               | 18404
schemaname          | public
relname             | table_test
seq_scan            | 4
seq_tup_read        | 500000
idx_scan            | 
idx_tup_fetch       | 
n_tup_ins           | 100000
n_tup_upd           | 200000
n_tup_del           | 0
n_tup_hot_upd       | 118
n_live_tup          | 100000
n_dead_tup          | 100000
n_mod_since_analyze | 300000
n_ins_since_vacuum  | 0
last_vacuum         | 2023-12-04 12:02:25.034844-05
last_autovacuum     | 
last_analyze        | 
last_autoanalyze    | 
vacuum_count        | 1
autovacuum_count    | 0
analyze_count       | 0
autoanalyze_count   | 0


tuning=# SELECT pg_size_pretty(pg_relation_size('table_test'));
-[ RECORD 1 ]--+--------
pg_size_pretty | 3544 kB

tuning=# UPDATE table_test SET ID = id + 1;
UPDATE 100000
tuning=# UPDATE table_test SET ID = id + 1;
UPDATE 100000
tuning=# UPDATE table_test SET ID = id + 1;
UPDATE 100000
tuning=# UPDATE table_test SET ID = id + 1;
UPDATE 100000
tuning=# UPDATE table_test SET ID = id + 1;
UPDATE 100000
tuning=# UPDATE table_test SET ID = id + 1;
UPDATE 100000
tuning=# SELECT pg_size_pretty(pg_relation_size('table_test'));
-[ RECORD 1 ]--+------
pg_size_pretty | 24 MB

tuning=# \x
Se ha desactivado el despliegue expandido.
tuning=# vacuum full table_test;
VACUUM
tuning=# SELECT pg_size_pretty(pg_relation_size('table_test'));
 pg_size_pretty 
----------------
 3544 kB
(1 fila)

-- aumentando el maintenance_work_mem en la session, baja el tiempo en el que la tabla hace el vacuum full

tuning=# set session maintenance_work_men = '512MB';
ERROR:  parámetro de configuración «maintenance_work_men» no reconocido
tuning=# set session maintenance_work_mem = '512MB';
SET
tuning=# UPDATE table_test SET ID = id + 1;
UPDATE 100000
tuning=# UPDATE table_test SET ID = id + 1;
UPDATE 100000
tuning=# UPDATE table_test SET ID = id + 1;
UPDATE 100000
tuning=# UPDATE table_test SET ID = id + 1;
UPDATE 100000
tuning=# UPDATE table_test SET ID = id + 1;
UPDATE 100000
tuning=# \timing
El despliegue de duración está activado.
tuning=# vacuum full table_test;
VACUUM
Duración: 85,844 ms



-- AUTOVACUUM

-- LIMPIA LAS TUPLAS MUERTAS EN OPERACIONES COMO UPDATE, DELETE 
tuning=# show autovacuum_naptime;
 autovacuum_naptime 
--------------------
 1min
(1 fila)

tuning=# show autovacuum_max_workers;
 autovacuum_max_workers 
------------------------
 3
(1 fila)
 --- cada minuto se despierta y comprueba si hay trabajo que hacer

 tuning=# show autovacuum_vacuum_scale_factor;
 autovacuum_vacuum_scale_factor 
--------------------------------
 0.2
(1 fila)

tuning=# show autovacuum_vacuum_threshold;
 autovacuum_vacuum_threshold 
-----------------------------
 50
(1 fila)


-- con estos parametros autovacum sabe que tiene trabajo que hacer

-- estadisticas

tuning=# show autovacuum_analyze_scale_factor;
 autovacuum_analyze_scale_factor 
---------------------------------
 0.1
(1 fila)

tuning=# show autovacuum_analyze_threshold;
 autovacuum_analyze_threshold 
------------------------------
 50
(1 fila)

-- idle_in_transactions

tuning=# show idle_in_transaction_session_timeout;
 idle_in_transaction_session_timeout 
-------------------------------------
 0
(1 fila)

tuning=# show statement_timeout;
 statement_timeout 
-------------------
 0
(1 fila)

tuning=# show autovacuum_vacuum_cost_limit;
 autovacuum_vacuum_cost_limit 
------------------------------
 -1
(1 fila)



postgres=# show vacuum_cost_limit;
 vacuum_cost_limit 
-------------------
 200
(1 fila)

-- se ejecuta tan rapido como sea posible si llega a 200 se duerme

postgres=# show autovacuum_vacuum_cost_delay;
 autovacuum_vacuum_cost_delay 
------------------------------
 2ms
(1 fila)


tuning=# ALTER TABLE table_test set (autovacuum_vacuum_cost_delay = 0);
ALTER TABLE


