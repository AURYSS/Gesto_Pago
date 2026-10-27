package com.proyecto.servicios;

import com.proyecto.servicios.util.DotEnvLoader;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.info.BuildProperties;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.context.ApplicationContext;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Map;



@SpringBootApplication
@EnableScheduling
@EnableFeignClients
@RestController
@Slf4j

public class App implements CommandLineRunner {

    @Autowired
    private ApplicationContext context;

    @RequestMapping(value = "/", method = {RequestMethod.GET, RequestMethod.HEAD})
    public ResponseEntity<Map<String, String>> rootHealth() {
        return ResponseEntity.ok(Map.of("status", "UP", "service", "api-gesto-pago"));
    }


    public static void main(String[] args) {
        DotEnvLoader.cargarSiExiste();
        SpringApplication.run(App.class, args);
    }

    @Override
    public void run(String... args) {
        //	displayInfo(context.getBean(BuildProperties.class));
    }

    private static void displayInfo(BuildProperties buildProperties) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss").withZone(ZoneId.systemDefault());
        String out = formatter.format(buildProperties.getTime());
        log.info("Nombre artefacto: " + buildProperties.getName() + "\n"
                + "Versión: " + buildProperties.getVersion() + "\n"
                + "Fecha Compilación: " + out + "\n"
                + "Artefacto: " + buildProperties.getArtifact() + "\n"
                + "Grupo: " + buildProperties.getGroup());


    }
}
