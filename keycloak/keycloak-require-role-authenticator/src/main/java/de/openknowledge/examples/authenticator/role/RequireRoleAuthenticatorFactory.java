package de.openknowledge.examples.authenticator.role;

import java.util.Collections;
import java.util.List;

import org.jboss.logging.Logger;
import org.keycloak.Config;
import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.AuthenticatorFactory;
import org.keycloak.models.AuthenticationExecutionModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.provider.ProviderConfigProperty;

public class RequireRoleAuthenticatorFactory implements AuthenticatorFactory {

  private static final Logger LOG = Logger.getLogger(RequireRoleAuthenticatorFactory.class);

  private static final String PROVIDER_ID = "required-role";

  static final String ROLE = "role";

  @Override
  public String getDisplayType() {
    return "Require Role";
  }

  @Override
  public String getReferenceCategory() {
    return null;
  }

  @Override
  public boolean isConfigurable() {
    return true;
  }

  @Override
  public AuthenticationExecutionModel.Requirement[] getRequirementChoices() {
    return new AuthenticationExecutionModel.Requirement[] {
        AuthenticationExecutionModel.Requirement.REQUIRED,
        AuthenticationExecutionModel.Requirement.DISABLED
    };
  }

  @Override
  public boolean isUserSetupAllowed() {
    return false;
  }

  @Override
  public String getHelpText() {
    return "Requires the user to have a given role.";
  }

  @Override
  public List<ProviderConfigProperty> getConfigProperties() {

    ProviderConfigProperty role = new ProviderConfigProperty();
    role.setType(ProviderConfigProperty.ROLE_TYPE);
    role.setName(ROLE);
    role.setLabel("Role");
    role.setHelpText("Required role.");

    return Collections.singletonList(role);
  }

  @Override
  public Authenticator create(KeycloakSession keycloakSession) {
    return new RequireRoleAuthenticator();
  }

  // prepare everything to create authenticator
  @Override
  public void init(Config.Scope scope) {
    LOG.info("Initialise required role authenticator factory");
  }

  // post everything after creating authenticator
  @Override
  public void postInit(KeycloakSessionFactory keycloakSessionFactory) {
    // nothing to do here
  }

  // clean everything before shutdown the authenticator
  @Override
  public void close() {
    // nothing to do here
  }

  @Override
  public String getId() {
    return PROVIDER_ID;
  }
}
