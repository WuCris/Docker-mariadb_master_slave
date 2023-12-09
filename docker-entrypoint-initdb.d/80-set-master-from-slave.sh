 
#!/bin/bash
set -e

if [ $MARIADB_ROLE = "master" ]; then
    echo "Creating replication user and backup of Master"
    mariadb -uroot -p$MARIADB_ROOT_PASSWORD \
        --execute="CREATE USER 'replication_user'@'%' IDENTIFIED BY 'DVvh5lnR1iqok1CV0cAd'; \
        GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%'; FLUSH PRIVILEGES; FLUSH TABLES WITH READ LOCK;" 
fi

if [ $MARIADB_ROLE = "slave" ]; then

    echo "Setting server ID on slave to 2"
    # Set global to take effect during temporary server.
    mariadb -uroot -p$MARIADB_ROOT_PASSWORD \
        --execute="SET GLOBAL server_id = 2;"
    # These settings won't apply until entrypoint exits and temporary server is stopped.
    sed -i 's/server_id=1/server_id=2/g' /etc/mysql/mariadb.conf.d/80-master-or-slave.cnf

    sleep 10s # Give master time to initialize
    mariadb-dump -uroot -p$MARIADB_ROOT_PASSWORD -h mariadb-master --all-databases --master-data > /tmp/mariadb-backup/master_initialization.sql


    echo "Importing master database to slave"
    mariadb -uroot -p$MARIADB_ROOT_PASSWORD < /tmp/mariadb-backup/master_initialization.sql

    sleep 10s

    echo "Setting replication host on slave"
    mariadb -uroot -p$MARIADB_ROOT_PASSWORD \
        --execute="CHANGE MASTER TO \
                        MASTER_HOST='mariadb-master',\
                        MASTER_USER='replication_user',\
                        MASTER_PASSWORD='DVvh5lnR1iqok1CV0cAd',\
                        MASTER_PORT=3306,\
                        MASTER_LOG_FILE='master1-bin.000002',\
                        MASTER_LOG_POS=344,\
                        MASTER_CONNECT_RETRY=10;"

    echo "Start slave"
    mariadb -uroot -p$MARIADB_ROOT_PASSWORD --execute="START SLAVE; SHOW SLAVE STATUS \G"

    # Unlock tables on master only after slave is configured
    mariadb -uroot -p$MARIADB_ROOT_PASSWORD -h mariadb-master \
        --execute="UNLOCK TABLES;"

fi