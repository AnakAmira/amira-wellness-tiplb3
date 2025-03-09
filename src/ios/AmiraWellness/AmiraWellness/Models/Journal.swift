import Foundation // standard library

/// Structure representing metadata for an audio recording
struct AudioMetadata: Codable, Equatable {
    let fileFormat: String
    let fileSizeBytes: Int
    let sampleRate: Double
    let bitRate: Int
    let channels: Int
    let checksum: String
    
    /// Initializes an AudioMetadata instance with the provided parameters
    init(fileFormat: String, fileSizeBytes: Int, sampleRate: Double, bitRate: Int, channels: Int, checksum: String) {
        self.fileFormat = fileFormat
        self.fileSizeBytes = fileSizeBytes
        self.sampleRate = sampleRate
        self.bitRate = bitRate
        self.channels = channels
        self.checksum = checksum
    }
    
    /// Returns a human-readable string representation of the file size
    func formattedFileSize() -> String {
        let kb = Double(fileSizeBytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.1f MB", mb)
        }
    }
}

/// Structure representing the emotional change between pre and post journaling states
struct EmotionalShift: Codable, Equatable {
    let preEmotionalState: EmotionalState
    let postEmotionalState: EmotionalState
    let primaryShift: EmotionType
    let intensityChange: Int
    let insights: [String]
    
    /// Initializes an EmotionalShift instance with the provided parameters
    init(preEmotionalState: EmotionalState, postEmotionalState: EmotionalState) {
        self.preEmotionalState = preEmotionalState
        self.postEmotionalState = postEmotionalState
        
        // Calculate the primary shift by comparing emotion types
        if preEmotionalState.emotionType != postEmotionalState.emotionType {
            self.primaryShift = postEmotionalState.emotionType
        } else {
            self.primaryShift = preEmotionalState.emotionType
        }
        
        // Calculate intensity change
        self.intensityChange = postEmotionalState.intensity - preEmotionalState.intensity
        
        // Generate insights based on the emotional shift
        self.insights = generateInsights()
    }
    
    /// Determines if the emotional shift is positive
    func isPositive() -> Bool {
        let postCategory = postEmotionalState.emotionType.category()
        return intensityChange > 0 && postCategory == .positive
    }
    
    /// Determines if the emotional shift is negative
    func isNegative() -> Bool {
        let postCategory = postEmotionalState.emotionType.category()
        return intensityChange < 0 || postCategory == .negative
    }
    
    /// Determines if the emotional shift is neutral
    func isNeutral() -> Bool {
        return abs(intensityChange) <= 1 && preEmotionalState.emotionType == postEmotionalState.emotionType
    }
    
    /// Generates insights based on the emotional shift
    func generateInsights() -> [String] {
        var insightList: [String] = []
        
        // Add insights based on the emotional shift pattern
        let (emotionChanged, _) = preEmotionalState.compareWith(postEmotionalState)
        
        if emotionChanged {
            insightList.append(NSLocalizedString("Tu emoción cambió de \(preEmotionalState.emotionType.displayName()) a \(postEmotionalState.emotionType.displayName()).", comment: "Emotion change insight"))
        }
        
        if intensityChange > 0 {
            insightList.append(NSLocalizedString("La intensidad de tu emoción aumentó en \(abs(intensityChange)) puntos.", comment: "Intensity increase insight"))
        } else if intensityChange < 0 {
            insightList.append(NSLocalizedString("La intensidad de tu emoción disminuyó en \(abs(intensityChange)) puntos.", comment: "Intensity decrease insight"))
        } else {
            insightList.append(NSLocalizedString("La intensidad de tu emoción se mantuvo estable.", comment: "Intensity stable insight"))
        }
        
        // Add pattern-specific insights
        if isPositive() {
            insightList.append(NSLocalizedString("Tus emociones se movieron en una dirección positiva.", comment: "Positive direction insight"))
        } else if isNegative() {
            insightList.append(NSLocalizedString("Registrar tus emociones es un paso importante, incluso cuando son difíciles.", comment: "Negative emotion coping insight"))
        }
        
        return insightList
    }
}

/// Structure representing a voice journal entry in the Amira Wellness application
struct Journal: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID?
    let title: String
    let createdAt: Date
    let updatedAt: Date?
    let durationSeconds: Int
    let isFavorite: Bool
    let isUploaded: Bool
    let storagePath: String
    let encryptionIv: String
    let preEmotionalState: EmotionalState
    let postEmotionalState: EmotionalState?
    let audioMetadata: AudioMetadata?
    let localFileUrl: URL?
    
    /// Initializes a Journal instance with the provided parameters
    init(
        id: UUID,
        userId: UUID? = nil,
        title: String,
        createdAt: Date,
        updatedAt: Date? = nil,
        durationSeconds: Int,
        isFavorite: Bool = false,
        isUploaded: Bool = false,
        storagePath: String,
        encryptionIv: String,
        preEmotionalState: EmotionalState,
        postEmotionalState: EmotionalState? = nil,
        audioMetadata: AudioMetadata? = nil,
        localFileUrl: URL? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.durationSeconds = durationSeconds
        self.isFavorite = isFavorite
        self.isUploaded = isUploaded
        self.storagePath = storagePath
        self.encryptionIv = encryptionIv
        self.preEmotionalState = preEmotionalState
        self.postEmotionalState = postEmotionalState
        self.audioMetadata = audioMetadata
        self.localFileUrl = localFileUrl
    }
    
    /// Returns a formatted string representation of the journal duration
    func formattedDuration() -> String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Returns a formatted string representation of the creation date
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    /// Calculates and returns the emotional shift between pre and post states
    func getEmotionalShift() -> EmotionalShift? {
        guard let postEmotionalState = postEmotionalState else {
            return nil
        }
        
        return EmotionalShift(preEmotionalState: preEmotionalState, postEmotionalState: postEmotionalState)
    }
    
    /// Toggles the favorite status of the journal
    func toggleFavorite() -> Bool {
        return !isFavorite
    }
    
    /// Determines if the journal needs to be uploaded to the server
    func needsUpload() -> Bool {
        return !isUploaded
    }
    
    /// Creates a new journal with updated post-emotional state
    func withUpdatedEmotionalState(postState: EmotionalState) -> Journal {
        return Journal(
            id: id,
            userId: userId,
            title: title,
            createdAt: createdAt,
            updatedAt: Date(),
            durationSeconds: durationSeconds,
            isFavorite: isFavorite,
            isUploaded: isUploaded,
            storagePath: storagePath,
            encryptionIv: encryptionIv,
            preEmotionalState: preEmotionalState,
            postEmotionalState: postState,
            audioMetadata: audioMetadata,
            localFileUrl: localFileUrl
        )
    }
    
    /// Creates a new journal with updated title
    func withUpdatedTitle(newTitle: String) -> Journal {
        return Journal(
            id: id,
            userId: userId,
            title: newTitle,
            createdAt: createdAt,
            updatedAt: Date(),
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
    }
    
    /// Creates a new journal with updated audio metadata
    func withUpdatedMetadata(metadata: AudioMetadata) -> Journal {
        return Journal(
            id: id,
            userId: userId,
            title: title,
            createdAt: createdAt,
            updatedAt: Date(),
            durationSeconds: durationSeconds,
            isFavorite: isFavorite,
            isUploaded: isUploaded,
            storagePath: storagePath,
            encryptionIv: encryptionIv,
            preEmotionalState: preEmotionalState,
            postEmotionalState: postEmotionalState,
            audioMetadata: metadata,
            localFileUrl: localFileUrl
        )
    }
    
    /// Creates a new journal with updated upload status
    func withUploadStatus(uploaded: Bool) -> Journal {
        return Journal(
            id: id,
            userId: userId,
            title: title,
            createdAt: createdAt,
            updatedAt: Date(),
            durationSeconds: durationSeconds,
            isFavorite: isFavorite,
            isUploaded: uploaded,
            storagePath: storagePath,
            encryptionIv: encryptionIv,
            preEmotionalState: preEmotionalState,
            postEmotionalState: postEmotionalState,
            audioMetadata: audioMetadata,
            localFileUrl: localFileUrl
        )
    }
}