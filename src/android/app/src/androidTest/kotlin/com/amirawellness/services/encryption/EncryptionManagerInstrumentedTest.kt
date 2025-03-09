package com.amirawellness.services.encryption

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.junit.runner.RunWith
import java.io.File
import java.io.FileOutputStream
import java.io.FileInputStream
import android.content.Context

/**
 * Instrumented test class for EncryptionManager to verify encryption and decryption
 * functionality on actual Android devices
 */
@RunWith(AndroidJUnit4::class)
class EncryptionManagerInstrumentedTest {

    @get:Rule
    val tempFolder = TemporaryFolder()

    private lateinit var context: Context
    private lateinit var encryptionManager: EncryptionManager
    private val testData = "Test data for encryption".toByteArray()
    private val testJournalId = "test-journal-123"
    private val testPassword = "StrongP@ssw0rd"

    /**
     * Setup method to initialize test environment before each test
     */
    @Before
    fun setup() {
        // Get application context
        context = InstrumentationRegistry.getInstrumentation().targetContext
        
        // Initialize encryption manager
        encryptionManager = EncryptionManager.getInstance(context)
        
        // Log hardware-backed KeyStore availability for diagnostic purposes
        println("Hardware-backed KeyStore available: ${KeyStoreManager.isHardwareBackedKeyStoreAvailable()}")
    }

    /**
     * Test basic encryption and decryption functionality with a generated key
     */
    @Test
    fun testEncryptDecrypt() {
        // Generate a random key for testing
        val key = generateRandomKey()
        
        // Encrypt test data
        val encryptResult = encryptionManager.encrypt(testData, key)
        assertTrue("Encryption should succeed", encryptResult.isSuccess)
        
        val encryptedData = encryptResult.getOrNull()
        assertNotNull("Encrypted data should not be null", encryptedData)
        assertNotEquals("Encrypted data should be different from original", 
            testData.contentToString(), encryptedData?.encryptedBytes?.contentToString())
        
        // Decrypt the data
        val decryptResult = encryptionManager.decrypt(encryptedData!!, key)
        assertTrue("Decryption should succeed", decryptResult.isSuccess)
        
        val decryptedData = decryptResult.getOrNull()
        assertNotNull("Decrypted data should not be null", decryptedData)
        assertArrayEquals("Decrypted data should match original", testData, decryptedData)
    }

    /**
     * Test encryption with an empty key should fail
     */
    @Test
    fun testEncryptWithEmptyKey() {
        // Create an empty key (ByteArray of size 0)
        val emptyKey = ByteArray(0)
        
        // Attempt to encrypt data with the empty key
        val encryptResult = encryptionManager.encrypt(testData, emptyKey)
        
        // Verify that the operation returns an InvalidKey error
        assertTrue("Encryption should fail with empty key", encryptResult.isFailure)
        val error = encryptResult.exceptionOrNull()
        assertTrue("Error should be InvalidKey", error is EncryptionException.InvalidKey)
    }

    /**
     * Test file encryption and decryption on the device filesystem
     */
    @Test
    fun testEncryptDecryptFile() {
        // Generate a random key for testing
        val key = generateRandomKey()
        
        // Create a temporary input file with test data
        val inputFile = createTestFile(testData)
        
        // Create a temporary output file for encrypted data
        val encryptedFile = tempFolder.newFile("encrypted.bin")
        
        // Encrypt the input file to the output file
        val encryptResult = encryptionManager.encryptFile(inputFile, encryptedFile, key)
        assertTrue("File encryption should succeed", encryptResult.isSuccess)
        assertTrue("Encrypted file should exist", encryptedFile.exists())
        assertNotEquals("Encrypted file size should be different", inputFile.length(), encryptedFile.length())
        
        // Create a temporary file for decrypted output
        val decryptedFile = tempFolder.newFile("decrypted.bin")
        
        // Decrypt the encrypted file to the decrypted output file
        val decryptResult = encryptionManager.decryptFile(encryptedFile, decryptedFile, key)
        assertTrue("File decryption should succeed", decryptResult.isSuccess)
        assertTrue("Decrypted file should exist", decryptedFile.exists())
        
        // Read the decrypted file content
        val decryptedContent = readFileContent(decryptedFile)
        
        // Verify the decrypted content matches the original test data
        assertArrayEquals("Decrypted file content should match original", testData, decryptedContent)
    }

    /**
     * Test file encryption with invalid input file should fail
     */
    @Test
    fun testEncryptFileWithInvalidInput() {
        // Generate a random key for testing
        val key = generateRandomKey()
        
        // Create a reference to a non-existent input file
        val nonExistentFile = File(tempFolder.root, "does-not-exist.txt")
        
        // Create a valid output file
        val outputFile = tempFolder.newFile("output.bin")
        
        // Attempt to encrypt the non-existent file
        val encryptResult = encryptionManager.encryptFile(nonExistentFile, outputFile, key)
        
        // Verify that the operation returns a FileOperationFailed error
        assertTrue("Encryption should fail with non-existent input file", encryptResult.isFailure)
        val error = encryptResult.exceptionOrNull()
        assertTrue("Error should be FileOperationFailed", error is EncryptionException.FileOperationFailed)
    }

    /**
     * Test journal-specific encryption and decryption using the KeyStore
     */
    @Test
    fun testEncryptJournalDecryptJournal() {
        // Encrypt test data as a journal entry with a specific journal ID
        val encryptResult = encryptionManager.encryptJournal(testData, testJournalId)
        assertTrue("Journal encryption should succeed", encryptResult.isSuccess)
        
        val encryptedData = encryptResult.getOrNull()
        assertNotNull("Encrypted journal data should not be null", encryptedData)
        
        // Decrypt the encrypted journal data with the same journal ID
        val decryptResult = encryptionManager.decryptJournal(encryptedData!!, testJournalId)
        assertTrue("Journal decryption should succeed", decryptResult.isSuccess)
        
        val decryptedData = decryptResult.getOrNull()
        assertNotNull("Decrypted journal data should not be null", decryptedData)
        assertArrayEquals("Decrypted journal data should match original", testData, decryptedData)
    }

    /**
     * Test password-based encryption and decryption
     */
    @Test
    fun testEncryptWithPasswordDecryptWithPassword() {
        // Encrypt test data with a password
        val encryptResult = encryptionManager.encryptWithPassword(testData, testPassword)
        assertTrue("Password encryption should succeed", encryptResult.isSuccess)
        
        val passwordEncryptedData = encryptResult.getOrNull()
        assertNotNull("Password-encrypted data should not be null", passwordEncryptedData)
        
        // Decrypt the encrypted data with the same password
        val decryptResult = encryptionManager.decryptWithPassword(passwordEncryptedData!!, testPassword)
        assertTrue("Password decryption should succeed", decryptResult.isSuccess)
        
        val decryptedData = decryptResult.getOrNull()
        assertNotNull("Decrypted password data should not be null", decryptedData)
        assertArrayEquals("Decrypted password data should match original", testData, decryptedData)
    }

    /**
     * Test encryption with an empty password should fail
     */
    @Test
    fun testEncryptWithEmptyPassword() {
        // Attempt to encrypt data with an empty password
        val encryptResult = encryptionManager.encryptWithPassword(testData, "")
        
        // Verify that the operation returns an error
        assertTrue("Encryption should fail with empty password", encryptResult.isFailure)
        val error = encryptResult.exceptionOrNull()
        assertTrue("Error should be InvalidKey", error is EncryptionException.InvalidKey)
    }

    /**
     * Test Base64 encoding and decoding functionality
     */
    @Test
    fun testBase64EncodingDecoding() {
        // Encode test data to Base64
        val base64String = encryptionManager.encodeToBase64(testData)
        
        // Verify the encoded string is not empty and is in Base64 format
        assertNotNull("Base64 string should not be null", base64String)
        assertTrue("Base64 string should not be empty", base64String.isNotEmpty())
        
        // Decode the Base64 string back to binary
        val decodedData = encryptionManager.decodeFromBase64(base64String)
        
        // Verify the decoded data matches the original test data
        assertArrayEquals("Decoded Base64 data should match original", testData, decodedData)
    }

    /**
     * Test encryption and decryption of larger data chunks similar to audio recordings
     */
    @Test
    fun testLargeDataEncryptionDecryption() {
        // Generate a large random byte array (e.g., 1MB) to simulate audio data
        val largeData = ByteArray(1024 * 1024) // 1MB
        java.security.SecureRandom().nextBytes(largeData)
        
        // Generate a random key for testing
        val key = generateRandomKey()
        
        // Encrypt the large data
        val encryptResult = encryptionManager.encrypt(largeData, key)
        assertTrue("Large data encryption should succeed", encryptResult.isSuccess)
        
        val encryptedData = encryptResult.getOrNull()
        assertNotNull("Encrypted large data should not be null", encryptedData)
        
        // Decrypt the encrypted large data
        val decryptResult = encryptionManager.decrypt(encryptedData!!, key)
        assertTrue("Large data decryption should succeed", decryptResult.isSuccess)
        
        val decryptedData = decryptResult.getOrNull()
        assertNotNull("Decrypted large data should not be null", decryptedData)
        assertArrayEquals("Decrypted large data should match original", largeData, decryptedData)
    }

    /**
     * Test multiple rounds of encryption and decryption to ensure consistency
     */
    @Test
    fun testMultipleEncryptionRounds() {
        // Generate a random key for testing
        val key = generateRandomKey()
        
        // Perform multiple rounds of encryption and decryption on the same data
        var currentData = testData
        
        for (i in 1..5) {
            // Encrypt the current data
            val encryptResult = encryptionManager.encrypt(currentData, key)
            assertTrue("Encryption round $i should succeed", encryptResult.isSuccess)
            
            val encryptedData = encryptResult.getOrNull()
            assertNotNull("Encrypted data for round $i should not be null", encryptedData)
            
            // Decrypt the data
            val decryptResult = encryptionManager.decrypt(encryptedData!!, key)
            assertTrue("Decryption round $i should succeed", decryptResult.isSuccess)
            
            val decryptedData = decryptResult.getOrNull()
            assertNotNull("Decrypted data for round $i should not be null", decryptedData)
            
            // Verify the decrypted data matches the input for this round
            assertArrayEquals("Decrypted data should match input for round $i", currentData, decryptedData)
            
            // Use the decrypted data as input for the next round
            decryptedData?.let { currentData = it }
        }
        
        // Verify the final decrypted data matches the original test data
        assertArrayEquals("Data should be unchanged after multiple encryption/decryption rounds", 
            testData, currentData)
    }

    /**
     * Helper method to generate a random encryption key for testing
     */
    private fun generateRandomKey(): ByteArray {
        val key = ByteArray(32) // 256 bits
        java.security.SecureRandom().nextBytes(key)
        return key
    }

    /**
     * Helper method to create a test file with specified content
     */
    private fun createTestFile(content: ByteArray): File {
        val file = tempFolder.newFile()
        FileOutputStream(file).use { it.write(content) }
        return file
    }

    /**
     * Helper method to read the content of a file
     */
    private fun readFileContent(file: File): ByteArray {
        val content = ByteArray(file.length().toInt())
        FileInputStream(file).use { it.read(content) }
        return content
    }
}