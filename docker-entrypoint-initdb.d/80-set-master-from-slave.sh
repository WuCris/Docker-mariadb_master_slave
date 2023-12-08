 
#!/bin/bash
set -e

if [ $MARIADB_ROLE = "slave" ]; then

echo "Setting server ID on slave"
mariadb -uroot -p$MARIADB_ROOT_PASSWORD \
    --execute="SET GLOBAL server_id = 2;"
sed -i 's/server_id=1/server_id=2/g' /etc/mysql/mariadb.conf.d/80-master-or-slave.cnf

# Configuring the master node. We run this from the slave to allow a chronological 
# order of opperations so the slave cannot proceed until master is configured.

echo "Creating replication user and backup of Master"

mariadb -uroot -p$MARIADB_ROOT_PASSWORD -h mariadb-master \
    --execute="CREATE USER 'replication_user'@'%' IDENTIFIED BY 'DVvh5lnR1iqok1CV0cAd'; \
    GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%'; FLUSH TABLES WITH READ LOCK;"

mariadb-dump -uroot -p$MARIADB_ROOT_PASSWORD -h mariadb-master --all-databases --master-data > /tmp/mariadb-backup/master_initialization.sql

mariadb -uroot -p$MARIADB_ROOT_PASSWORD -h mariadb-master \
    --execute="UNLOCK TABLES;"


# Run the following on the slave node (localhost)

echo "Importing master database to slave"
mariadb -uroot -p$MARIADB_ROOT_PASSWORD < /tmp/mariadb-backup/master_initialization.sql

echo "Setting replication host on slave"
mariadb -uroot -p$MARIADB_ROOT_PASSWORD \
    --execute="CHANGE MASTER TO MASTER_HOST='mariadb-master', MASTER_USER='replication_user', MASTER_PASSWORD='DVvh5lnR1iqok1CV0cAd', MASTER_PORT=3306, MASTER_LOG_FILE='master1-bin.000002', MASTER_LOG_POS=689, MASTER_USE_GTID = slave_pos, MASTER_CONNECT_RETRY=10;"

echo "Start slave"
mariadb -uroot -p$MARIADB_ROOT_PASSWORD --execute="START SLAVE; SHOW SLAVE STATUS \G"

fi