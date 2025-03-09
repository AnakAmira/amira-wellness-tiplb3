import Foundation // Latest
import Combine // Latest
import XCTest // Latest

@testable import AmiraWellness

/// A mock implementation of JournalService for testing purposes
class MockJournalService: JournalService {
    // MARK: - Singleton
    
    static let shared = MockJournalService()
    
    // MARK: - Properties
    
    // State tracking
    var currentJournalId: UUID?
    var preRecordingState: EmotionalState?
    var journals: [Journal] = []
    
    // Configurable results
    var startRecordingResult: (Result<UUID, JournalServiceError>) -> Void = { completion in
        completion(.success(UUID()))
    }
    
    var pauseRecordingResult: (Result<Void, JournalServiceError>) -> Void = { completion in
        completion(.success(()))
    }
    
    var resumeRecordingResult: (Result<Void, JournalServiceError>) -> Void = { completion in
        completion(.success(()))
    }
    
    var stopRecordingResult: (Result<Void, JournalServiceError>) -> Void = { completion in
        completion(.success(()))
    }
    
    var cancelRecordingResult: (Result<Void, JournalServiceError>) -> Void = { completion in
        completion(.success(()))
    }
    
    var saveJournalResult: (Result<Journal, JournalServiceError>) -> Void = { completion in
        completion(.success(TestData.mockJournal()))
    }
    
    var getJournalsResult: (Result<[Journal], JournalServiceError>) -> Void = { completion in
        completion(.success(TestData.mockJournalArray()))
    }
    
    var getJournalResult: (UUID) -> Result<Journal, JournalServiceError> = { journalId in
        return .success(TestData.mockJournal())
    }
    
    var updateJournalTitleResult: (UUID, String) -> Result<Journal, JournalServiceError> = { journalId, newTitle in
        return .success(TestData.mockJournal().withUpdatedTitle(newTitle: newTitle))
    }
    
    var toggleFavoriteResult: (UUID) -> Result<Journal, JournalServiceError> = { journalId in
        return .success(TestData.mockJournal().toggleFavorite())
    }
    
    var deleteJournalResult: (UUID) -> Result<Void, JournalServiceError> = { journalId in
        return .success(())
    }
    
    var playJournalResult: (UUID) -> Result<Void, JournalServiceError> = { journalId in
        return .success(())
    }
    
    var pausePlaybackResult: (Result<Void, JournalServiceError>) -> Void = { completion in
        completion(.success(()))
    }
    
    var resumePlaybackResult: (Result<Void, JournalServiceError>) -> Void = { completion in
        completion(.success(()))
    }
    
    var stopPlaybackResult: (Result<Void, JournalServiceError>) -> Void = { completion in
        completion(.success(()))
    }
    
    var exportJournalResult: (UUID, URL) -> Result<URL, JournalServiceError> = { journalId, destinationURL in
        return .success(destinationURL)
    }
    
    var syncJournalsResult: (Result<Int, JournalServiceError>) -> Void = { completion in
        completion(.success(5))
    }
    
    // Call counts
    var startRecordingCallCount = 0
    var pauseRecordingCallCount = 0
    var resumeRecordingCallCount = 0
    var stopRecordingCallCount = 0
    var cancelRecordingCallCount = 0
    var saveJournalCallCount = 0
    var getJournalsCallCount = 0
    var getJournalCallCount = 0
    var updateJournalTitleCallCount = 0
    var toggleFavoriteCallCount = 0
    var deleteJournalCallCount = 0
    var playJournalCallCount = 0
    var pausePlaybackCallCount = 0
    var resumePlaybackCallCount = 0
    var stopPlaybackCallCount = 0
    var exportJournalCallCount = 0
    var syncJournalsCallCount = 0
    
    // Publishers
    private let journalCreatedSubject = PassthroughSubject<Journal, Never>()
    private let journalUpdatedSubject = PassthroughSubject<Journal, Never>()
    private let journalDeletedSubject = PassthroughSubject<UUID, Never>()
    private let errorSubject = PassthroughSubject<JournalServiceError, Never>()
    
    // MARK: - Initializer
    
    init() {
        journals = []
        
        // Set up default getJournalResult for convenience
        getJournalResult = { [weak self] journalId in
            if let journal = self?.journals.first(where: { $0.id == journalId }) {
                return .success(journal)
            }
            return .success(TestData.mockJournal())
        }
        
        // Set up default updateJournalTitleResult
        updateJournalTitleResult = { [weak self] journalId, newTitle in
            if let index = self?.journals.firstIndex(where: { $0.id == journalId }) {
                let updatedJournal = self!.journals[index].withUpdatedTitle(newTitle: newTitle)
                self?.journals[index] = updatedJournal
                return .success(updatedJournal)
            }
            let journal = TestData.mockJournal().withUpdatedTitle(newTitle: newTitle)
            return .success(journal)
        }
        
        // Set up default toggleFavoriteResult
        toggleFavoriteResult = { [weak self] journalId in
            if let index = self?.journals.firstIndex(where: { $0.id == journalId }) {
                let updatedJournal = self!.journals[index].toggleFavorite()
                self?.journals[index] = updatedJournal
                return .success(updatedJournal)
            }
            return .success(TestData.mockJournal().toggleFavorite())
        }
        
        // Set up default deleteJournalResult
        deleteJournalResult = { [weak self] journalId in
            self?.journals.removeAll(where: { $0.id == journalId })
            return .success(())
        }
    }
    
    // MARK: - Public Methods
    
    /// Resets the mock to its initial state
    func reset() {
        currentJournalId = nil
        preRecordingState = nil
        journals = []
        
        // Reset call counts
        startRecordingCallCount = 0
        pauseRecordingCallCount = 0
        resumeRecordingCallCount = 0
        stopRecordingCallCount = 0
        cancelRecordingCallCount = 0
        saveJournalCallCount = 0
        getJournalsCallCount = 0
        getJournalCallCount = 0
        updateJournalTitleCallCount = 0
        toggleFavoriteCallCount = 0
        deleteJournalCallCount = 0
        playJournalCallCount = 0
        pausePlaybackCallCount = 0
        resumePlaybackCallCount = 0
        stopPlaybackCallCount = 0
        exportJournalCallCount = 0
        syncJournalsCallCount = 0
    }
    
    // MARK: - JournalService Protocol Implementation
    
    func startRecording(preEmotionalState: EmotionalState, completion: @escaping (Result<UUID, JournalServiceError>) -> Void) {
        startRecordingCallCount += 1
        preRecordingState = preEmotionalState
        startRecordingResult(completion)
    }
    
    @available(iOS 15.0, *)
    func startRecording(preEmotionalState: EmotionalState) async throws -> UUID {
        startRecordingCallCount += 1
        preRecordingState = preEmotionalState
        
        return try await withCheckedThrowingContinuation { continuation in
            startRecordingResult { result in
                switch result {
                case .success(let uuid):
                    continuation.resume(returning: uuid)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func pauseRecording(completion: @escaping (Result<Void, JournalServiceError>) -> Void) {
        pauseRecordingCallCount += 1
        pauseRecordingResult(completion)
    }
    
    @available(iOS 15.0, *)
    func pauseRecording() async throws {
        pauseRecordingCallCount += 1
        
        return try await withCheckedThrowingContinuation { continuation in
            pauseRecordingResult { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func resumeRecording(completion: @escaping (Result<Void, JournalServiceError>) -> Void) {
        resumeRecordingCallCount += 1
        resumeRecordingResult(completion)
    }
    
    @available(iOS 15.0, *)
    func resumeRecording() async throws {
        resumeRecordingCallCount += 1
        
        return try await withCheckedThrowingContinuation { continuation in
            resumeRecordingResult { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func stopRecording(completion: @escaping (Result<Void, JournalServiceError>) -> Void) {
        stopRecordingCallCount += 1
        stopRecordingResult(completion)
    }
    
    @available(iOS 15.0, *)
    func stopRecording() async throws {
        stopRecordingCallCount += 1
        
        return try await withCheckedThrowingContinuation { continuation in
            stopRecordingResult { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func cancelRecording(completion: @escaping (Result<Void, JournalServiceError>) -> Void) {
        cancelRecordingCallCount += 1
        currentJournalId = nil
        preRecordingState = nil
        cancelRecordingResult(completion)
    }
    
    @available(iOS 15.0, *)
    func cancelRecording() async throws {
        cancelRecordingCallCount += 1
        currentJournalId = nil
        preRecordingState = nil
        
        return try await withCheckedThrowingContinuation { continuation in
            cancelRecordingResult { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func saveJournal(title: String, postEmotionalState: EmotionalState, completion: @escaping (Result<Journal, JournalServiceError>) -> Void) {
        saveJournalCallCount += 1
        
        guard let journalId = currentJournalId, let preState = preRecordingState else {
            completion(.failure(.recordingNotFound))
            return
        }
        
        let journal = Journal(
            id: journalId,
            userId: UUID(),
            title: title,
            createdAt: Date(),
            durationSeconds: 180,
            storagePath: "journals/\(journalId.uuidString).aac",
            encryptionIv: "test-encryption-iv-base64-encoded",
            preEmotionalState: preState,
            postEmotionalState: postEmotionalState
        )
        
        journals.append(journal)
        currentJournalId = nil
        preRecordingState = nil
        
        journalCreatedSubject.send(journal)
        saveJournalResult(completion)
    }
    
    @available(iOS 15.0, *)
    func saveJournal(title: String, postEmotionalState: EmotionalState) async throws -> Journal {
        saveJournalCallCount += 1
        
        guard let journalId = currentJournalId, let preState = preRecordingState else {
            throw JournalServiceError.recordingNotFound
        }
        
        let journal = Journal(
            id: journalId,
            userId: UUID(),
            title: title,
            createdAt: Date(),
            durationSeconds: 180,
            storagePath: "journals/\(journalId.uuidString).aac",
            encryptionIv: "test-encryption-iv-base64-encoded",
            preEmotionalState: preState,
            postEmotionalState: postEmotionalState
        )
        
        journals.append(journal)
        currentJournalId = nil
        preRecordingState = nil
        
        journalCreatedSubject.send(journal)
        
        return try await withCheckedThrowingContinuation { continuation in
            saveJournalResult { result in
                switch result {
                case .success(let journal):
                    continuation.resume(returning: journal)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getJournals(completion: @escaping (Result<[Journal], JournalServiceError>) -> Void) {
        getJournalsCallCount += 1
        getJournalsResult(completion)
    }
    
    @available(iOS 15.0, *)
    func getJournals() async throws -> [Journal] {
        getJournalsCallCount += 1
        
        return try await withCheckedThrowingContinuation { continuation in
            getJournalsResult { result in
                switch result {
                case .success(let journals):
                    continuation.resume(returning: journals)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getJournal(journalId: UUID, completion: @escaping (Result<Journal, JournalServiceError>) -> Void) {
        getJournalCallCount += 1
        let result = getJournalResult(journalId)
        completion(result)
    }
    
    @available(iOS 15.0, *)
    func getJournal(journalId: UUID) async throws -> Journal {
        getJournalCallCount += 1
        let result = getJournalResult(journalId)
        
        switch result {
        case .success(let journal):
            return journal
        case .failure(let error):
            throw error
        }
    }
    
    func updateJournalTitle(journalId: UUID, newTitle: String, completion: @escaping (Result<Journal, JournalServiceError>) -> Void) {
        updateJournalTitleCallCount += 1
        let result = updateJournalTitleResult(journalId, newTitle)
        
        if case .success(let journal) = result {
            journalUpdatedSubject.send(journal)
        }
        
        completion(result)
    }
    
    @available(iOS 15.0, *)
    func updateJournalTitle(journalId: UUID, newTitle: String) async throws -> Journal {
        updateJournalTitleCallCount += 1
        let result = updateJournalTitleResult(journalId, newTitle)
        
        switch result {
        case .success(let journal):
            journalUpdatedSubject.send(journal)
            return journal
        case .failure(let error):
            throw error
        }
    }
    
    func toggleFavorite(journalId: UUID, completion: @escaping (Result<Journal, JournalServiceError>) -> Void) {
        toggleFavoriteCallCount += 1
        let result = toggleFavoriteResult(journalId)
        
        if case .success(let journal) = result {
            journalUpdatedSubject.send(journal)
        }
        
        completion(result)
    }
    
    @available(iOS 15.0, *)
    func toggleFavorite(journalId: UUID) async throws -> Journal {
        toggleFavoriteCallCount += 1
        let result = toggleFavoriteResult(journalId)
        
        switch result {
        case .success(let journal):
            journalUpdatedSubject.send(journal)
            return journal
        case .failure(let error):
            throw error
        }
    }
    
    func deleteJournal(journalId: UUID, completion: @escaping (Result<Void, JournalServiceError>) -> Void) {
        deleteJournalCallCount += 1
        let result = deleteJournalResult(journalId)
        
        if case .success = result {
            journalDeletedSubject.send(journalId)
        }
        
        completion(result)
    }
    
    @available(iOS 15.0, *)
    func deleteJournal(journalId: UUID) async throws {
        deleteJournalCallCount += 1
        let result = deleteJournalResult(journalId)
        
        switch result {
        case .success:
            journalDeletedSubject.send(journalId)
            return
        case .failure(let error):
            throw error
        }
    }
    
    func playJournal(journalId: UUID, completion: @escaping (Result<Void, JournalServiceError>) -> Void) {
        playJournalCallCount += 1
        let result = playJournalResult(journalId)
        completion(result)
    }
    
    @available(iOS 15.0, *)
    func playJournal(journalId: UUID) async throws {
        playJournalCallCount += 1
        let result = playJournalResult(journalId)
        
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func pausePlayback(completion: @escaping (Result<Void, JournalServiceError>) -> Void) {
        pausePlaybackCallCount += 1
        pausePlaybackResult(completion)
    }
    
    @available(iOS 15.0, *)
    func pausePlayback() async throws {
        pausePlaybackCallCount += 1
        
        return try await withCheckedThrowingContinuation { continuation in
            pausePlaybackResult { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func resumePlayback(completion: @escaping (Result<Void, JournalServiceError>) -> Void) {
        resumePlaybackCallCount += 1
        resumePlaybackResult(completion)
    }
    
    @available(iOS 15.0, *)
    func resumePlayback() async throws {
        resumePlaybackCallCount += 1
        
        return try await withCheckedThrowingContinuation { continuation in
            resumePlaybackResult { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func stopPlayback(completion: @escaping (Result<Void, JournalServiceError>) -> Void) {
        stopPlaybackCallCount += 1
        stopPlaybackResult(completion)
    }
    
    @available(iOS 15.0, *)
    func stopPlayback() async throws {
        stopPlaybackCallCount += 1
        
        return try await withCheckedThrowingContinuation { continuation in
            stopPlaybackResult { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func exportJournal(journalId: UUID, destinationURL: URL, completion: @escaping (Result<URL, JournalServiceError>) -> Void) {
        exportJournalCallCount += 1
        let result = exportJournalResult(journalId, destinationURL)
        completion(result)
    }
    
    @available(iOS 15.0, *)
    func exportJournal(journalId: UUID, destinationURL: URL) async throws -> URL {
        exportJournalCallCount += 1
        let result = exportJournalResult(journalId, destinationURL)
        
        switch result {
        case .success(let url):
            return url
        case .failure(let error):
            throw error
        }
    }
    
    func syncJournals(completion: @escaping (Result<Int, JournalServiceError>) -> Void) {
        syncJournalsCallCount += 1
        syncJournalsResult(completion)
    }
    
    @available(iOS 15.0, *)
    func syncJournals() async throws -> Int {
        syncJournalsCallCount += 1
        
        return try await withCheckedThrowingContinuation { continuation in
            syncJournalsResult { result in
                switch result {
                case .success(let count):
                    continuation.resume(returning: count)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Publishers
    
    func journalCreatedPublisher() -> AnyPublisher<Journal, Never> {
        return journalCreatedSubject.eraseToAnyPublisher()
    }
    
    func journalUpdatedPublisher() -> AnyPublisher<Journal, Never> {
        return journalUpdatedSubject.eraseToAnyPublisher()
    }
    
    func journalDeletedPublisher() -> AnyPublisher<UUID, Never> {
        return journalDeletedSubject.eraseToAnyPublisher()
    }
    
    func errorPublisher() -> AnyPublisher<JournalServiceError, Never> {
        return errorSubject.eraseToAnyPublisher()
    }
}