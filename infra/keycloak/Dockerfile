FROM quay.io/keycloak/keycloak:26.6 AS builder

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

ENV KC_DB=postgres
ENV KC_HTTP_RELATIVE_PATH=/auth

RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.6

COPY --from=builder /opt/keycloak/ /opt/keycloak/
COPY import/ /opt/keycloak/data/import-template/
COPY docker-entrypoint.sh /opt/keycloak/docker-entrypoint.sh

USER root
RUN chmod +x /opt/keycloak/docker-entrypoint.sh \
    && mkdir -p /opt/keycloak/data/import \
    && chown keycloak:keycloak /opt/keycloak/data/import
USER keycloak

ENTRYPOINT ["/opt/keycloak/docker-entrypoint.sh"]
