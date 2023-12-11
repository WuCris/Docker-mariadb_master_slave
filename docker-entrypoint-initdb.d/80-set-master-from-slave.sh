 
#!/bin/bash
set -e

if [ $MYSQL_ROLE = "master" ]; then
    echo "Creating replication user and backup of Master"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD \
        --execute="CREATE USER 'replication_user'@'%' IDENTIFIED BY '$MYSQL_REPLICATION_PASS'; \
        GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%'; FLUSH PRIVILEGES; FLUSH TABLES WITH READ LOCK;" 
fi

if [ $MYSQL_ROLE = "slave" ]; then

    # These settings won't apply until entrypoint exits and temporary server is stopped.
    echo -e "\nread-only=1" >> /etc/mysql/conf.d/80-master-or-slave.cnf

    sleep 10s # Give master time to initialize
    echo "Backing up master host"
    mysql-dump -uroot -p$MYSQL_ROOT_PASSWORD -h mysql-master --all-databases --master-data | zstd > /tmp/mysql-backup/master_initialization.sql.zstd


    echo "Importing master database to slave"
    zstd -d < /tmp/mysql-backup/master_initialization.sql.zstd | mysql -uroot -p$MYSQL_ROOT_PASSWORD

    sleep 10s

    echo "Setting replication host on slave"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD \
        --execute="CHANGE MASTER TO \
                        MASTER_HOST='$MYSQL_MASTER_HOST',\
                        MASTER_USER='replication_user',\
                        MASTER_PASSWORD='$MYSQL_REPLICATION_PASS',\
                        MASTER_PORT=3306,\
                        MASTER_LOG_FILE='master1-bin.000002',\
                        MASTER_LOG_POS=344,\
                        MASTER_CONNECT_RETRY=10;"

    echo "Start slave"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD --execute="START SLAVE;"

    # GTID must be enabled after intial connection to prevent user creation error
    echo "Enabling GTID and restarting slave"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD --execute="STOP SLAVE; CHANGE MASTER TO master_use_gtid = slave_pos; START SLAVE; SHOW SLAVE STATUS \G"

    # Unlock tables on master only after slave is configured
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -h mysql-master \
        --execute="UNLOCK TABLES;"

fi
