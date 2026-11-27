# InferScale web image: nginx + the web page
# nginx's unprivileged image runs as the normal user nginx (uid 101), not root.
# Mainline nginx (1.31) gets security fixes first; nginx recommends it for most users.
FROM nginxinc/nginx-unprivileged:1.31.7-alpine

# Security updates for the Alpine packages (Trivy in CI found fixed versions of musl, libxml2 and
# libxslt), then back to the nginx user
USER root
RUN apk upgrade --no-cache
USER 101

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY html/ /usr/share/nginx/html/

EXPOSE 8443
# plain-HTTP health check on localhost inside the container (never published)
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8081/healthz"]
