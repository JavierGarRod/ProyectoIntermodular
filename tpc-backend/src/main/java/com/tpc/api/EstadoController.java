package com.tpc.api;

import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Ruta de prueba: comprueba que el servidor arranca y responde. */
@RestController
@RequestMapping("/api")
public class EstadoController {

    @GetMapping("/estado")
    public Map<String, Boolean> estado() {
        return Map.of("ok", true);
    }
}
