# InferScale web image: nginx + the web page
# nginx's unprivileged image runs as the normal user nginx (uid 101), not root
FROM nginxinc/nginx-unprivileged:1.30.6-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY html/ /usr/share/nginx/html/

EXPOSE 8443
# plain-HTTP health check on localhost inside the container (never published)
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8081/healthz || exit 1
