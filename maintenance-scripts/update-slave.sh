 #!/bin/bash
set -e

if [ $MARIADB_ROLE = "master" ]; then
    echo "Server set to master. Script is to be run on a slave only"
    exit 1
fi

if [ $MARIADB_ROLE = "slave" ]; then

    echo "Backing up master server"
    mariadb -uroot -p$MARIADB_ROOT_PASSWORD -h mariadb-master \
        --execute="FLUSH TABLES WITH READ LOCK;"

    mariadb-dump -uroot -p$MARIADB_ROOT_PASSWORD -h mariadb-master \
        --all-databases --master-data | zstd > /tmp/mariadb-backup/master_initialization.sql.zstd

    mariadb -uroot -p$MARIADB_ROOT_PASSWORD -h mariadb-master \
        --execute="UNLOCK TABLES;"

    echo "Updating slave server"
    mariadb -uroot -p$MARIADB_ROOT_PASSWORD -h localhost \
        --execute="STOP SLAVE;"

    zstd -d < /tmp/mariadb-backup/master_initialization.sql.zstd | mariadb -uroot -p$MARIADB_ROOT_PASSWORD -h localhost

    echo "Restarting slave"
    mariadb -uroot -p$MARIADB_ROOT_PASSWORD -h localhost \
        --execute="START SLAVE;"
fi
