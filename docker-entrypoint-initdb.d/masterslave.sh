#!/bin/bash

if [ $MARIADB_ROLE = "master" ]; then

    echo "MARIADB_ROLE set to $MARIADB_ROLE"

    echo "Creating replication user"
    mariadb -uroot -p$MARIADB_ROOT_PASSWORD \
    --execute="CREATE USER 'replication_user'@'%' IDENTIFIED BY 'DVvh5lnR1iqok1CV0cAd'; \
    GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%'; FLUSH TABLES WITH READ LOCK;"

    echo "Performing temporary backup of all databases"
    mariadb-dump -uroot -p$MARIADB_ROOT_PASSWORD --all-databases --master-data > /tmp/mariadb-backup/master_initialization.sql

    mariadb -uroot -p$MARIADB_ROOT_PASSWORD \
    --execute="SHOW MASTER STATUS;"

    mariadb -uroot -p$MARIADB_ROOT_PASSWORD \
    --execute="UNLOCK TABLES;"


else

    echo "MARIADB_ROLE set to slave"

    echo "Importing master database"
    mariadb -uroot -p$MARIADB_ROOT_PASSWORD < /tmp/mysql-backup/master_initialization.sql

    mariadb -uroot -p$MARIADB_ROOT_PASSWORD \
    --execute="SET GLOBAL server_id = 2;"

    echo "Setting replication host"
    mariadb -uroot -p$MARIADB_ROOT_PASSWORD \
    --execute="CHANGE MASTER TO MASTER_HOST='mariadb-master', MASTER_USER='replication_user', MASTER_PASSWORD='DVvh5lnR1iqok1CV0cAd', MASTER_PORT=3306, MASTER_LOG_FILE='master1-bin.000001', MASTER_LOG_POS=330, MASTER_USE_GTID = slave_pos, MASTER_CONNECT_RETRY=10;"


    echo "Starting replica"
    mariadb -uroot -p$MARIADB_ROOT_PASSWORD --execute="START SLAVE; SHOW SLAVE STATUS \G"

fi