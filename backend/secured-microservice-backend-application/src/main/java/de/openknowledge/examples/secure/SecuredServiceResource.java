package de.openknowledge.examples.secure;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;

import javax.annotation.security.DeclareRoles;
import javax.annotation.security.DenyAll;
import javax.annotation.security.RolesAllowed;
import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.eclipse.microprofile.jwt.JsonWebToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@DeclareRoles({"USER", "ADMIN"})
@DenyAll
@Path("/message")
@ApplicationScoped
@Produces(value = MediaType.APPLICATION_JSON)
public class SecuredServiceResource {

  private static final Logger LOG = LoggerFactory.getLogger(SecuredServiceResource.class);

  private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("dd.MM.yyyy hh:mm:ss");

  @Inject
  private JsonWebToken callerPrincipal;

  @GET
  @Path("/user")
  @RolesAllowed("USER")
  public Response userMessage() {
    logIssuer();
    return Response.ok(callerPrincipal.getName() + " is allowed to read USER message").build();
  }

  @GET
  @Path("/admin")
  @RolesAllowed("ADMIN")
  public Response adminMessage() {
    logIssuer();
    return Response.ok(callerPrincipal.getName() + " is allowed to read ADMIN message").build();
  }

  private void logIssuer() {
    LOG.info("caller: {}\nissuer: {}\ntokenId: {}\ncalled at: {}\ncall expired at: {}\ncurrent date is: {}\ngroups: {}",
        callerPrincipal.getSubject(), callerPrincipal.getIssuer(), callerPrincipal.getTokenID(),
        LocalDateTime.ofEpochSecond(callerPrincipal.getIssuedAtTime(), 0, ZoneOffset.ofHours(1)).format(FORMATTER),
        LocalDateTime.ofEpochSecond(callerPrincipal.getExpirationTime(), 0, ZoneOffset.ofHours(1)).format(FORMATTER),
        LocalDateTime.now().format(FORMATTER), callerPrincipal.getGroups());
  }

}
