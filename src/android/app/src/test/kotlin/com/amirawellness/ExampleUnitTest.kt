package com.amirawellness

import org.junit.Test // JUnit 4.13.2
import org.junit.Assert.* // JUnit 4.13.2

/**
 * Example test class that demonstrates basic unit testing with JUnit.
 * 
 * This class serves as a reference for developers to understand how to write
 * unit tests for the Amira Wellness application. It includes examples of
 * different assertion types commonly used in testing.
 */
class ExampleUnitTest {

    /**
     * Example test that verifies basic arithmetic operation.
     * 
     * This demonstrates the most basic form of assertion using assertEquals.
     */
    @Test
    fun addition_isCorrect() {
        assertEquals(4, 2 + 2)
    }

    /**
     * Example test that verifies string comparison.
     * 
     * This demonstrates how to test string equality, which will be useful
     * for testing text content and messages in the application.
     */
    @Test
    fun string_comparison_isCorrect() {
        val testString = "Amira Wellness"
        assertEquals("Amira Wellness", testString)
    }

    /**
     * Example test that demonstrates boolean assertions.
     * 
     * This demonstrates how to use assertTrue and assertFalse, which are helpful
     * for testing conditional logic and validations in the application.
     */
    @Test
    fun boolean_assertion_isCorrect() {
        assertTrue(true)
        assertFalse(false)
    }
}