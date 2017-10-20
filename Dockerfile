FROM nginx

COPY nginx.conf.template nginx.conf.template
RUN envsubst < nginx.conf.template '$S3_HOST, $S3_PATH_PREFIX' > /etc/nginx/nginx.conf

CMD nginx
