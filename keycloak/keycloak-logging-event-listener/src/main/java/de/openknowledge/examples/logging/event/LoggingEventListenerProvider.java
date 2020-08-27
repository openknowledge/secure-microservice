package de.openknowledge.examples.logging.event;

import org.jboss.logging.Logger;
import org.keycloak.events.Event;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.admin.AdminEvent;

public class LoggingEventListenerProvider implements EventListenerProvider {

  private static final Logger LOG = Logger.getLogger(LoggingEventListenerProvider.class);

  public LoggingEventListenerProvider() {
    LOG.debug("Initialise logging event listener provider");
  }

  @Override
  public void onEvent(Event event) {
    LOG.info("Receive event [userId=" + event.getUserId() + ",eventType=" + event.getType() + "]");
  }

  @Override
  public void onEvent(AdminEvent event, boolean includeRepresentation) {
    LOG.debug("Receive event [realmId=" + event.getRealmId() + ",eventType=" + event.getResourceType() + "]");
  }

  // will called on every request
  @Override
  public void close() {
    LOG.debug("Shutting down logging event listener provider");
  }

}
