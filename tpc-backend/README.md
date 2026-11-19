# tpc-backend

Backend de TPC - Tus Pistas de Confi (Spring Boot 3.5, Java 17, Maven).

## Arrancar

    mvn spring-boot:run

## Probar

    curl http://localhost:8080/api/estado
    # {"ok":true}

## Tests

    mvn test

## Estructura

    src/main/java/com/tpc/api/
      TpcApplication.java      punto de entrada
      EstadoController.java   GET /api/estado
    src/main/resources/application.properties

La conexión a MySQL (tpc_tus_pistas_de_confi) y el CRUD se añadirán en la siguiente fase.
