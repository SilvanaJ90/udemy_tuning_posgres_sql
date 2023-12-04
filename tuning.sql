
-- Entrar a postgres
 sudo -u postgres psql 

-- Ver el archivo de configuracion de postgres
postgres=# show config_file
postgres-# ;
               config_file               
-----------------------------------------
 /etc/postgresql/15/main/postgresql.conf
(1 fila)

-- dependiendo del parametro que se reinicie se debe reinicar, vamos a modificar el parametro de max conexiones permitidas
-- este parametro esta en 100 lo puedo dejar en 300 conexiones, y despues de esto reiniciar

#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------

# - Connection Settings -

#listen_addresses = 'localhost'		# what IP address(es) to listen on;
					# comma-separated list of addresses;
					# defaults to 'localhost'; use '*' for all
					# (change requires restart)
port = 5432				# (change requires restart)
max_connections = 300			# (change requires restart)



-- reiniciar
systemctl

-- Mostrar el valor del parametro

postgres=# show max_connections;
 max_connections 
-----------------
 300
(1 fila)

-- ver otra forma la vista del sistema

postgres=# \d pg_settings
                  Vista «pg_catalog.pg_settings»
     Columna     |  Tipo   | Ordenamiento | Nulable | Por omisión 
-----------------+---------+--------------+---------+-------------
 name            | text    |              |         | 
 setting         | text    |              |         | 
 unit            | text    |              |         | 
 category        | text    |              |         | 
 short_desc      | text    |              |         | 
 extra_desc      | text    |              |         | 
 context         | text    |              |         | 
 vartype         | text    |              |         | 
 source          | text    |              |         | 
 min_val         | text    |              |         | 
 max_val         | text    |              |         | 
 enumvals        | text[]  |              |         | 
 boot_val        | text    |              |         | 
 reset_val       | text    |              |         | 
 sourcefile      | text    |              |         | 
 sourceline      | integer |              |         | 
 pending_restart | boolean |              |         | 

postgres=# \x
Se ha activado el despliegue expandido.
postgres=# select * from pg_settings where name = 'max_connections';
-[ RECORD 1 ]---+------------------------------------------------------
name            | max_connections
setting         | 300
unit            | 
category        | Conexiones y Autentificación / Parámetros de Conexión
short_desc      | Número máximo de conexiones concurrentes.
extra_desc      | 
context         | postmaster
vartype         | integer
source          | configuration file
min_val         | 1
max_val         | 262143
enumvals        | 
boot_val        | 100
reset_val       | 100
sourcefile      | /etc/postgresql/15/main/postgresql.conf
sourceline      | 65
pending_restart | f

-- Otra forma de modificar parametros es con 
postgres=# show log_connections;
-[ RECORD 1 ]---+----
log_connections | off

postgres=# alter system set log_connections = 'on';
ALTER SYSTEM

postgres=# select pg_reload_conf();
-[ RECORD 1 ]--+--
pg_reload_conf | t


# cat /var/lib/postgresql/15/main/postgresql.auto.conf 
# Do not edit this file manually!
# It will be overwritten by the ALTER SYSTEM command.
log_connections = 'on'


postgres=# show wal_buffers;
 wal_buffers 
-------------
 4MB
(1 fila)


postgres=# \x
Se ha activado el despliegue expandido.
postgres=# select * from pg_settings where name = 'wal_buffers';
-[ RECORD 1 ]---+--------------------------------------------------
name            | wal_buffers
setting         | 512
unit            | 8kB
category        | Write-Ahead Log / Configuraciones
short_desc      | Búfers en memoria compartida para páginas de WAL.
extra_desc      | 
context         | postmaster
vartype         | integer
source          | default
min_val         | -1
max_val         | 262143
enumvals        | 
boot_val        | -1
reset_val       | 512
sourcefile      | 
sourceline      | 
pending_restart | f


-- tendriamos que hacer la multiplicacion 512 * 8kb = 4 mb

-- SET SESSION - Esta configuraciòn solo dura lo que dura la session. 
postgres=# show work_mem;
-[ RECORD 1 ]-
work_mem | 4MB
                                ^
postgres=# set session work_mem ='8MB';
SET

-- para resetear el valor del sistema 

postgres=# alter system reset log_connections;
ALTER SYSTEM
-- si tenemos mas de un parametro y queremos receptearlos todos le decimos 

postgres=# alter system reset all;
ALTER SYSTEM


-- SHARED_BUFFERS

-- RESERVA MEMORIA PARA SUS BUFFERS INTERNOS 

postgres=# show shared_buffers;
 shared_buffers 
----------------
 128MB
(1 fila)

postgres=# \q
silvana@silvana-pc:~$ cat /proc/meminfo | grep MemTotal
MemTotal:       12056032 kB
silvana@silvana-pc:~$ 

-- se le puede asignar el 25% de la memoria en este caso 3G
postgres=# alter system set shared_buffers = '3GB';

-- reinicio del servidor

systemctl

-- WORK_MEN Y MAINTENANCE_WORK_MEN
-- CANTIDAD DE MEMORIA QUE UTILIZA LAS FUNCIONES INTERNAS COMO ORDER BY, DISTIC,ETC 

-- VALOR ADECUADO ES ASIGNARLE UN 4% O 2% DE LA MEMORIA RAM PARA MI CASO SE LE PUEDE ASIGNAR 384mb

postgres=# ALTER SYSTEM SET work_mem = '384MB';
select pg_reload_conf();


-- MAINTENANCE_WORK_MEN

-- Cantidad maxima de memoria que usa las operaciones de mantenimiento como create index, fk etc

postgres=# show maintenance_work_mem;
 maintenance_work_mem 
----------------------
 64MB
(1 fila)


-- AJUSTAR LOS PROCESOS DEL SERVIDOR

-- CHECKPOINTER 
-- SE ENCARGA DE COPIAR LOS BLOQUES SUCIOS DE LA SHARED_BUFFERS A DISCOS, MARCA LOS BLOQUES COMO LIMIPIOS

postgres=# SHOW checkpoint_flush_after;
 checkpoint_flush_after 
------------------------
 256kB
(1 fila)


-- Este valor le indica a postgres que cuando se consuma este numero se produzca el checkpoint

postgres=# show checkpoint_timeout;
 checkpoint_timeout 
--------------------
 5min
(1 fila)


postgres=# show checkpoint_completion_target;
 checkpoint_completion_target 
------------------------------
 0.9
(1 fila)

-- valor por defecto 0.5 indica que lo haga a la mitad de tiempo antes que haga el siguiente checkpoint

postgres=# show bgwriter_delay;
 bgwriter_delay 
----------------
 200ms
(1 fila)

postgres=# show bgwriter_lru_maxpages;
 bgwriter_lru_maxpages 
-----------------------
 100
(1 fila)


-- PGTUNER
 https://pgtune.leopard.in.ua/

# DB Version: 15
# OS Type: linux
# DB Type: oltp
# Total Memory (RAM): 12 GB
# CPUs num: 1
# Connections num: 100
# Data Storage: ssd

max_connections = 100
shared_buffers = 3GB
effective_cache_size = 9GB
maintenance_work_mem = 768MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 15728kB
huge_pages = off
min_wal_size = 2GB
max_wal_size = 8GB