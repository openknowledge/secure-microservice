package de.openknowledge.examples.infrastructure.rest;

import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import javax.ws.rs.ext.Provider;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Provider
@Produces(value = MediaType.APPLICATION_JSON)
public class ThrowableExceptionMapper implements ExceptionMapper<Throwable> {

  private static final Logger LOG = LoggerFactory.getLogger(ThrowableExceptionMapper.class);

  @Override
  public Response toResponse(Throwable e) {
    LOG.error("ThrowableExceptionMapper caught unexpected exception: {}", e.getMessage());
    return Response.status(Response.Status.BAD_REQUEST).entity(e.getMessage()).build();
  }
}
