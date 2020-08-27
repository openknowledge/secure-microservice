package de.openknowledge.examples.infrastructure.rest;


import javax.ws.rs.ApplicationPath;
import javax.ws.rs.core.Application;

import org.eclipse.microprofile.auth.LoginConfig;
import org.eclipse.microprofile.openapi.annotations.OpenAPIDefinition;
import org.eclipse.microprofile.openapi.annotations.info.Contact;
import org.eclipse.microprofile.openapi.annotations.info.Info;
import org.eclipse.microprofile.openapi.annotations.servers.Server;

@OpenAPIDefinition(
    info = @Info(
        title = "Secured Microservice",
        version = "1.0.0",
        contact = @Contact(
            name = "Tim de Buhr",
            email = "tim.debuhr@openknowledge.de",
            url = "https://www.openknowledge.de"),
        description = "The service provides all operations secured to the user"),
    servers = {
        @Server(url = "/", description = "secured-microservice")
    })
@LoginConfig(authMethod = "MP-JWT")
@ApplicationPath("/secure")
public class SecuredMicroserviceApplication extends Application {

}
