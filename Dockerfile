FROM nginx

COPY nginx.conf.template nginx.conf.template
CMD envsubst < nginx.conf.template '$PRIMARY_S3_HOST, $BACKUP_S3_HOST' > /etc/nginx/nginx.conf; nginx
