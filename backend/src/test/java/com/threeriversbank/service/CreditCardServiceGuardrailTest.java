package com.threeriversbank.service;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertFalse;

class CreditCardServiceGuardrailTest {
    @Test
    void creditCardServiceShouldNotReferenceThreadSleep() throws IOException {
        try (InputStream classStream = CreditCardService.class.getClassLoader()
                .getResourceAsStream("com/threeriversbank/service/CreditCardService.class")) {
            assertNotNull(classStream, "Unable to load CreditCardService bytecode");
            byte[] classBytecode = classStream.readAllBytes();

            assertFalse(containsAscii(classBytecode, "java/lang/Thread")
                            && containsAscii(classBytecode, "sleep"),
                "CreditCardService must not block request handling with Thread.sleep");
        }
    }

    private boolean containsAscii(byte[] source, String token) {
        byte[] target = token.getBytes(StandardCharsets.US_ASCII);
        outer:
        for (int i = 0; i <= source.length - target.length; i++) {
            for (int j = 0; j < target.length; j++) {
                if (source[i + j] != target[j]) {
                    continue outer;
                }
            }
            return true;
        }
        return false;
    }
}
