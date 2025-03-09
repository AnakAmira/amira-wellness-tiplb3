import XCTest
import Foundation
import Journal
import EmotionalState
import TestData

final class JournalTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Setup code if needed before each test
    }
    
    override func tearDown() {
        // Clean up code if needed after each test
        super.tearDown()
    }
    
    // MARK: - Journal Tests
    
    func testJournalInitialization() {
        // Create test data
        let id = UUID()
        let userId = UUID()
        let title = "Test Journal"
        let createdAt = Date()
        let updatedAt = Date().addingTimeInterval(3600) // 1 hour later
        let durationSeconds = 180 // 3 minutes
        let isFavorite = true
        let isUploaded = false
        let storagePath = "journals/test.aac"
        let encryptionIv = "test-encryption-iv"
        let preEmotionalState = TestData.mockEmotionalState(emotionType: .joy, intensity: 5)
        let postEmotionalState = TestData.mockEmotionalState(emotionType: .calm, intensity: 8)
        let audioMetadata = TestData.createTestAudioMetadata()
        let localFileUrl = URL(string: "file:///test/journals/test.aac")
        
        // Initialize Journal
        let journal = Journal(
            id: id,
            userId: userId,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            durationSeconds: durationSeconds,
            isFavorite: isFavorite,
            isUploaded: isUploaded,
            storagePath: storagePath,
            encryptionIv: encryptionIv,
            preEmotionalState: preEmotionalState,
            postEmotionalState: postEmotionalState,
            audioMetadata: audioMetadata,
            localFileUrl: localFileUrl
        )
        
        // Verify all properties were set correctly
        XCTAssertEqual(journal.id, id)
        XCTAssertEqual(journal.userId, userId)
        XCTAssertEqual(journal.title, title)
        XCTAssertEqual(journal.createdAt, createdAt)
        XCTAssertEqual(journal.updatedAt, updatedAt)
        XCTAssertEqual(journal.durationSeconds, durationSeconds)
        XCTAssertEqual(journal.isFavorite, isFavorite)
        XCTAssertEqual(journal.isUploaded, isUploaded)
        XCTAssertEqual(journal.storagePath, storagePath)
        XCTAssertEqual(journal.encryptionIv, encryptionIv)
        XCTAssertEqual(journal.preEmotionalState, preEmotionalState)
        XCTAssertEqual(journal.postEmotionalState, postEmotionalState)
        XCTAssertEqual(journal.audioMetadata, audioMetadata)
        XCTAssertEqual(journal.localFileUrl, localFileUrl)
    }
    
    func testJournalEquality() {
        // Create two identical journals
        let journal1 = TestData.mockJournal()
        let journal2 = Journal(
            id: journal1.id,
            userId: journal1.userId,
            title: journal1.title,
            createdAt: journal1.createdAt,
            updatedAt: journal1.updatedAt,
            durationSeconds: journal1.durationSeconds,
            isFavorite: journal1.isFavorite,
            isUploaded: journal1.isUploaded,
            storagePath: journal1.storagePath,
            encryptionIv: journal1.encryptionIv,
            preEmotionalState: journal1.preEmotionalState,
            postEmotionalState: journal1.postEmotionalState,
            audioMetadata: journal1.audioMetadata,
            localFileUrl: journal1.localFileUrl
        )
        
        // Create a different journal
        let journal3 = TestData.mockJournal(withPostEmotionalState: false)
        
        // Test equality
        XCTAssertEqual(journal1, journal2)
        XCTAssertNotEqual(journal1, journal3)
    }
    
    func testJournalCodable() {
        let originalJournal = TestData.mockJournal()
        
        do {
            // Encode to JSON
            let encoder = JSONEncoder()
            let journalData = try encoder.encode(originalJournal)
            
            // Decode from JSON
            let decoder = JSONDecoder()
            let decodedJournal = try decoder.decode(Journal.self, from: journalData)
            
            // Verify decoded journal matches original
            XCTAssertEqual(originalJournal, decodedJournal)
        } catch {
            XCTFail("Codable test failed with error: \(error)")
        }
    }
    
    func testFormattedDuration() {
        // Test with 65 seconds (1:05)
        let journal1 = TestData.mockJournal()
        let journalWithCustomDuration = Journal(
            id: journal1.id,
            userId: journal1.userId,
            title: journal1.title,
            createdAt: journal1.createdAt,
            durationSeconds: 65,
            storagePath: journal1.storagePath,
            encryptionIv: journal1.encryptionIv,
            preEmotionalState: journal1.preEmotionalState
        )
        XCTAssertEqual(journalWithCustomDuration.formattedDuration(), "01:05")
        
        // Test with 3661 seconds (61:01)
        let journalWithLongDuration = Journal(
            id: journal1.id,
            userId: journal1.userId,
            title: journal1.title,
            createdAt: journal1.createdAt,
            durationSeconds: 3661,
            storagePath: journal1.storagePath,
            encryptionIv: journal1.encryptionIv,
            preEmotionalState: journal1.preEmotionalState
        )
        XCTAssertEqual(journalWithLongDuration.formattedDuration(), "61:01")
    }
    
    func testFormattedDate() {
        // Create a journal with a known date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let knownDate = dateFormatter.date(from: "2023-01-01 10:30:00")!
        
        let journal = TestData.mockJournal()
        let journalWithKnownDate = Journal(
            id: journal.id,
            userId: journal.userId,
            title: journal.title,
            createdAt: knownDate,
            durationSeconds: journal.durationSeconds,
            storagePath: journal.storagePath,
            encryptionIv: journal.encryptionIv,
            preEmotionalState: journal.preEmotionalState
        )
        
        // Format the date using the same formatter the app would use
        let expectedFormatter = DateFormatter()
        expectedFormatter.dateStyle = .medium
        expectedFormatter.timeStyle = .short
        let expectedFormattedDate = expectedFormatter.string(from: knownDate)
        
        XCTAssertEqual(journalWithKnownDate.formattedDate(), expectedFormattedDate)
    }
    
    func testGetEmotionalShift() {
        // Create a journal with pre and post emotional states
        let preEmotionalState = TestData.mockEmotionalState(emotionType: .joy, intensity: 5)
        let postEmotionalState = TestData.mockEmotionalState(emotionType: .calm, intensity: 8)
        
        let journal = TestData.mockJournal()
        let journalWithSpecificEmotions = Journal(
            id: journal.id,
            userId: journal.userId,
            title: journal.title,
            createdAt: journal.createdAt,
            durationSeconds: journal.durationSeconds,
            storagePath: journal.storagePath,
            encryptionIv: journal.encryptionIv,
            preEmotionalState: preEmotionalState,
            postEmotionalState: postEmotionalState
        )
        
        // Get emotional shift
        let shift = journalWithSpecificEmotions.getEmotionalShift()
        
        // Verify shift details
        XCTAssertNotNil(shift)
        XCTAssertEqual(shift?.preEmotionalState, preEmotionalState)
        XCTAssertEqual(shift?.postEmotionalState, postEmotionalState)
        XCTAssertEqual(shift?.primaryShift, .calm) // Shift from joy to calm
        XCTAssertEqual(shift?.intensityChange, 3) // From 5 to 8
        
        // Test with a journal without post emotional state
        let journalWithoutPostEmotion = Journal(
            id: journal.id,
            userId: journal.userId,
            title: journal.title,
            createdAt: journal.createdAt,
            durationSeconds: journal.durationSeconds,
            storagePath: journal.storagePath,
            encryptionIv: journal.encryptionIv,
            preEmotionalState: preEmotionalState
        )
        
        // Should return nil if no post emotional state
        XCTAssertNil(journalWithoutPostEmotion.getEmotionalShift())
    }
    
    func testToggleFavorite() {
        // Create a journal that is not favorited
        let journal = TestData.mockJournal(isFavorite: false)
        
        // Toggle favorite status (should become true)
        let newStatus = journal.toggleFavorite()
        XCTAssertTrue(newStatus)
        
        // Create a journal that is favorited
        let favoritedJournal = TestData.mockJournal(isFavorite: true)
        
        // Toggle favorite status (should become false)
        let newStatusForFavorited = favoritedJournal.toggleFavorite()
        XCTAssertFalse(newStatusForFavorited)
    }
    
    func testNeedsUpload() {
        // Create a journal that is not uploaded
        let journal = TestData.mockJournal()
        let notUploadedJournal = Journal(
            id: journal.id,
            userId: journal.userId,
            title: journal.title,
            createdAt: journal.createdAt,
            durationSeconds: journal.durationSeconds,
            isUploaded: false,
            storagePath: journal.storagePath,
            encryptionIv: journal.encryptionIv,
            preEmotionalState: journal.preEmotionalState
        )
        
        // Should need upload
        XCTAssertTrue(notUploadedJournal.needsUpload())
        
        // Create a journal that is uploaded
        let uploadedJournal = Journal(
            id: journal.id,
            userId: journal.userId,
            title: journal.title,
            createdAt: journal.createdAt,
            durationSeconds: journal.durationSeconds,
            isUploaded: true,
            storagePath: journal.storagePath,
            encryptionIv: journal.encryptionIv,
            preEmotionalState: journal.preEmotionalState
        )
        
        // Should not need upload
        XCTAssertFalse(uploadedJournal.needsUpload())
    }
    
    func testWithUpdatedEmotionalState() {
        // Create a journal without post emotional state
        let journal = TestData.mockJournal(withPostEmotionalState: false)
        
        // Create a new emotional state
        let newEmotionalState = TestData.mockEmotionalState(emotionType: .calm, intensity: 7)
        
        // Update the journal with the new emotional state
        let updatedJournal = journal.withUpdatedEmotionalState(postState: newEmotionalState)
        
        // Verify that a new instance was returned
        XCTAssertNotEqual(journal, updatedJournal)
        
        // Verify that the new instance has the updated state
        XCTAssertEqual(updatedJournal.postEmotionalState, newEmotionalState)
        
        // Verify that the updatedAt date was set
        XCTAssertNotNil(updatedJournal.updatedAt)
        XCTAssertGreaterThan(updatedJournal.updatedAt ?? Date.distantPast, journal.updatedAt ?? Date.distantPast)
        
        // Verify that other properties weren't changed
        XCTAssertEqual(updatedJournal.id, journal.id)
        XCTAssertEqual(updatedJournal.title, journal.title)
        XCTAssertEqual(updatedJournal.createdAt, journal.createdAt)
        XCTAssertEqual(updatedJournal.durationSeconds, journal.durationSeconds)
    }
    
    func testWithUpdatedTitle() {
        // Create a journal
        let journal = TestData.mockJournal()
        
        // Update the journal with a new title
        let newTitle = "Updated Title"
        let updatedJournal = journal.withUpdatedTitle(newTitle: newTitle)
        
        // Verify that a new instance was returned
        XCTAssertNotEqual(journal, updatedJournal)
        
        // Verify that the new instance has the updated title
        XCTAssertEqual(updatedJournal.title, newTitle)
        
        // Verify that the updatedAt date was set
        XCTAssertNotNil(updatedJournal.updatedAt)
        XCTAssertGreaterThan(updatedJournal.updatedAt ?? Date.distantPast, journal.updatedAt ?? Date.distantPast)
        
        // Verify that other properties weren't changed
        XCTAssertEqual(updatedJournal.id, journal.id)
        XCTAssertEqual(updatedJournal.createdAt, journal.createdAt)
        XCTAssertEqual(updatedJournal.durationSeconds, journal.durationSeconds)
    }
    
    func testWithUpdatedMetadata() {
        // Create a journal
        let journal = TestData.mockJournal()
        
        // Create new audio metadata
        let newMetadata = AudioMetadata(
            fileFormat: "MP3",
            fileSizeBytes: 2_000_000,
            sampleRate: 48000.0,
            bitRate: 256000,
            channels: 2,
            checksum: "new-checksum"
        )
        
        // Update the journal with the new metadata
        let updatedJournal = journal.withUpdatedMetadata(metadata: newMetadata)
        
        // Verify that a new instance was returned
        XCTAssertNotEqual(journal, updatedJournal)
        
        // Verify that the new instance has the updated metadata
        XCTAssertEqual(updatedJournal.audioMetadata, newMetadata)
        
        // Verify that the updatedAt date was set
        XCTAssertNotNil(updatedJournal.updatedAt)
        XCTAssertGreaterThan(updatedJournal.updatedAt ?? Date.distantPast, journal.updatedAt ?? Date.distantPast)
        
        // Verify that other properties weren't changed
        XCTAssertEqual(updatedJournal.id, journal.id)
        XCTAssertEqual(updatedJournal.title, journal.title)
        XCTAssertEqual(updatedJournal.createdAt, journal.createdAt)
        XCTAssertEqual(updatedJournal.durationSeconds, journal.durationSeconds)
    }
    
    func testWithUploadStatus() {
        // Create a journal that is not uploaded
        let journal = TestData.mockJournal()
        let notUploadedJournal = Journal(
            id: journal.id,
            userId: journal.userId,
            title: journal.title,
            createdAt: journal.createdAt,
            durationSeconds: journal.durationSeconds,
            isUploaded: false,
            storagePath: journal.storagePath,
            encryptionIv: journal.encryptionIv,
            preEmotionalState: journal.preEmotionalState
        )
        
        // Update the journal with uploaded status
        let updatedJournal = notUploadedJournal.withUploadStatus(uploaded: true)
        
        // Verify that a new instance was returned
        XCTAssertNotEqual(notUploadedJournal, updatedJournal)
        
        // Verify that the new instance has the updated upload status
        XCTAssertTrue(updatedJournal.isUploaded)
        
        // Verify that the updatedAt date was set
        XCTAssertNotNil(updatedJournal.updatedAt)
        XCTAssertGreaterThan(updatedJournal.updatedAt ?? Date.distantPast, notUploadedJournal.updatedAt ?? Date.distantPast)
        
        // Verify that other properties weren't changed
        XCTAssertEqual(updatedJournal.id, notUploadedJournal.id)
        XCTAssertEqual(updatedJournal.title, notUploadedJournal.title)
        XCTAssertEqual(updatedJournal.createdAt, notUploadedJournal.createdAt)
        XCTAssertEqual(updatedJournal.durationSeconds, notUploadedJournal.durationSeconds)
    }
    
    // MARK: - AudioMetadata Tests
    
    func testAudioMetadataInitialization() {
        // Create audio metadata
        let fileFormat = "AAC"
        let fileSizeBytes = 1_500_000
        let sampleRate = 44100.0
        let bitRate = 128000
        let channels = 1
        let checksum = "test-checksum"
        
        let metadata = AudioMetadata(
            fileFormat: fileFormat,
            fileSizeBytes: fileSizeBytes,
            sampleRate: sampleRate,
            bitRate: bitRate,
            channels: channels,
            checksum: checksum
        )
        
        // Verify all properties were set correctly
        XCTAssertEqual(metadata.fileFormat, fileFormat)
        XCTAssertEqual(metadata.fileSizeBytes, fileSizeBytes)
        XCTAssertEqual(metadata.sampleRate, sampleRate)
        XCTAssertEqual(metadata.bitRate, bitRate)
        XCTAssertEqual(metadata.channels, channels)
        XCTAssertEqual(metadata.checksum, checksum)
    }
    
    func testAudioMetadataEquality() {
        // Create two identical metadata objects
        let metadata1 = AudioMetadata(
            fileFormat: "AAC",
            fileSizeBytes: 1_500_000,
            sampleRate: 44100.0,
            bitRate: 128000,
            channels: 1,
            checksum: "test-checksum"
        )
        
        let metadata2 = AudioMetadata(
            fileFormat: "AAC",
            fileSizeBytes: 1_500_000,
            sampleRate: 44100.0,
            bitRate: 128000,
            channels: 1,
            checksum: "test-checksum"
        )
        
        // Create a different metadata object
        let metadata3 = AudioMetadata(
            fileFormat: "MP3",
            fileSizeBytes: 2_000_000,
            sampleRate: 48000.0,
            bitRate: 256000,
            channels: 2,
            checksum: "different-checksum"
        )
        
        // Test equality
        XCTAssertEqual(metadata1, metadata2)
        XCTAssertNotEqual(metadata1, metadata3)
    }
    
    func testAudioMetadataCodable() {
        let originalMetadata = AudioMetadata(
            fileFormat: "AAC",
            fileSizeBytes: 1_500_000,
            sampleRate: 44100.0,
            bitRate: 128000,
            channels: 1,
            checksum: "test-checksum"
        )
        
        do {
            // Encode to JSON
            let encoder = JSONEncoder()
            let metadataData = try encoder.encode(originalMetadata)
            
            // Decode from JSON
            let decoder = JSONDecoder()
            let decodedMetadata = try decoder.decode(AudioMetadata.self, from: metadataData)
            
            // Verify decoded metadata matches original
            XCTAssertEqual(originalMetadata, decodedMetadata)
        } catch {
            XCTFail("Codable test failed with error: \(error)")
        }
    }
    
    func testFormattedFileSize() {
        // Test KB formatting (1 KB)
        let metadata1 = AudioMetadata(
            fileFormat: "AAC",
            fileSizeBytes: 1024,
            sampleRate: 44100.0,
            bitRate: 128000,
            channels: 1,
            checksum: "test-checksum"
        )
        XCTAssertEqual(metadata1.formattedFileSize(), "1.0 KB")
        
        // Test MB formatting (1 MB)
        let metadata2 = AudioMetadata(
            fileFormat: "AAC",
            fileSizeBytes: 1024 * 1024,
            sampleRate: 44100.0,
            bitRate: 128000,
            channels: 1,
            checksum: "test-checksum"
        )
        XCTAssertEqual(metadata2.formattedFileSize(), "1.0 MB")
        
        // Test GB formatting (1 GB)
        let metadata3 = AudioMetadata(
            fileFormat: "AAC",
            fileSizeBytes: 1024 * 1024 * 1024,
            sampleRate: 44100.0,
            bitRate: 128000,
            channels: 1,
            checksum: "test-checksum"
        )
        XCTAssertEqual(metadata3.formattedFileSize(), "1.0 GB")
    }
    
    // MARK: - EmotionalShift Tests
    
    func testEmotionalShiftInitialization() {
        // Create emotional states
        let preEmotionalState = TestData.mockEmotionalState(emotionType: .joy, intensity: 5)
        let postEmotionalState = TestData.mockEmotionalState(emotionType: .calm, intensity: 8)
        
        // Create emotional shift
        let shift = EmotionalShift(
            preEmotionalState: preEmotionalState,
            postEmotionalState: postEmotionalState
        )
        
        // Verify properties
        XCTAssertEqual(shift.preEmotionalState, preEmotionalState)
        XCTAssertEqual(shift.postEmotionalState, postEmotionalState)
        XCTAssertEqual(shift.primaryShift, .calm) // Should be post emotion since different types
        XCTAssertEqual(shift.intensityChange, 3) // From 5 to 8
        XCTAssertFalse(shift.insights.isEmpty) // Should generate insights
    }
    
    func testEmotionalShiftEquality() {
        // Create emotional states
        let preEmotionalState1 = TestData.mockEmotionalState(emotionType: .joy, intensity: 5)
        let postEmotionalState1 = TestData.mockEmotionalState(emotionType: .calm, intensity: 8)
        
        // Create identical emotional shifts
        let shift1 = EmotionalShift(
            preEmotionalState: preEmotionalState1,
            postEmotionalState: postEmotionalState1
        )
        
        let shift2 = EmotionalShift(
            preEmotionalState: preEmotionalState1,
            postEmotionalState: postEmotionalState1
        )
        
        // Create a different emotional shift
        let preEmotionalState2 = TestData.mockEmotionalState(emotionType: .anxiety, intensity: 7)
        let postEmotionalState2 = TestData.mockEmotionalState(emotionType: .joy, intensity: 6)
        
        let shift3 = EmotionalShift(
            preEmotionalState: preEmotionalState2,
            postEmotionalState: postEmotionalState2
        )
        
        // Test equality
        XCTAssertEqual(shift1, shift2)
        XCTAssertNotEqual(shift1, shift3)
    }
    
    func testEmotionalShiftCodable() {
        // Create emotional states
        let preEmotionalState = TestData.mockEmotionalState(emotionType: .joy, intensity: 5)
        let postEmotionalState = TestData.mockEmotionalState(emotionType: .calm, intensity: 8)
        
        // Create emotional shift
        let originalShift = EmotionalShift(
            preEmotionalState: preEmotionalState,
            postEmotionalState: postEmotionalState
        )
        
        do {
            // Encode to JSON
            let encoder = JSONEncoder()
            let shiftData = try encoder.encode(originalShift)
            
            // Decode from JSON
            let decoder = JSONDecoder()
            let decodedShift = try decoder.decode(EmotionalShift.self, from: shiftData)
            
            // Verify decoded shift matches original
            XCTAssertEqual(originalShift, decodedShift)
        } catch {
            XCTFail("Codable test failed with error: \(error)")
        }
    }
    
    func testIsPositive() {
        // Positive shift: Anxiety (negative) to Calm (positive) with higher intensity
        let preState1 = TestData.mockEmotionalState(emotionType: .anxiety, intensity: 8)
        let postState1 = TestData.mockEmotionalState(emotionType: .calm, intensity: 9)
        let shift1 = EmotionalShift(preEmotionalState: preState1, postEmotionalState: postState1)
        XCTAssertTrue(shift1.isPositive())
        
        // Positive shift: Joy (positive) with increased intensity
        let preState2 = TestData.mockEmotionalState(emotionType: .joy, intensity: 5)
        let postState2 = TestData.mockEmotionalState(emotionType: .joy, intensity: 8)
        let shift2 = EmotionalShift(preEmotionalState: preState2, postEmotionalState: postState2)
        XCTAssertTrue(shift2.isPositive())
        
        // Not positive: Calm (positive) to Anxiety (negative)
        let preState3 = TestData.mockEmotionalState(emotionType: .calm, intensity: 7)
        let postState3 = TestData.mockEmotionalState(emotionType: .anxiety, intensity: 5)
        let shift3 = EmotionalShift(preEmotionalState: preState3, postEmotionalState: postState3)
        XCTAssertFalse(shift3.isPositive())
    }
    
    func testIsNegative() {
        // Negative shift: Calm (positive) to Anxiety (negative)
        let preState1 = TestData.mockEmotionalState(emotionType: .calm, intensity: 7)
        let postState1 = TestData.mockEmotionalState(emotionType: .anxiety, intensity: 5)
        let shift1 = EmotionalShift(preEmotionalState: preState1, postEmotionalState: postState1)
        XCTAssertTrue(shift1.isNegative())
        
        // Negative shift: Joy (positive) with decreased intensity
        let preState2 = TestData.mockEmotionalState(emotionType: .joy, intensity: 8)
        let postState2 = TestData.mockEmotionalState(emotionType: .joy, intensity: 5)
        let shift2 = EmotionalShift(preEmotionalState: preState2, postEmotionalState: postState2)
        XCTAssertTrue(shift2.isNegative())
        
        // Not negative: Anxiety (negative) to Calm (positive)
        let preState3 = TestData.mockEmotionalState(emotionType: .anxiety, intensity: 8)
        let postState3 = TestData.mockEmotionalState(emotionType: .calm, intensity: 6)
        let shift3 = EmotionalShift(preEmotionalState: preState3, postEmotionalState: postState3)
        XCTAssertFalse(shift3.isNegative())
    }
    
    func testIsNeutral() {
        // Neutral shift: Same emotion, same intensity
        let preState1 = TestData.mockEmotionalState(emotionType: .calm, intensity: 7)
        let postState1 = TestData.mockEmotionalState(emotionType: .calm, intensity: 7)
        let shift1 = EmotionalShift(preEmotionalState: preState1, postEmotionalState: postState1)
        XCTAssertTrue(shift1.isNeutral())
        
        // Neutral shift: Different positive emotions but similar intensity
        let preState2 = TestData.mockEmotionalState(emotionType: .joy, intensity: 6)
        let postState2 = TestData.mockEmotionalState(emotionType: .contentment, intensity: 6)
        let shift2 = EmotionalShift(preEmotionalState: preState2, postEmotionalState: postState2)
        XCTAssertTrue(shift2.isNeutral())
        
        // Not neutral: Significant change in emotion or intensity
        let preState3 = TestData.mockEmotionalState(emotionType: .anxiety, intensity: 8)
        let postState3 = TestData.mockEmotionalState(emotionType: .calm, intensity: 6)
        let shift3 = EmotionalShift(preEmotionalState: preState3, postEmotionalState: postState3)
        XCTAssertFalse(shift3.isNeutral())
    }
    
    func testGenerateInsights() {
        // Create a shift from anxiety to calm
        let preState = TestData.mockEmotionalState(emotionType: .anxiety, intensity: 8)
        let postState = TestData.mockEmotionalState(emotionType: .calm, intensity: 6)
        let shift = EmotionalShift(preEmotionalState: preState, postEmotionalState: postState)
        
        // Generate insights
        let insights = shift.generateInsights()
        
        // Verify insights were generated
        XCTAssertFalse(insights.isEmpty)
        
        // Verify insights contain relevant content about the shift from anxiety to calm
        let insightsText = insights.joined(separator: " ")
        XCTAssertTrue(insightsText.contains("ansiedad") || insightsText.contains("anxiety"), "Insights should mention the pre-emotion")
        XCTAssertTrue(insightsText.contains("calma") || insightsText.contains("calm"), "Insights should mention the post-emotion")
    }
}