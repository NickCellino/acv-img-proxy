FROM nginx

ENV S3_HOST='s3.amazonaws.com'
ENV S3_PATH_PREFIX='static-dev.acvauctions.com/'

COPY nginx.conf.template nginx.conf.template
RUN envsubst < nginx.conf.template '$S3_HOST, $S3_PATH_PREFIX' > /etc/nginx/nginx.conf

CMD nginx
