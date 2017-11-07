FROM nginx

COPY nginx.conf.template nginx.conf.template
CMD envsubst < nginx.conf.template '$S3_HOST, $S3_PATH_PREFIX' > /etc/nginx/nginx.conf; nginx
