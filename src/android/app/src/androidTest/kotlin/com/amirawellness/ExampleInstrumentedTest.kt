package com.amirawellness

import androidx.test.platform.app.InstrumentationRegistry // androidx.test.platform:platform:1.1.5
import androidx.test.ext.junit.runners.AndroidJUnit4 // androidx.test.ext:junit:1.1.5
import org.junit.Test // org.junit:junit:4.13.2
import org.junit.Assert.* // org.junit:junit:4.13.2
import org.junit.runner.RunWith // org.junit:junit:4.13.2

/**
 * Example instrumented test class for the Amira Wellness application.
 *
 * These tests require a connected Android device or emulator to run properly as they
 * access the actual application context and resources. This class demonstrates basic
 * Android instrumentation testing principles and serves as a template for more complex
 * test implementations.
 *
 * See [testing documentation](http://d.android.com/tools/testing).
 */
@RunWith(AndroidJUnit4::class)
class ExampleInstrumentedTest {

    /**
     * Verifies that the application package name is correct.
     *
     * This is a basic sanity check to ensure that the test is running against
     * the expected application package.
     */
    @Test
    fun useAppContext() {
        // Context of the app under test
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        
        // Verify the package name matches our application
        assertEquals("com.amirawellness", appContext.packageName)
    }
}