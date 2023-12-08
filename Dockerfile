FROM mariadb:11.2

COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

RUN chmod -R 555 /docker-entrypoint-initdb.d/ \
   && mkdir -p /etc/default/template/mariadb-conf.d /tmp/mariadb-backup /var/log/mysql \
   && chown mysql:mysql /var/log/mysql /tmp/mariadb-backup

COPY mariadb-conf.d/80-master-or-slave.cnf /etc/mysql/mariadb.conf.d/

