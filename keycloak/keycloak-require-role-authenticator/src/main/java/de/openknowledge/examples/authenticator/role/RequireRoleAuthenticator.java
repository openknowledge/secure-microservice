package de.openknowledge.examples.authenticator.role;

import java.util.Set;

import org.jboss.logging.Logger;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.Authenticator;
import org.keycloak.events.Errors;
import org.keycloak.models.AuthenticatorConfigModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.RoleModel;
import org.keycloak.models.UserModel;
import org.keycloak.models.utils.FormMessage;
import org.keycloak.models.utils.KeycloakModelUtils;
import org.keycloak.models.utils.RoleUtils;
import org.keycloak.services.messages.Messages;

public class RequireRoleAuthenticator implements Authenticator {

  private static final Logger LOG = Logger.getLogger(RequireRoleAuthenticator.class);

  @Override
  public void authenticate(AuthenticationFlowContext context) {
    AuthenticatorConfigModel configModel = context.getAuthenticatorConfig();

    String requiredRoleName = configModel.getConfig().get(RequireRoleAuthenticatorFactory.ROLE);

    if (!configurationValid(requiredRoleName)) {
      LOG.warn("Required role name is missing - may not be configured.");
      abortRequest(context);
      return;
    }

    RealmModel realm = context.getRealm();
    UserModel user = context.getUser();

    if (!hasRequiredRole(realm, user, requiredRoleName)) {
      LOG.info("Access denied for user (userId=" + user.getId()
          + ") on realm '" + realm.getName() + "' because of missing role '" + requiredRoleName + "'");
      abortRequest(context);
      return;
    }

    LOG.debug("Access granted for user (userId=" + user.getId() + ") on realm '" + realm.getName() + "'");
    context.success();
  }

  @Override
  public boolean requiresUser() {
    return false;
  }

  @Override
  public boolean configuredFor(KeycloakSession keycloakSession, RealmModel realmModel, UserModel userModel) {
    return true;
  }

  @Override
  public void setRequiredActions(KeycloakSession keycloakSession, RealmModel realmModel, UserModel userModel) {
    // nothing to do here
  }

  @Override
  public void action(AuthenticationFlowContext authenticationFlowContext) {
    // nothing to do here
  }

  // will called on every request
  @Override
  public void close() {
    // nothing to do here
  }

  private void abortRequest(AuthenticationFlowContext context) {
    context.getEvent().user(context.getUser());
    context.getEvent().error(Errors.NOT_ALLOWED);
    context.forkWithErrorMessage(new FormMessage(Messages.NO_ACCESS));
  }

  private boolean configurationValid(String requiredRoleName) {
    return requiredRoleName != null;
  }

  private boolean hasRequiredRole(RealmModel realm, UserModel user, String requiredRoleName) {
    LOG.debug("Checking if user [userId=" + user.getId() + "] has required role '" + requiredRoleName + "'");
    RoleModel requiredRole = KeycloakModelUtils.getRoleFromString(realm, requiredRoleName);

    Set<RoleModel> directAssignedRoles = user.getRoleMappings();
    LOG.debug("User [userId=" + user.getId() + "] has " + directAssignedRoles.size() + " direct assigned roles");
    if (RoleUtils.hasRole(directAssignedRoles, requiredRole)) {
      return true;
    }

    Set<RoleModel> nestedAssignedRoles = RoleUtils.getDeepUserRoleMappings(user);
    LOG.debug("User [userId=" + user.getId() + "] has " + nestedAssignedRoles.size() + " nested assigned roles");
    if (RoleUtils.hasRole(nestedAssignedRoles, requiredRole)) {
      return true;
    }

    LOG.debug("User [userId=" + user.getId() + "] does not have the required role '" + requiredRoleName + "'");
    return false;
  }
}
