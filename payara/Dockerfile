FROM docker.io/alpine:3.12.0

ENV PAYARA_PATH /opt/payara

RUN   apk update \
 &&   apk add ca-certificates wget openjdk11 \
 &&   update-ca-certificates && \
 mkdir -p $PAYARA_PATH/deployments && \
 adduser -D -h $PAYARA_PATH payara && echo payara:payara | chpasswd && \
 chown -R payara:payara /opt

ARG PAYARA_VERSION=5.201
ARG PAYARA_PKG=https://repo1.maven.org/maven2/fish/payara/extras/payara-micro/${PAYARA_VERSION}/payara-micro-${PAYARA_VERSION}.jar
ARG PAYARA_CHECKSUM="4314ee56077eaf5b26fb7f868d20c7b1b384e0cc"
ENV PKG_FILE_NAME payara-micro.jar

RUN wget --quiet -O $PAYARA_PATH/$PKG_FILE_NAME $PAYARA_PKG
RUN echo "$PAYARA_CHECKSUM  $PAYARA_PATH/$PKG_FILE_NAME" > /tmp/checksum
RUN cat /tmp/checksum && sha1sum $PAYARA_PATH/$PKG_FILE_NAME
RUN sha1sum -c /tmp/checksum

ENV DEPLOY_DIR $PAYARA_PATH/deployments
ENV AUTODEPLOY_DIR $PAYARA_PATH/deployments
ENV PAYARA_MICRO_JAR=$PAYARA_PATH/$PKG_FILE_NAME

# Default payara ports to expose
EXPOSE 4848 8009 8080

USER payara
WORKDIR $PAYARA_PATH

ADD --chown=payara:payara server_scripts/startup.sh /opt/payara/startup.sh
ADD --chown=payara:payara server_scripts/logging.profiles /opt/payara/logging.properties

# Add dependencies
COPY server_libs/slf4j-*.jar /opt/payara/external-libs/

ENTRYPOINT ["/opt/payara/startup.sh"]
