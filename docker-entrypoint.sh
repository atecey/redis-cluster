#!/bin/sh
waitForRedis() {
    while true; do
        sleep 1
        redis-cli -h "$1" -p "$2" PING &>/dev/null
        if [ $? -eq 0 ]; then
            break
        fi
    done
}

sysctl vm.overcommit_memory=1

if [ "$1" = 'redis-cluster' ]; then

    if [ -z "$INITIAL_PORT" ]; then # Default to port 7000
      INITIAL_PORT=7000
    fi

    if [ -z "$MASTERS" ]; then # Default to 3 masters
      MASTERS=3
    fi

    if [ -z "$SLAVES_PER_MASTER" ]; then # Default to 1 slave for each master
      SLAVES_PER_MASTER=1
    fi

    if [ -z "$BIND_ADDRESS" ]; then # Default to any IPv4 address
      BIND_ADDRESS=0.0.0.0
    fi

    max_port=$(($INITIAL_PORT + $MASTERS * ( $SLAVES_PER_MASTER  + 1 ) - 1))
    first_standalone=$(($max_port + 1))
    
    for port in $(seq $INITIAL_PORT $max_port); do
      mkdir -p /redis-conf/${port}
      mkdir -p /redis-data/${port}

      if [ -e /redis-data/${port}/nodes.conf ]; then
        rm /redis-data/${port}/nodes.conf
      fi

      if [ -e /redis-data/${port}/dump.rdb ]; then
        rm /redis-data/${port}/dump.rdb
      fi

      if [ -e /redis-data/${port}/appendonly.aof ]; then
        rm /redis-data/${port}/appendonly.aof
      fi

      if [ "$port" -lt "$first_standalone" ]; then
        PORT=${port} BIND_ADDRESS=${BIND_ADDRESS} envsubst < /redis-conf/redis-cluster.tmpl > /redis-conf/${port}/redis.conf
        nodes="$nodes localhost:$port"
        redis-server /redis-conf/${port}/redis.conf --port "$port" &
        waitForRedis "localhost" "$port"
      else
        PORT=${port} BIND_ADDRESS=${BIND_ADDRESS} envsubst < /redis-conf/redis.tmpl > /redis-conf/${port}/redis.conf
        redis-server /redis-conf/${port}/redis.conf --port "$port" &
        waitForRedis "localhost" "$port"
      fi
    done

    echo "creating the cluster"
    yes "yes" | redis-cli --cluster create $nodes --cluster-replicas "$SLAVES_PER_MASTER" 

    tail -f /dev/null
fi

 exec "$@"