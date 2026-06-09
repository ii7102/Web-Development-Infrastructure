package com.example.app.web;

import java.time.Instant;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Proves the gateway -> backend route works out of the box. Controllers live
 * under /api because the gateway forwards /api/ to this service (prefix kept).
 * Replace / extend this when you build the real API.
 */
@RestController
@RequestMapping("/api")
public class PingController {

    @GetMapping("/ping")
    public Map<String, Object> ping() {
        return Map.of(
                "service", "backend",
                "status", "ok",
                "time", Instant.now().toString());
    }
}
