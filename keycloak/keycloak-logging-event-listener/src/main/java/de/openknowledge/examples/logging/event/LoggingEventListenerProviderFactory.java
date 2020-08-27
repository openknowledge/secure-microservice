package de.openknowledge.examples.logging.event;

import org.jboss.logging.Logger;
import org.keycloak.Config;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventListenerProviderFactory;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

public class LoggingEventListenerProviderFactory implements EventListenerProviderFactory {

  private static final Logger LOG = Logger.getLogger(LoggingEventListenerProviderFactory.class);

  private static final String PROVIDER_ID = "event-logger";

  @Override
  public EventListenerProvider create(KeycloakSession keycloakSession) {
    return new LoggingEventListenerProvider();
  }

  // prepare everything to create event listener provider
  @Override
  public void init(Config.Scope scope) {
    LOG.info("Initialise logging event listener provider factory");
  }

  // post everything after creating event listener provider
  @Override
  public void postInit(KeycloakSessionFactory keycloakSessionFactory) {
    // do nothing here
  }

  // clean everything before shutdown the event listener provider
  @Override
  public void close() {
    LOG.info("Shutting down logging event listener provider factory");
  }

  @Override
  public String getId() {
    return PROVIDER_ID;
  }
}
