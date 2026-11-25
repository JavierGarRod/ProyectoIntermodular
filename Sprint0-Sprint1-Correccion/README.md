# TPC · Tus Pistas de Confi

Plataforma web para buscar, comparar y reservar pistas deportivas (pádel, tenis, fútbol 7, fútbol sala, baloncesto y voleibol). El MVP empieza en Sevilla y su provincia.

Proyecto Intermodular de Javier García y Alexandru Cozaru.

## Qué hace el MVP

- Buscar pistas por deporte, ciudad y precio.
- Consultar la disponibilidad de una pista y reservar una franja.
- Impedir reservas solapadas con un trigger en MySQL (regla RN05) y con validación en el backend.
- Organizar partidos de comunidad y buscar jugadores.

## Tecnologías

| Capa | Tecnología |
|---|---|
| Base de datos | MySQL 8 |
| Backend | Java con Spring Boot 3 y Spring Data JPA |
| Seguridad | Spring Security, BCrypt y JWT (Sprint 3) |
| Frontend | HTML, CSS propio y JavaScript |

## Estructura del repositorio

```
ProyectoIntermodular/
├── database/     scripts SQL: esquema, trigger y datos de prueba
├── docs/         documentación: api.md y el PDF del proyecto
├── frontend/     componentes.html, css/ y js/
├── tpc-backend/  API Spring Boot
├── .env.example  variables de entorno de ejemplo
├── .gitignore
└── README.md
```

## Puesta en marcha

### 1. Base de datos

Necesitas MySQL 8 o superior. Ejecuta los scripts de `database/` en este orden: esquema, trigger y datos de prueba.

```bash
mysql -u root -p < database/schema.sql
```

Repite el comando con el resto de scripts de la carpeta. El primero crea la base `tpc_tus_pistas_de_confi`.

### 2. Variables de entorno

```bash
cp .env.example .env
```

Edita `.env` con tus datos. Spring Boot no lee ese fichero por sí solo: exporta las variables en tu terminal o defínelas en la configuración de ejecución de tu IDE. `application.properties` las usa con la sintaxis `${DB_URL}`.

### 3. Backend

```bash
cd tpc-backend
./mvnw spring-boot:run
```

Comprueba que funciona en `http://localhost:8080/api/estado`. Para lanzar los tests:

```bash
./mvnw test
```

### 4. Frontend

Abre `frontend/componentes.html` en el navegador para ver el catálogo de componentes.

## Documentación

- [Rutas de la API y JSON de ejemplo](docs/api.md)
- Documento del proyecto (Sprint 0 y Sprint 1): carpeta `docs/`

## Flujo de trabajo con Git

- `main`: versión estable. Solo recibe cambios desde `develop` al cerrar un sprint.
- `develop`: rama de integración.
- `feature/hu02-buscador`, `feature/hu05-reservas`…: una rama por historia de usuario, creada desde `develop`.

Cada rama entra en `develop` mediante una Pull Request que revisa la otra persona del equipo. Nadie aprueba su propia PR.

## Equipo

| Persona | Rol |
|---|---|
| Jesús Doña | Product Owner |
| Javier García | Scrum Master, diseño y pruebas |
| Alexandru Cozaru | Programación |

Backlog y tablero Sprint en Trello: enlace en el documento del proyecto.
