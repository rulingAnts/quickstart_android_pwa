// Main Application Logic

class WordlistApp {
    constructor() {
        this.currentScreen = 'home-screen';
        this.currentEntryIndex = 0;
        this.entries = [];
        this.currentAudioBlob = null;
    }

    async init() {
        try {
            // Initialize storage
            await storageManager.init();

            // Load existing entries
            await this.loadEntries();

            // Setup event listeners
            this.setupEventListeners();

            // Update UI
            this.updateHomeScreen();

            console.log('App initialized successfully');
        } catch (error) {
            console.error('App initialization failed:', error);
            this.showError('Failed to initialize app: ' + error.message);
        }
    }

    setupEventListeners() {
        // Home screen buttons
        document.getElementById('import-btn').addEventListener('click', () => this.showScreen('import-screen'));
        document.getElementById('elicitation-btn').addEventListener('click', () => this.showScreen('elicitation-screen'));
        document.getElementById('export-btn').addEventListener('click', () => this.showScreen('export-screen'));

        // Import screen
        document.getElementById('import-back-btn').addEventListener('click', () => this.showScreen('home-screen'));
        document.getElementById('select-file-btn').addEventListener('click', () => document.getElementById('file-input').click());
        document.getElementById('file-input').addEventListener('change', (e) => this.handleFileSelect(e));

        // Elicitation screen
        document.getElementById('elicitation-back-btn').addEventListener('click', () => this.saveCurrentAndGoHome());
        document.getElementById('prev-btn').addEventListener('click', () => this.navigateEntry(-1));
        document.getElementById('next-btn').addEventListener('click', () => this.navigateEntry(1));
        document.getElementById('record-btn').addEventListener('click', () => this.toggleRecording());
        document.getElementById('play-btn').addEventListener('click', () => this.playRecording());
        document.getElementById('transcription-input').addEventListener('input', (e) => this.updateTranscription(e.target.value));

        // Export screen
        document.getElementById('export-back-btn').addEventListener('click', () => this.showScreen('home-screen'));
        document.getElementById('export-data-btn').addEventListener('click', () => this.exportData());
    }

    showScreen(screenId) {
        // Hide all screens
        document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
        
        // Show requested screen
        document.getElementById(screenId).classList.add('active');
        this.currentScreen = screenId;

        // Update screen-specific content
        if (screenId === 'elicitation-screen') {
            this.loadElicitationScreen();
        } else if (screenId === 'export-screen') {
            this.loadExportScreen();
        } else if (screenId === 'home-screen') {
            this.updateHomeScreen();
        }
    }

    async loadEntries() {
        this.entries = await storageManager.getAllEntries();
        this.updateButtonStates();
    }

    updateButtonStates() {
        const hasEntries = this.entries.length > 0;
        document.getElementById('elicitation-btn').disabled = !hasEntries;
        document.getElementById('export-btn').disabled = !hasEntries;
    }

    async updateHomeScreen() {
        const total = await storageManager.getTotalCount();
        const completed = await storageManager.getCompletedCount();
        const remaining = total - completed;

        document.getElementById('total-count').textContent = total;
        document.getElementById('completed-count').textContent = completed;
        document.getElementById('remaining-count').textContent = remaining;

        this.updateButtonStates();
    }

    async handleFileSelect(event) {
        const file = event.target.files[0];
        if (!file) return;

        const statusEl = document.getElementById('import-status');
        statusEl.textContent = 'Processing...';
        statusEl.className = 'status-message info';

        try {
            const text = await file.text();
            const entries = xmlParser.parseWordlist(text);

            if (entries.length === 0) {
                throw new Error('No valid entries found in XML file');
            }

            // Clear existing entries
            await storageManager.deleteAllEntries();

            // Add new entries
            for (const entry of entries) {
                await storageManager.addEntry(entry);
            }

            // Reload entries
            await this.loadEntries();

            statusEl.textContent = `Successfully imported ${entries.length} entries!`;
            statusEl.className = 'status-message success';

            // Go to home screen after 2 seconds
            setTimeout(() => this.showScreen('home-screen'), 2000);
        } catch (error) {
            console.error('Import failed:', error);
            statusEl.textContent = 'Import failed: ' + error.message;
            statusEl.className = 'status-message error';
        }

        // Reset file input
        event.target.value = '';
    }

    loadElicitationScreen() {
        if (this.entries.length === 0) {
            this.showScreen('home-screen');
            return;
        }

        // Ensure current index is valid
        if (this.currentEntryIndex >= this.entries.length) {
            this.currentEntryIndex = 0;
        }

        this.displayCurrentEntry();
    }

    displayCurrentEntry() {
        const entry = this.entries[this.currentEntryIndex];
        if (!entry) return;

        // Update word info
        document.getElementById('word-reference').textContent = entry.reference || '';
        document.getElementById('word-gloss').textContent = entry.gloss || '';
        document.getElementById('transcription-input').value = entry.localTranscription || '';

        // Update picture if available
        const pictureContainer = document.getElementById('picture-container');
        if (entry.pictureFilename) {
            pictureContainer.style.display = 'block';
            document.getElementById('word-picture').src = entry.pictureFilename;
        } else {
            pictureContainer.style.display = 'none';
        }

        // Update navigation
        document.getElementById('word-counter').textContent = 
            `${this.currentEntryIndex + 1} / ${this.entries.length}`;
        
        document.getElementById('prev-btn').disabled = this.currentEntryIndex === 0;
        document.getElementById('next-btn').disabled = this.currentEntryIndex === this.entries.length - 1;

        // Update play button visibility
        const playBtn = document.getElementById('play-btn');
        if (entry.audioFilename) {
            playBtn.style.display = 'flex';
        } else {
            playBtn.style.display = 'none';
        }

        // Reset recording status
        this.currentAudioBlob = null;
        this.updateRecordingStatus('');
    }

    async navigateEntry(direction) {
        // Save current entry first
        await this.saveCurrentEntry();

        // Navigate
        this.currentEntryIndex += direction;
        this.currentEntryIndex = Math.max(0, Math.min(this.currentEntryIndex, this.entries.length - 1));

        // Load new entry
        this.displayCurrentEntry();
    }

    async saveCurrentEntry() {
        const entry = this.entries[this.currentEntryIndex];
        if (!entry) return;

        // Update completion status
        const hasTranscription = entry.localTranscription && entry.localTranscription.trim() !== '';
        const hasAudio = entry.audioFilename !== null;
        entry.isCompleted = hasTranscription || hasAudio;

        await storageManager.updateEntry(entry);
    }

    async saveCurrentAndGoHome() {
        await this.saveCurrentEntry();
        await this.loadEntries();
        this.showScreen('home-screen');
    }

    updateTranscription(value) {
        const entry = this.entries[this.currentEntryIndex];
        if (entry) {
            entry.localTranscription = value;
        }
    }

    async toggleRecording() {
        const recordBtn = document.getElementById('record-btn');
        const recordText = document.getElementById('record-text');

        if (audioRecorder.isRecording) {
            // Stop recording
            try {
                this.currentAudioBlob = await audioRecorder.stopRecording();
                recordBtn.classList.remove('recording');
                recordText.textContent = 'Record';
                
                // Save audio
                await this.saveAudio();
                
                this.updateRecordingStatus('Recording saved!', 'success');
                
                // Show play button
                document.getElementById('play-btn').style.display = 'flex';
            } catch (error) {
                console.error('Stop recording failed:', error);
                this.updateRecordingStatus('Failed to stop recording', 'error');
            }
        } else {
            // Start recording
            try {
                await audioRecorder.startRecording();
                recordBtn.classList.add('recording');
                recordText.textContent = 'Stop';
                this.updateRecordingStatus('Recording...', 'info');
            } catch (error) {
                console.error('Start recording failed:', error);
                this.updateRecordingStatus('Microphone access required', 'error');
            }
        }
    }

    async saveAudio() {
        if (!this.currentAudioBlob) return;

        const entry = this.entries[this.currentEntryIndex];
        const filename = `${entry.reference.padStart(4, '0')}_${entry.gloss.replace(/\s+/g, '.')}.wav`;
        
        // Save audio blob to storage
        await storageManager.saveAudio(filename, this.currentAudioBlob);
        
        // Update entry
        entry.audioFilename = filename;
        entry.recordedAt = new Date().toISOString();
        await storageManager.updateEntry(entry);
        
        // Update local entry
        this.entries[this.currentEntryIndex] = entry;
    }

    async playRecording() {
        const entry = this.entries[this.currentEntryIndex];
        
        let audioBlob;
        if (this.currentAudioBlob) {
            audioBlob = this.currentAudioBlob;
        } else if (entry.audioFilename) {
            audioBlob = await storageManager.getAudio(entry.audioFilename);
        }

        if (!audioBlob) {
            this.updateRecordingStatus('No recording available', 'error');
            return;
        }

        try {
            const audioUrl = URL.createObjectURL(audioBlob);
            const audio = new Audio(audioUrl);
            audio.play();
            audio.onended = () => URL.revokeObjectURL(audioUrl);
        } catch (error) {
            console.error('Playback failed:', error);
            this.updateRecordingStatus('Playback failed', 'error');
        }
    }

    updateRecordingStatus(message, type = '') {
        const statusEl = document.getElementById('recording-status');
        statusEl.textContent = message;
        statusEl.className = 'status-message';
        if (type) {
            statusEl.classList.add(type);
        }

        if (message) {
            setTimeout(() => {
                statusEl.textContent = '';
                statusEl.className = 'status-message';
            }, 3000);
        }
    }

    async loadExportScreen() {
        const stats = await exportManager.getExportStats();
        
        document.getElementById('export-total').textContent = stats.total;
        document.getElementById('export-completed').textContent = stats.completed;
        document.getElementById('export-audio').textContent = stats.withAudio;
    }

    async exportData() {
        const statusEl = document.getElementById('export-status');
        const exportBtn = document.getElementById('export-data-btn');

        statusEl.textContent = 'Preparing export...';
        statusEl.className = 'status-message info';
        exportBtn.disabled = true;

        try {
            await exportManager.exportData();
            statusEl.textContent = 'Export successful! Download started.';
            statusEl.className = 'status-message success';
        } catch (error) {
            console.error('Export failed:', error);
            statusEl.textContent = 'Export failed: ' + error.message;
            statusEl.className = 'status-message error';
        } finally {
            exportBtn.disabled = false;
        }
    }

    showError(message) {
        alert(message);
    }
}

// Initialize app when DOM is ready
const app = new WordlistApp();
document.addEventListener('DOMContentLoaded', () => app.init());
