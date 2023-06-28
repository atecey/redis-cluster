FROM redis:7.0.11-alpine3.18

RUN mkdir /redis-conf && mkdir /redis-data

RUN apk add --update envsubst && rm  -rf /tmp/* /var/cache/apk/*

COPY redis-cluster.tmpl /redis-conf/redis-cluster.tmpl
COPY redis.tmpl         /redis-conf/redis.tmpl

# Add startup script
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod 755 /docker-entrypoint.sh

EXPOSE 7000 7001 7002 7003 7004 7005 7006 7007 7008 7009 7010

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["redis-cluster"]