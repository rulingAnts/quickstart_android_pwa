// Main Application Logic

class WordlistApp {
    constructor() {
        this.currentScreen = 'home-screen';
        this.currentEntryIndex = 0;
        this.entries = [];
        this.currentAudioBlob = null;
        this._eventsWired = false;
        this._delegationBound = false;
        this.LS_LAST_INDEX_KEY = 'elicitation.lastIndex';
    }

    async init() {
        try {
            // Setup event listeners
            this.setupEventListeners();
            this.bindDelegatedClicks();

            // Initialize storage
            await storageManager.init();

            // Load existing entries
            await this.loadEntries();

            // Update UI
            this.updateHomeScreen();

            console.log('App initialized successfully');
        } catch (error) {
            console.error('App initialization failed:', error);
            this.showError('Failed to initialize app: ' + error.message);
        }
    }

    setupEventListeners() {
        if (this._eventsWired) return;

        // Home screen buttons
        const importBtn = document.getElementById('import-btn');
        if (importBtn) importBtn.addEventListener('click', () => this.showScreen('import-screen'));
        const elicitBtn = document.getElementById('elicitation-btn');
        if (elicitBtn) elicitBtn.addEventListener('click', () => this.showScreen('elicitation-screen'));
        const exportBtn = document.getElementById('export-btn');
        if (exportBtn) exportBtn.addEventListener('click', () => this.showScreen('export-screen'));

        // Import screen
        const importBack = document.getElementById('import-back-btn');
        if (importBack) importBack.addEventListener('click', () => this.showScreen('home-screen'));
        const selectFileBtn = document.getElementById('select-file-btn');
        if (selectFileBtn) selectFileBtn.addEventListener('click', () => {
            const fi = document.getElementById('file-input');
            if (fi) fi.click();
        });
        const fileInput = document.getElementById('file-input');
        if (fileInput) fileInput.addEventListener('change', (e) => this.handleFileSelect(e));
        const importOnlineBtn = document.getElementById('import-online-btn');
        if (importOnlineBtn) {
            importOnlineBtn.addEventListener('click', () => this.handleOnlineImport());
        }

        // Elicitation screen
        const elicBack = document.getElementById('elicitation-back-btn');
        if (elicBack) elicBack.addEventListener('click', () => this.saveCurrentAndGoHome());
        const prevBtn = document.getElementById('prev-btn');
        if (prevBtn) prevBtn.addEventListener('click', () => this.navigateEntry(-1));
        const nextBtn = document.getElementById('next-btn');
        if (nextBtn) nextBtn.addEventListener('click', () => this.navigateEntry(1));
        const recBtn = document.getElementById('record-btn');
        if (recBtn) recBtn.addEventListener('click', () => this.toggleRecording());
        const playBtn = document.getElementById('play-btn');
        if (playBtn) playBtn.addEventListener('click', () => this.playRecording());
        const transInput = document.getElementById('transcription-input');
        if (transInput) transInput.addEventListener('input', (e) => this.updateTranscription(e.target.value));

        // Export screen
        const exportBack = document.getElementById('export-back-btn');
        if (exportBack) exportBack.addEventListener('click', () => this.showScreen('home-screen'));
        const exportDataBtn = document.getElementById('export-data-btn');
        if (exportDataBtn) exportDataBtn.addEventListener('click', () => this.exportData());

    // Entry list panel controls
    const entryListBtn = document.getElementById('entry-list-btn');
    if (entryListBtn) entryListBtn.addEventListener('click', () => this.toggleEntryList(true));
    const entryListClose = document.getElementById('entry-list-close');
    if (entryListClose) entryListClose.addEventListener('click', () => this.toggleEntryList(false));
    const entryListOverlay = document.getElementById('entry-list-overlay');
    if (entryListOverlay) entryListOverlay.addEventListener('click', () => this.toggleEntryList(false));

        this._eventsWired = true;
    }

    bindDelegatedClicks() {
        if (this._delegationBound) return;
        document.addEventListener('click', (ev) => {
            const target = ev.target;
            if (!target || !target.closest) return;

            // Home: Import Wordlist button
            if (target.closest('#import-btn')) {
                ev.preventDefault();
                try { this.showScreen('import-screen'); } catch (_) {}
                return;
            }

            // Generic delegated navigation by data-nav="<screen-id>"
            const navEl = target.closest('[data-nav]');
            if (navEl) {
                const dest = navEl.getAttribute('data-nav');
                if (dest) {
                    ev.preventDefault();
                    try { this.showScreen(dest); } catch (_) {}
                    return;
                }
            }

            // Import: Select XML File button
            if (target.closest('#select-file-btn')) {
                ev.preventDefault();
                const fi = document.getElementById('file-input');
                if (fi) fi.click();
                return;
            }

            // Import: Import from Online Source button
            if (target.closest('#import-online-btn')) {
                ev.preventDefault();
                try { this.handleOnlineImport(); } catch (_) {}
                return;
            }

            // Entry list item selection
            const item = target.closest('[data-entry-index]');
            if (item && item.parentElement && item.parentElement.id === 'entry-list') {
                ev.preventDefault();
                const idx = Number(item.getAttribute('data-entry-index'));
                if (!Number.isNaN(idx)) {
                    this.currentEntryIndex = Math.max(0, Math.min(idx, this.entries.length - 1));
                    this.displayCurrentEntry();
                    this.persistLastIndex();
                    this.toggleEntryList(false);
                }
                return;
            }
        }, { capture: true });
        this._delegationBound = true;
    }

    toggleEntryList(open) {
        const panel = document.getElementById('entry-list-panel');
        const overlay = document.getElementById('entry-list-overlay');
        if (!panel || !overlay) return;
        if (open) {
            this.refreshEntryListPanel();
            panel.style.display = 'block';
            overlay.style.display = 'block';
        } else {
            panel.style.display = 'none';
            overlay.style.display = 'none';
        }
    }

    refreshEntryListPanel() {
        const listEl = document.getElementById('entry-list');
        if (!listEl) return;
        listEl.innerHTML = '';
        this.entries.forEach((e, i) => {
            const li = document.createElement('li');
            li.setAttribute('data-entry-index', String(i));
            li.style.cssText = 'padding:8px 10px; border-bottom:1px solid #eee; cursor:pointer; display:flex; justify-content:space-between; align-items:center; gap:8px;';
            const left = document.createElement('div');
            left.textContent = `${String(e.reference || '').padStart(4, '0')} — ${e.gloss || ''}`;
            const right = document.createElement('div');
            right.style.fontSize = '12px';
            right.style.opacity = '0.7';
            right.textContent = e.isCompleted ? '✓' : '';
            if (i === this.currentEntryIndex) {
                li.style.background = '#f0f7ff';
            }
            li.appendChild(left);
            li.appendChild(right);
            listEl.appendChild(li);
        });
        // Scroll current into view
        const current = listEl.querySelector(`[data-entry-index="${this.currentEntryIndex}"]`);
        if (current && current.scrollIntoView) current.scrollIntoView({ block: 'nearest' });
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
        const all = await storageManager.getAllEntries();
        // Sort by numeric Reference ascending with stable tie-breaker by gloss
        this.entries = all.slice().sort((a, b) => {
            const ra = parseInt(String(a.reference || '').replace(/^0+/, '') || '0', 10);
            const rb = parseInt(String(b.reference || '').replace(/^0+/, '') || '0', 10);
            if (ra !== rb) return ra - rb;
            const ga = (a.gloss || '').toLowerCase();
            const gb = (b.gloss || '').toLowerCase();
            return ga.localeCompare(gb);
        });
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
            // Read as ArrayBuffer to handle UTF-16 correctly
            const buffer = await file.arrayBuffer();
            const text = this.decodePossiblyUtf16(buffer);
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

    async handleOnlineImport() {
        const statusEl = document.getElementById('import-status');
        const selectEl = document.getElementById('online-source-select');
        const url = (selectEl && selectEl.value) ? selectEl.value : '';

        if (!url) {
            this.showError('No online source selected.');
            return;
        }

        // Confirm replacement of existing entries
        const existingTotal = await storageManager.getTotalCount();
        if (existingTotal > 0) {
            const proceed = confirm(`This will replace ${existingTotal} existing entries. Continue?`);
            if (!proceed) return;
        }

        statusEl.textContent = 'Fetching wordlist...';
        statusEl.className = 'status-message info';

        try {
            // Try direct fetch first
            let response = await fetch(url, { cache: 'no-cache' });
            if (!response.ok) {
                // Fallback to jsDelivr mirror if GitHub raw blocks
                const fallback = this.toJsDelivr(url);
                if (fallback) {
                    response = await fetch(fallback, { cache: 'no-cache' });
                }
            }

            if (!response.ok) {
                throw new Error(`Network error: ${response.status} ${response.statusText}`);
            }

            // Fetch as ArrayBuffer to preserve original encoding (UTF-16)
            const buffer = await response.arrayBuffer();
            const text = this.decodePossiblyUtf16(buffer);
            const entries = xmlParser.parseWordlist(text);

            if (entries.length === 0) {
                throw new Error('No valid entries found in remote XML');
            }

            // Replace existing entries
            await storageManager.deleteAllEntries();
            for (const entry of entries) {
                await storageManager.addEntry(entry);
            }

            await this.loadEntries();

            statusEl.textContent = `Successfully imported ${entries.length} entries from online source.`;
            statusEl.className = 'status-message success';
            setTimeout(() => this.showScreen('home-screen'), 2000);
        } catch (error) {
            console.error('Online import failed:', error);
            statusEl.textContent = 'Online import failed: ' + error.message;
            statusEl.className = 'status-message error';
        }
    }

    toJsDelivr(url) {
        try {
            const u = new URL(url);
            // Convert GitHub raw URL to jsDelivr CDN
            // Example:
            // https://raw.githubusercontent.com/owner/repo/refs/heads/main/path/file.xml
            // -> https://cdn.jsdelivr.net/gh/owner/repo@main/path/file.xml
            if (u.hostname === 'raw.githubusercontent.com') {
                const parts = u.pathname.split('/').filter(Boolean);
                // parts: [owner, repo, 'refs', 'heads', branch, ...path]
                if (parts.length >= 5 && parts[2] === 'refs' && parts[3] === 'heads') {
                    const owner = parts[0];
                    const repo = parts[1];
                    const branch = parts[4];
                    const rest = parts.slice(5).join('/');
                    return `https://cdn.jsdelivr.net/gh/${owner}/${repo}@${branch}/${rest}`;
                }
                // Standard raw pattern: /owner/repo/branch/path
                if (parts.length >= 4) {
                    const owner = parts[0];
                    const repo = parts[1];
                    const branch = parts[2];
                    const rest = parts.slice(3).join('/');
                    return `https://cdn.jsdelivr.net/gh/${owner}/${repo}@${branch}/${rest}`;
                }
            }
        } catch (_) {
            // ignore
        }
        return null;
    }

    // Decode XML that may be UTF-8 or UTF-16 (LE/BE) with or without BOM
    decodePossiblyUtf16(arrayBuffer) {
        const bytes = new Uint8Array(arrayBuffer);
        // Check for BOMs
        const hasUTF16LEBOM = bytes.length >= 2 && bytes[0] === 0xFF && bytes[1] === 0xFE;
        const hasUTF16BEBOM = bytes.length >= 2 && bytes[0] === 0xFE && bytes[1] === 0xFF;
        const hasUTF8BOM   = bytes.length >= 3 && bytes[0] === 0xEF && bytes[1] === 0xBB && bytes[2] === 0xBF;

        try {
            if (hasUTF16LEBOM) {
                return new TextDecoder('utf-16le').decode(bytes.subarray(2));
            }
            if (hasUTF16BEBOM) {
                return new TextDecoder('utf-16be').decode(bytes.subarray(2));
            }
        } catch (e) {
            console.warn('TextDecoder utf-16 failed, falling back', e);
        }

        // Heuristic: look at the first few bytes for zero pattern indicating UTF-16
        if (!hasUTF8BOM && bytes.length >= 4) {
            const zeroEveryOtherLE = bytes[1] === 0x00 || bytes[3] === 0x00;
            const zeroEveryOtherBE = bytes[0] === 0x00 || bytes[2] === 0x00;
            try {
                if (zeroEveryOtherLE) {
                    return new TextDecoder('utf-16le').decode(bytes);
                }
                if (zeroEveryOtherBE) {
                    return new TextDecoder('utf-16be').decode(bytes);
                }
            } catch (e) {
                console.warn('Heuristic utf-16 decode failed, will try utf-8', e);
            }
        }

        // Default to UTF-8
        try {
            return new TextDecoder('utf-8').decode(bytes.subarray(hasUTF8BOM ? 3 : 0));
        } catch (e) {
            // Last resort
            return String.fromCharCode.apply(null, bytes);
        }
    }

    loadElicitationScreen() {
        if (this.entries.length === 0) {
            this.showScreen('home-screen');
            return;
        }

        // Restore last position if available
        try {
            const saved = localStorage.getItem(this.LS_LAST_INDEX_KEY);
            if (saved != null) {
                const idx = Number(saved);
                if (!Number.isNaN(idx) && idx >= 0 && idx < this.entries.length) {
                    this.currentEntryIndex = idx;
                }
            }
        } catch (_) {}

        // Ensure current index is valid
        if (this.currentEntryIndex >= this.entries.length) {
            this.currentEntryIndex = 0;
        }

        this.displayCurrentEntry();
        this.refreshEntryListPanel();
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
        this.persistLastIndex();
        this.refreshEntryListPanel();
    }

    async saveCurrentEntry() {
        const entry = this.entries[this.currentEntryIndex];
        if (!entry) return;

        // Update completion status
        const hasTranscription = entry.localTranscription && entry.localTranscription.trim() !== '';
        const hasAudio = entry.audioFilename !== null;
        entry.isCompleted = hasTranscription || hasAudio;

        await storageManager.updateEntry(entry);
        this.persistLastIndex();
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

    persistLastIndex() {
        try { localStorage.setItem(this.LS_LAST_INDEX_KEY, String(this.currentEntryIndex)); } catch (_) {}
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
        const filename = `${entry.reference.padStart(4, '0')}${entry.gloss.replace(/\s+/g, '.')}.wav`;
        
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

// Initialize app regardless of when this script is injected
const app = new WordlistApp();
// Expose for debugging
try { window.app = app; } catch (_) {}
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => app.init());
} else {
    // DOMContentLoaded already fired
    app.init();
}
