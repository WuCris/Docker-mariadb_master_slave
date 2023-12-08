FROM mariadb:11.2

COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

RUN chmod -R 555 /docker-entrypoint-initdb.d/ \
   && mkdir -p /tmp/mariadb-backup /var/log/mysql \
   && chown mysql:mysql /etc/mysql/mariadb.conf.d /var/log/mysql /tmp/mariadb-backup

COPY mariadb-conf.d/ /etc/mysql/mariadb.conf.d/

