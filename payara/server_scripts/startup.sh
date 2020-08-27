#!/bin/sh

# 500ms default tracing threshold
TRACING_THRESHOLD=${TRACING_THRESHOLD:500}

cat > /opt/payara/preboot.cli << EOF
EOF

cat > /opt/payara/postboot.cli << EOF
notification-configure --enabled=true --dynamic=true
notification-log-configure --dynamic=true --enabled=true
set-requesttracing-configuration --enabled=true --dynamic=true --thresholdValue=${TRACING_THRESHOLD} --thresholdUnit="MILLISECONDS"
requesttracing-log-notifier-configure --enabled=true --dynamic=true
EOF

java -jar /opt/payara/payara-micro.jar \
  --noCluster \
  --deploymentDir /opt/payara/deployments \
  --prebootcommandfile /opt/payara/preboot.cli \
  --postbootcommandfile /opt/payara/postboot.cli \
  --logproperties /opt/payara/logging.properties \
  --addLibs /opt/payara/external-libs
