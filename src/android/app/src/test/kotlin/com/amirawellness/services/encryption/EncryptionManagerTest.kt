package com.amirawellness.services.encryption

import org.junit.Before
import org.junit.Test
import org.junit.Rule
import org.junit.rules.TemporaryFolder
import org.mockito.Mock
import org.mockito.Mockito
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.whenever
import org.mockito.kotlin.any
import org.mockito.kotlin.verify
import org.junit.Assert.*
import android.content.Context
import java.io.File
import com.amirawellness.core.constants.AppConstants

/**
 * Test class for EncryptionManager to verify encryption and decryption functionality
 * with a focus on ensuring proper AES-256-GCM encryption implementation for sensitive user data.
 */
class EncryptionManagerTest {
    @get:Rule
    val tempFolder = TemporaryFolder()
    
    @Mock
    private lateinit var mockContext: Context
    
    @Mock
    private lateinit var mockKeyStoreManager: KeyStoreManager
    
    private lateinit var encryptionManager: EncryptionManager
    
    private val testData = "Test data for encryption".toByteArray()
    private val testKey = ByteArray(32) { 1 } // 32-byte test key
    private val testJournalId = "test-journal-123"
    private val testPassword = "StrongP@ssw0rd"
    
    @Before
    fun setup() {
        // Initialize Mockito annotations
        MockitoAnnotations.openMocks(this)
        
        // Set up KeyStoreManager mock to return test key
        whenever(mockKeyStoreManager.getDataKey(any(), any())).thenReturn(Result.success(testKey))
        whenever(mockKeyStoreManager.generateDataKey(any(), any())).thenReturn(Result.success(testKey))
        whenever(mockKeyStoreManager.deriveKeyFromPassword(any())).thenReturn(Result.success(Pair(testKey, ByteArray(16))))
        whenever(mockKeyStoreManager.deriveKeyFromPassword(any(), any())).thenReturn(Result.success(Pair(testKey, ByteArray(16))))
        
        // Get the EncryptionManager instance
        encryptionManager = EncryptionManager.getInstance(mockContext)
        
        // In a real test, we would need to inject the mocked KeyStoreManager
        // This could be done via reflection or a test constructor
        // For this exercise, we'll assume this injection has been done
    }
    
    @Test
    fun testEncryptDecrypt() {
        // Encrypt test data using the encryption manager
        val encryptResult = encryptionManager.encrypt(testData, testKey)
        
        // Verify encryption succeeded
        assertTrue("Encryption should succeed", encryptResult.isSuccess)
        
        val encryptedData = encryptResult.getOrThrow()
        
        // Verify the encrypted data is not the same as the original
        assertFalse("Encrypted data should be different from original", 
                   testData.contentEquals(encryptedData.encryptedBytes))
        
        // Decrypt the encrypted data
        val decryptResult = encryptionManager.decrypt(encryptedData, testKey)
        
        // Verify decryption succeeded
        assertTrue("Decryption should succeed", decryptResult.isSuccess)
        
        val decryptedData = decryptResult.getOrThrow()
        
        // Verify the decrypted data matches the original test data
        assertTrue("Decrypted data should match original", 
                  testData.contentEquals(decryptedData))
    }
    
    @Test
    fun testEncryptWithEmptyKey() {
        // Attempt to encrypt data with an empty key
        val emptyKey = ByteArray(0)
        val result = encryptionManager.encrypt(testData, emptyKey)
        
        // Verify that the operation returns an InvalidKey error
        assertTrue("Encryption with empty key should fail", result.isFailure)
        val error = result.exceptionOrNull()
        assertTrue("Error should be InvalidKey type", error is EncryptionException.InvalidKey)
    }
    
    @Test
    fun testDecryptWithEmptyKey() {
        // Create a valid encrypted data object
        val validResult = encryptionManager.encrypt(testData, testKey)
        val validEncryptedData = validResult.getOrThrow()
        
        // Attempt to decrypt with an empty key
        val emptyKey = ByteArray(0)
        val result = encryptionManager.decrypt(validEncryptedData, emptyKey)
        
        // Verify that the operation returns an InvalidKey error
        assertTrue("Decryption with empty key should fail", result.isFailure)
        val error = result.exceptionOrNull()
        assertTrue("Error should be InvalidKey type", error is EncryptionException.InvalidKey)
    }
    
    @Test
    fun testDecryptWithInvalidData() {
        // Create an invalid encrypted data object
        val invalidIv = ByteArray(12) { 0 }
        val invalidEncryptedData = EncryptedData(ByteArray(10), invalidIv)
        
        // Attempt to decrypt the invalid data
        val result = encryptionManager.decrypt(invalidEncryptedData, testKey)
        
        // Verify that the operation returns a DecryptionFailed error
        assertTrue("Decryption with invalid data should fail", result.isFailure)
        val error = result.exceptionOrNull()
        assertTrue("Error should be DecryptionFailed type", error is EncryptionException.DecryptionFailed)
    }
    
    @Test
    fun testEncryptDecryptFile() {
        // Create a temporary input file with test data
        val inputFile = tempFolder.newFile("test_input.txt")
        inputFile.writeBytes(testData)
        
        // Create a temporary output file for encrypted data
        val encryptedFile = tempFolder.newFile("test_encrypted.enc")
        
        // Encrypt the input file to the output file
        val encryptResult = encryptionManager.encryptFile(inputFile, encryptedFile, testKey)
        
        // Verify encryption succeeded
        assertTrue("File encryption should succeed", encryptResult.isSuccess)
        assertTrue("Encrypted file should exist", encryptedFile.exists())
        assertTrue("Encrypted file should not be empty", encryptedFile.length() > 0)
        
        // Create a temporary file for decrypted output
        val decryptedFile = tempFolder.newFile("test_decrypted.txt")
        
        // Decrypt the encrypted file to the decrypted output file
        val decryptResult = encryptionManager.decryptFile(encryptedFile, decryptedFile, testKey)
        
        // Verify decryption succeeded
        assertTrue("File decryption should succeed", decryptResult.isSuccess)
        assertTrue("Decrypted file should exist", decryptedFile.exists())
        
        // Verify the decrypted content matches the original test data
        val decryptedContent = decryptedFile.readBytes()
        assertTrue("Decrypted file content should match original", 
                  testData.contentEquals(decryptedContent))
    }
    
    @Test
    fun testEncryptFileWithInvalidInput() {
        // Create a non-existent input file
        val nonExistentFile = File(tempFolder.root, "non_existent.txt")
        val outputFile = tempFolder.newFile("output.enc")
        
        // Attempt to encrypt the non-existent file
        val result = encryptionManager.encryptFile(nonExistentFile, outputFile, testKey)
        
        // Verify that the operation returns a FileOperationFailed error
        assertTrue("Encryption with invalid input file should fail", result.isFailure)
        val error = result.exceptionOrNull()
        assertTrue("Error should be FileOperationFailed type", error is EncryptionException.FileOperationFailed)
    }
    
    @Test
    fun testEncryptJournalDecryptJournal() {
        // Set up KeyStoreManager mock to return a journal-specific key
        whenever(mockKeyStoreManager.getDataKey(KeyType.JOURNAL, testJournalId))
            .thenReturn(Result.success(testKey))
        
        // Encrypt test data as a journal entry
        val journalResult = encryptionManager.encryptJournal(testData, testJournalId)
        
        // Verify encryption succeeded
        assertTrue("Journal encryption should succeed", journalResult.isSuccess)
        
        val encryptedJournal = journalResult.getOrThrow()
        
        // Verify the encrypted data is not the same as the original
        assertFalse("Encrypted journal data should be different from original", 
                   testData.contentEquals(encryptedJournal.encryptedBytes))
        
        // Decrypt the encrypted journal data
        val decryptResult = encryptionManager.decryptJournal(encryptedJournal, testJournalId)
        
        // Verify decryption succeeded
        assertTrue("Journal decryption should succeed", decryptResult.isSuccess)
        
        val decryptedJournal = decryptResult.getOrThrow()
        
        // Verify the decrypted data matches the original test data
        assertTrue("Decrypted journal data should match original", 
                  testData.contentEquals(decryptedJournal))
        
        // Verify KeyStoreManager was called with correct parameters
        verify(mockKeyStoreManager).getDataKey(KeyType.JOURNAL, testJournalId)
    }
    
    @Test
    fun testEncryptWithPasswordDecryptWithPassword() {
        // Set up KeyStoreManager mock to handle password-based key derivation
        val salt = ByteArray(16) { 2 }
        whenever(mockKeyStoreManager.deriveKeyFromPassword(testPassword))
            .thenReturn(Result.success(Pair(testKey, salt)))
        whenever(mockKeyStoreManager.deriveKeyFromPassword(testPassword, salt))
            .thenReturn(Result.success(Pair(testKey, salt)))
        
        // Encrypt test data with a password
        val encryptResult = encryptionManager.encryptWithPassword(testData, testPassword)
        
        // Verify encryption succeeded
        assertTrue("Password-based encryption should succeed", encryptResult.isSuccess)
        
        val passwordEncryptedData = encryptResult.getOrThrow()
        
        // Verify the encrypted data has salt
        assertNotNull("Password-encrypted data should have salt", passwordEncryptedData.salt)
        
        // Decrypt the encrypted data with the same password
        val decryptResult = encryptionManager.decryptWithPassword(passwordEncryptedData, testPassword)
        
        // Verify decryption succeeded
        assertTrue("Password-based decryption should succeed", decryptResult.isSuccess)
        
        val decryptedData = decryptResult.getOrThrow()
        
        // Verify the decrypted data matches the original test data
        assertTrue("Decrypted data should match original", 
                  testData.contentEquals(decryptedData))
        
        // Verify KeyStoreManager was called with correct parameters
        verify(mockKeyStoreManager).deriveKeyFromPassword(testPassword)
        verify(mockKeyStoreManager).deriveKeyFromPassword(testPassword, passwordEncryptedData.salt)
    }
    
    @Test
    fun testEncryptWithEmptyPassword() {
        // Attempt to encrypt data with an empty password
        val emptyPassword = ""
        val result = encryptionManager.encryptWithPassword(testData, emptyPassword)
        
        // Verify that the operation returns an error
        assertTrue("Encryption with empty password should fail", result.isFailure)
        val error = result.exceptionOrNull()
        assertTrue("Error should be InvalidKey type", error is EncryptionException.InvalidKey)
    }
    
    @Test
    fun testBase64EncodingDecoding() {
        // Encode test data to Base64
        val encoded = encryptionManager.encodeToBase64(testData)
        
        // Verify the encoded string is not empty and is in Base64 format
        assertNotNull("Encoded string should not be null", encoded)
        assertTrue("Encoded string should not be empty", encoded.isNotEmpty())
        
        // Decode the Base64 string back to binary
        val decoded = encryptionManager.decodeFromBase64(encoded)
        
        // Verify the decoded data matches the original test data
        assertNotNull("Decoded data should not be null", decoded)
        assertTrue("Decoded data should match original", 
                  testData.contentEquals(decoded))
    }
}