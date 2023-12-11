FROM mysql:8

COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/
COPY mysql-conf.d/ /etc/mysql/conf.d/

RUN chmod -R 555 /docker-entrypoint-initdb.d/ \
   && mkdir -p /tmp/mysql-backup /var/log/mysql \
   && chown -R mysql:mysql /etc/mysql/conf.d /var/log/mysql /tmp/mysql-backup