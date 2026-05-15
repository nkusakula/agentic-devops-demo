package com.threeriversbank.service;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertFalse;

class CreditCardServiceGuardrailTest {

    @Test
    void creditCardServiceShouldNotContainThreadSleep() throws IOException {
        Path creditCardServicePath = Path.of("src/main/java/com/threeriversbank/service/CreditCardService.java");
        String source = Files.readString(creditCardServicePath);

        assertFalse(source.contains("Thread.sleep("),
                "CreditCardService must not block request handling with Thread.sleep");
    }
}
