-- CREAR EL INDEX PARA MEJORAR LA CONSULTA 


tuning=# CREATE TABLE test_index(id serial, city text);
CREATE TABLE
tuning=# INSERT INTO test_index (city)
tuning-# SELECT 'Murcia'
tuning-# FROM generate_series(1, 500000);
INSERT 0 500000
tuning=# analyze;
ANALYZE
tuning=# \timing
El despliegue de duración está activado.
tuning=# SELECT * FROM test_index where id = 10;
 id |  city  
----+--------
 10 | Murcia
(1 fila)

Duración: 51,161 ms
tuning=# CREATE INDEX idx_test ON test_index (id);
CREATE INDEX
Duración: 205,049 ms
tuning=# SELECT * FROM test_index where id = 10;
 id |  city  
----+--------
 10 | Murcia
(1 fila)

Duración: 1,490 ms

-- costos
-- insercion - tamaño 
tuning=# \di+
                                            Listado de relaciones
 Esquema |  Nombre  |  Tipo  |  Dueño   |   Tabla    | Persistencia | Método de acceso | Tamaño | Descripción 
---------+----------+--------+----------+------------+--------------+------------------+--------+-------------
 public  | idx_test | índice | postgres | test_index | permanente   | btree            | 11 MB  | 


-- only scan

tuning=# explain select id, city from test_index where id= 10;
                                 QUERY PLAN                                 
----------------------------------------------------------------------------
 Index Scan using idx_test on test_index  (cost=0.42..8.44 rows=1 width=11)
   Index Cond: (id = 10)
(2 filas)

Duración: 1,597 ms
tuning=# CREATE INDEX idx_test_index_city ON test_index (id) include (city);
CREATE INDEX
Duración: 214,955 ms
tuning=# explain select id, city from test_index where id= 10;
                                         QUERY PLAN                                         
--------------------------------------------------------------------------------------------
 Index Only Scan using idx_test_index_city on test_index  (cost=0.42..4.44 rows=1 width=11)
   Index Cond: (id = 10)
(2 filas)

Duración: 1,534 ms
tuning=# explain select id, city from test_index where id= 10;
                                         QUERY PLAN                                         
--------------------------------------------------------------------------------------------
 Index Only Scan using idx_test_index_city on test_index  (cost=0.42..4.44 rows=1 width=11)
   Index Cond: (id = 10)
(2 filas)

Duración: 0,876 ms


-- indices fk

tuning=# create table tasks(id_task serial primary key, status text);
CREATE TABLE
Duración: 13,282 ms

tuning=# create table items(id_items serial, id_task int, task_order int, name text,
constraint fk_items foreign key (id_task) references tasks (id_task)
match simple on update cascade on delete cascade);
CREATE TABLE
Duración: 11,880 ms

                                                  ^
Duración: 1,089 ms
tuning=# with tasks_rws as (
insert into tasks
select generate_series (1, 500000), 'closed'
returning id_task)
insert into items
select generate_series (1, 10), id_task, generate_series (1,10), 'Tarea numero: '||generate_series(1,10)
from tasks_rws;
INSERT 0 5000000
Duración: 30744,527 ms (00:30,745)

tuning=# with tasks_rws as (
insert into tasks
select generate_series (500001, 1000000), 'opened'
returning id_task)
insert into items
select generate_series (1, 10), id_task, generate_series (1,10), 'Tarea numero: '||generate_series(1,10)
from tasks_rws;
INSERT 0 5000000


Duración: 1,476 ms
tuning=# select * from tasks t join items i on t.id_task = i.id_task where t.id_task = 100;
 id_task | status | id_items | id_task | task_order |       name       
---------+--------+----------+---------+------------+------------------
     100 | closed |        1 |     100 |          1 | Tarea numero: 1
     100 | closed |        2 |     100 |          2 | Tarea numero: 2
     100 | closed |        3 |     100 |          3 | Tarea numero: 3
     100 | closed |        4 |     100 |          4 | Tarea numero: 4
     100 | closed |        5 |     100 |          5 | Tarea numero: 5
     100 | closed |        6 |     100 |          6 | Tarea numero: 6
     100 | closed |        7 |     100 |          7 | Tarea numero: 7
     100 | closed |        8 |     100 |          8 | Tarea numero: 8
     100 | closed |        9 |     100 |          9 | Tarea numero: 9
     100 | closed |       10 |     100 |         10 | Tarea numero: 10
(10 filas)

Duración: 259,162 ms
tuning=# CREATE INDEX idx_item_task ON items (id_task );
CREATE INDEX
Duración: 2400,517 ms (00:02,401)
tuning=# select * from tasks t join items i on t.id_task = i.id_task where t.id_task = 100;
 id_task | status | id_items | id_task | task_order |       name       
---------+--------+----------+---------+------------+------------------
     100 | closed |        1 |     100 |          1 | Tarea numero: 1
     100 | closed |        2 |     100 |          2 | Tarea numero: 2
     100 | closed |        3 |     100 |          3 | Tarea numero: 3
     100 | closed |        4 |     100 |          4 | Tarea numero: 4
     100 | closed |        5 |     100 |          5 | Tarea numero: 5
     100 | closed |        6 |     100 |          6 | Tarea numero: 6
     100 | closed |        7 |     100 |          7 | Tarea numero: 7
     100 | closed |        8 |     100 |          8 | Tarea numero: 8
     100 | closed |        9 |     100 |          9 | Tarea numero: 9
     100 | closed |       10 |     100 |         10 | Tarea numero: 10
(10 filas)

Duración: 1,591 


-- INDEX PARCIAL
-- ocupa menos espacio en disco, 

tuning=# explain select * from tasks where status = 'opened';
                          QUERY PLAN                           
---------------------------------------------------------------
 Seq Scan on tasks  (cost=0.00..17906.00 rows=495200 width=11)
   Filter: (status = 'opened'::text)
(2 filas)

Duración: 0,853 ms
tuning=# CREATE INDEX idx_status ON tasks (status ) where status = 'opened';
CREATE INDEX
Duración: 184,296 ms
tuning=# explain select * from tasks where status = 'opened';
                                    QUERY PLAN                                    
----------------------------------------------------------------------------------
 Index Scan using idx_status on tasks  (cost=0.42..10570.72 rows=495200 width=11)
(1 fila)

Duración: 1,653 ms
tuning=# explain select * from tasks where status = 'opened';
                                    QUERY PLAN                                    
----------------------------------------------------------------------------------
 Index Scan using idx_status on tasks  (cost=0.42..10570.72 rows=495200 width=11)
(1 fila)

Duración: 0,391 ms
tuning=# 


-- fill factor

tuning=# ALTER TABLE table_test SET(FILLFACTOR = 60);
ALTER TABLE
Duración: 2,195 ms
tuning=# SELECT pc.relname as objectname,
       pc.reloptions as objectoptions
  FROM pg_class AS pc INNER JOIN pg_namespace AS pns ON pns.oid = pc.relnamespace
 WHERE pns.nspname ='public'
   AND pc.relname = 'table_test';
 objectname |                             objectoptions                             
------------+-----------------------------------------------------------------------
 table_test | {autovacuum_enabled=off,autovacuum_vacuum_cost_delay=0,fillfactor=60}
(1 fila)



-----------------
-- Bloat Index --
-----------------

SELECT nspname,
       relname,
       ROUND (100 * PG_RELATION_SIZE (indexrelid) / PG_RELATION_SIZE (indrelid)) / 100 AS index_ratio,
       PG_SIZE_PRETTY (PG_RELATION_SIZE (indexrelid)) AS index_size,
       PG_SIZE_PRETTY (PG_RELATION_SIZE (indrelid)) AS table_size
  FROM pg_index i LEFT JOIN pg_class c ON (c.oid = i.indexrelid)
                  LEFT JOIN pg_namespace n ON (c.oid = c.relnamespace)
 WHERE nspname NOT IN ('pg_catalog','information_schema','pg_toast')
   AND c.relkind = 'i'
   AND PG_RELATION_SIZE (indrelid) > 0;


   -- bajar un indice hinchado

   reindex index idx_test;


   -- COST

   postgres=# show seq_page_cost;
 seq_page_cost 
---------------
 1
(1 fila)

postgres=# show random_page_cost;
 random_page_cost 
------------------
 1.1
(1 fila)

postgres=# show cpu_tuple_cost ;
 cpu_tuple_cost 
----------------
 0.01
(1 fila)

postgres=# show cpu_operator_cost ;
 cpu_operator_cost 
-------------------
 0.0025
(1 fila)
 