# API de TPC · Tus Pistas de Confi

API REST en Spring Boot. Todas las rutas cuelgan de `/api`, reciben y devuelven JSON y usan UTF-8.

- **URL base en local:** `http://localhost:8080/api`
- **Estado de la documentación:** diseño del Sprint 2. Cada ruta se marca como *hecha* cuando se implementa y se revisa en una Pull Request.

## Convenciones

| Código | Cuándo se devuelve |
|---|---|
| 200 | Consulta o modificación correcta |
| 201 | Recurso creado (incluye la cabecera `Location`) |
| 204 | Borrado correcto, sin cuerpo |
| 400 | Datos inválidos (falla Bean Validation o una restricción CHECK) |
| 401 | Falta autenticación (a partir del Sprint 3) |
| 403 | El rol no permite la operación (por ejemplo, un Cliente intenta crear una pista) |
| 404 | El recurso no existe |
| 409 | Conflicto: reserva solapada (regla RN05), email repetido o borrado de algo con dependencias |

**Formato de error** (todas las rutas):

```json
{
  "estado": 409,
  "error": "La pista ya tiene una reserva activa en esa franja horaria.",
  "ruta": "/api/reservas"
}
```

**Formatos de datos:** fechas `AAAA-MM-DD`, horas `HH:mm`, importes en euros con dos decimales.

---

## Estado

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `/api/estado` | Comprueba que el servidor responde | Hecha |

---

## Deportes

| Método | Ruta | Descripción | Rol |
|---|---|---|---|
| GET | `/api/deportes` | Lista el catálogo de deportes | Público |

```json
[
  { "idDeporte": 1, "nombre": "Pádel" },
  { "idDeporte": 2, "nombre": "Tenis" }
]
```

## Centros deportivos

| Método | Ruta | Descripción | Rol |
|---|---|---|---|
| GET | `/api/centros?ciudad=Sevilla` | Lista centros; `ciudad` es opcional | Público |
| GET | `/api/centros/{id}` | Detalle de un centro | Público |
| POST | `/api/centros` | Crea un centro | Admin |
| PUT | `/api/centros/{id}` | Modifica un centro | Admin |
| DELETE | `/api/centros/{id}` | Borra un centro y sus pistas (`ON DELETE CASCADE`) | Admin |

Cuerpo del `POST` y del `PUT`:

```json
{
  "nombre": "Centro Deportivo Supera Entrepuentes",
  "direccion": "Av. de Ramón y Cajal, s/n, 41005",
  "ciudad": "Sevilla",
  "telefono": "954924900",
  "descripcion": "Complejo deportivo en Nervión con pistas de pádel."
}
```

`nombre`, `direccion`, `ciudad` y `telefono` son obligatorios.

## Pistas

| Método | Ruta | Descripción | Rol |
|---|---|---|---|
| GET | `/api/pistas?deporte=1&ciudad=Sevilla&precioMax=20` | Busca pistas; todos los filtros son opcionales | Público |
| GET | `/api/pistas/{id}` | Detalle de una pista | Público |
| GET | `/api/pistas/{id}/disponibilidad?fecha=2026-12-01` | Franjas ocupadas de ese día | Público |
| POST | `/api/pistas` | Crea una pista | Admin |
| PUT | `/api/pistas/{id}` | Modifica una pista | Admin |
| DELETE | `/api/pistas/{id}` | Borra una pista; devuelve 409 si tiene reservas (`ON DELETE RESTRICT`) | Admin |

Cuerpo del `POST` y del `PUT`:

```json
{
  "idCentro": 1,
  "idDeporte": 1,
  "nombreNumero": "Pista Pádel 01 - Cristal Panorámica",
  "precioPorHora": 16.00
}
```

Respuesta de `GET /api/pistas/1/disponibilidad?fecha=2026-12-01`:

```json
{
  "idPista": 1,
  "fecha": "2026-12-01",
  "ocupadas": [
    { "horaInicio": "18:00", "horaFin": "19:30" }
  ]
}
```

## Reservas

| Método | Ruta | Descripción | Rol |
|---|---|---|---|
| GET | `/api/reservas?idUsuario=3` | Reservas de un usuario | Cliente (las suyas) o Admin |
| GET | `/api/reservas/{id}` | Detalle de una reserva | Cliente (la suya) o Admin |
| POST | `/api/reservas` | Crea una reserva | Cliente |
| PATCH | `/api/reservas/{id}/cancelar` | Cambia el estado a `Cancelada` | Cliente (la suya) o Admin |

### `POST /api/reservas`

Petición:

```json
{
  "idUsuario": 3,
  "idPista": 1,
  "fecha": "2026-12-01",
  "horaInicio": "18:00",
  "horaFin": "19:30"
}
```

Reglas:

- `horaFin` debe ser posterior a `horaInicio`.
- El servidor calcula `precioTotal` = `precioPorHora` × horas (16 € × 1,5 h = 24 €). El cliente no lo envía.
- La reserva nace con estado `Pendiente`.
- Si la franja se solapa con otra reserva no cancelada de la misma pista, el trigger `trg_evitar_solapamiento_reserva` rechaza la inserción y la API devuelve 409.
- A partir del Sprint 3, `idUsuario` se toma del token JWT y deja de enviarse en el cuerpo.

Respuesta `201 Created`:

```json
{
  "idReserva": 15,
  "idUsuario": 3,
  "idPista": 1,
  "fecha": "2026-12-01",
  "horaInicio": "18:00",
  "horaFin": "19:30",
  "estado": "Pendiente",
  "precioTotal": 24.00
}
```

Errores posibles:

| Código | Causa |
|---|---|
| 400 | Falta un campo, la hora de fin es anterior a la de inicio o la pista no existe |
| 409 | La franja se solapa con otra reserva (RN05) |

## Partidos de comunidad

| Método | Ruta | Descripción | Rol |
|---|---|---|---|
| GET | `/api/partidos?estado=Abierto` | Lista partidos; `estado` es opcional | Público |
| POST | `/api/partidos` | Crea un partido vinculado a una reserva propia | Cliente |
| POST | `/api/partidos/{id}/participantes` | El usuario se une al partido | Cliente |

Cuerpo del `POST /api/partidos`:

```json
{
  "idCreador": 3,
  "idReserva": 1,
  "jugadoresNecesarios": 3
}
```

Una reserva solo puede tener un partido (`id_reserva` es único). Si un usuario ya participa o el partido no está `Abierto`, `POST /api/partidos/{id}/participantes` devuelve 409.

## Autenticación (Sprint 3)

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/api/auth/registro` | Crea una cuenta con rol Cliente |
| POST | `/api/auth/login` | Devuelve un token JWT |

Las rutas protegidas reciben `Authorization: Bearer <token>`.
