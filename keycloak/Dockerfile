FROM jboss/keycloak:11.0.0

USER root

# install jq for json parsing in keycloak-startup.sh
RUN microdnf install wget
RUN wget --quiet -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
RUN chmod +x ./jq
RUN mv jq /usr/bin

# logging event listener SPI
COPY keycloak-logging-event-listener/target/keycloak-logging-event-listener.jar /opt/jboss/keycloak/standalone/deployments/

# require role authenticator SPI
COPY keycloak-require-role-authenticator/target/keycloak-require-role-authenticator.jar /opt/jboss/keycloak/standalone/deployments/

# startup script for realm config
COPY keycloak-startup.sh /opt/jboss/startup-scripts/
RUN chmod +x /opt/jboss/startup-scripts/keycloak-startup.sh


