package de.openknowledge.examples.infrastructure.rest;

import javax.ws.rs.ForbiddenException;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import javax.ws.rs.ext.Provider;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Provider
@Produces(value = MediaType.APPLICATION_JSON)
public class ForbiddenExceptionMapper implements ExceptionMapper<ForbiddenException> {

  private static final Logger LOG = LoggerFactory.getLogger(ForbiddenExceptionMapper.class);

  @Override
  public Response toResponse(ForbiddenException e) {
    LOG.debug("ForbiddenExceptionMapper caught exception: {}", e.getMessage());
    return Response.status(Response.Status.FORBIDDEN).entity(e.getMessage()).build();
  }
}
