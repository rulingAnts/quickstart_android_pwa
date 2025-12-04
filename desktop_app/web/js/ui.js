/**
 * Wordlist Elicitation Tool - Desktop UI
 * 
 * This file contains UI-only logic. All business logic is handled by Python via pywebview API.
 * Access Python APIs through: window.pywebview.api.<method>()
 */

// State
let currentScreen = 'home-screen';
let currentEntryIndex = 0;
let entries = [];
let currentEntryId = null;
let isRecording = false;

// Wait for pywebview API to be ready
window.addEventListener('pywebviewready', init);

async function init() {
    try {
        await loadEntries();
        setupEventListeners();
        await updateHomeScreen();
        console.log('App initialized');
    } catch (err) {
        console.error('Init failed:', err);
        alert('Failed to initialize: ' + err.message);
    }
}

function setupEventListeners() {
    // Home screen
    document.getElementById('import-btn').addEventListener('click', () => showScreen('import-screen'));
    document.getElementById('elicitation-btn').addEventListener('click', () => showScreen('elicitation-screen'));
    document.getElementById('export-btn').addEventListener('click', () => showScreen('export-screen'));
    
    // Import screen
    document.getElementById('import-back-btn').addEventListener('click', () => showScreen('home-screen'));
    document.getElementById('select-file-btn').addEventListener('click', handleFileSelect);
    document.getElementById('import-url-btn').addEventListener('click', handleUrlImport);
    document.getElementById('url-input').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') handleUrlImport();
    });
    
    // Elicitation screen
    document.getElementById('elicitation-back-btn').addEventListener('click', saveAndGoHome);
    document.getElementById('prev-btn').addEventListener('click', () => navigateEntry(-1));
    document.getElementById('next-btn').addEventListener('click', () => navigateEntry(1));
    document.getElementById('record-btn').addEventListener('click', toggleRecording);
    document.getElementById('play-btn').addEventListener('click', playRecording);
    document.getElementById('transcription-input').addEventListener('input', (e) => {
        updateTranscription(e.target.value);
    });
    
    // All entries panel
    document.getElementById('all-entries-btn').addEventListener('click', openAllEntriesPanel);
    document.getElementById('close-panel-btn').addEventListener('click', closeAllEntriesPanel);
    document.getElementById('panel-overlay').addEventListener('click', closeAllEntriesPanel);
    document.getElementById('entry-search').addEventListener('input', (e) => {
        filterEntryList(e.target.value);
    });
    
    // Export screen
    document.getElementById('export-back-btn').addEventListener('click', () => showScreen('home-screen'));
    document.getElementById('export-data-btn').addEventListener('click', exportData);
}

function showScreen(id) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById(id).classList.add('active');
    currentScreen = id;
    
    if (id === 'elicitation-screen') loadElicitationScreen();
    else if (id === 'export-screen') loadExportScreen();
    else if (id === 'home-screen') updateHomeScreen();
}

async function loadEntries() {
    entries = await window.pywebview.api.load_entries();
    updateButtonStates();
}

function updateButtonStates() {
    const hasEntries = entries.length > 0;
    document.getElementById('elicitation-btn').disabled = !hasEntries;
    document.getElementById('export-btn').disabled = !hasEntries;
}

async function updateHomeScreen() {
    const progress = await window.pywebview.api.get_progress();
    document.getElementById('total-count').textContent = progress.total;
    document.getElementById('completed-count').textContent = progress.completed;
    document.getElementById('remaining-count').textContent = progress.total - progress.completed;
    updateButtonStates();
}

// Import functions
async function handleFileSelect() {
    const status = document.getElementById('import-status');
    
    try {
        const path = await window.pywebview.api.select_import_file();
        if (!path) return;
        
        status.textContent = 'Processing...';
        status.className = 'status-message info';
        
        const result = await window.pywebview.api.import_from_file(path);
        
        if (result.success) {
            await loadEntries();
            status.textContent = `Imported ${result.count} entries!`;
            status.className = 'status-message success';
            setTimeout(() => showScreen('home-screen'), 2000);
        } else {
            status.textContent = 'Import failed: ' + result.error;
            status.className = 'status-message error';
        }
    } catch (err) {
        console.error('Import failed:', err);
        status.textContent = 'Import failed: ' + err.message;
        status.className = 'status-message error';
    }
}

async function handleUrlImport() {
    const urlInput = document.getElementById('url-input');
    const status = document.getElementById('import-status');
    const url = urlInput.value.trim();
    
    if (!url) {
        status.textContent = 'Please enter a URL';
        status.className = 'status-message error';
        return;
    }
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
        status.textContent = 'URL must start with http:// or https://';
        status.className = 'status-message error';
        return;
    }
    
    try {
        status.textContent = 'Fetching...';
        status.className = 'status-message info';
        
        const result = await window.pywebview.api.import_from_url(url);
        
        if (result.success) {
            await loadEntries();
            status.textContent = `Imported ${result.count} entries!`;
            status.className = 'status-message success';
            urlInput.value = '';
            setTimeout(() => showScreen('home-screen'), 2000);
        } else {
            status.textContent = 'Import failed: ' + result.error;
            status.className = 'status-message error';
        }
    } catch (err) {
        console.error('Import failed:', err);
        status.textContent = 'Import failed: ' + err.message;
        status.className = 'status-message error';
    }
}

// Elicitation functions
async function loadElicitationScreen() {
    if (entries.length === 0) {
        showScreen('home-screen');
        return;
    }
    
    // Restore last position
    const lastPos = await window.pywebview.api.get_last_position();
    currentEntryIndex = Math.min(lastPos, entries.length - 1);
    currentEntryIndex = Math.max(0, currentEntryIndex);
    
    displayCurrentEntry();
}

function displayCurrentEntry() {
    const entry = entries[currentEntryIndex];
    if (!entry) return;
    
    currentEntryId = entry.id;
    
    document.getElementById('word-reference').textContent = entry.reference || '';
    document.getElementById('word-gloss').textContent = entry.gloss || '';
    document.getElementById('transcription-input').value = entry.local_transcription || '';
    
    const pic = document.getElementById('picture-container');
    if (entry.picture_filename) {
        pic.style.display = 'block';
        document.getElementById('word-picture').src = entry.picture_filename;
    } else {
        pic.style.display = 'none';
    }
    
    document.getElementById('word-counter').textContent = `${currentEntryIndex + 1} / ${entries.length}`;
    document.getElementById('prev-btn').disabled = currentEntryIndex === 0;
    document.getElementById('next-btn').disabled = currentEntryIndex === entries.length - 1;
    
    const playBtn = document.getElementById('play-btn');
    playBtn.style.display = entry.audio_filename ? 'flex' : 'none';
    
    updateRecordingStatus('');
    
    // Save position (fire and forget, no need to await)
    window.pywebview.api.set_last_position(currentEntryIndex).catch(err => {
        console.warn('Failed to save position:', err);
    });
}

async function navigateEntry(direction) {
    await saveCurrentEntry();
    currentEntryIndex += direction;
    currentEntryIndex = Math.max(0, Math.min(currentEntryIndex, entries.length - 1));
    displayCurrentEntry();
}

async function saveCurrentEntry() {
    if (currentEntryId === null) return;
    
    const transcription = document.getElementById('transcription-input').value;
    await window.pywebview.api.save_transcription(currentEntryId, transcription);
    
    // Update local entry
    const entry = entries[currentEntryIndex];
    if (entry) {
        entry.local_transcription = transcription;
        entry.is_completed = !!(transcription.trim() || entry.audio_filename);
    }
}

async function saveAndGoHome() {
    await saveCurrentEntry();
    await loadEntries();
    showScreen('home-screen');
}

async function updateTranscription(value) {
    // Just update the local entry; actual save happens on navigate
    const entry = entries[currentEntryIndex];
    if (entry) {
        entry.local_transcription = value;
    }
}

async function toggleRecording() {
    const btn = document.getElementById('record-btn');
    const txt = document.getElementById('record-text');
    
    if (isRecording) {
        // Stop recording
        try {
            const result = await window.pywebview.api.stop_recording(currentEntryId);
            btn.classList.remove('recording');
            txt.textContent = 'Record';
            isRecording = false;
            
            if (result.success) {
                // Update local entry
                const entry = entries[currentEntryIndex];
                if (entry) {
                    entry.audio_filename = result.filename;
                    entry.is_completed = true;
                }
                
                document.getElementById('play-btn').style.display = 'flex';
                updateRecordingStatus('Recording saved!', 'success');
            } else {
                updateRecordingStatus('Recording failed: ' + result.error, 'error');
            }
        } catch (err) {
            console.error('Stop failed:', err);
            updateRecordingStatus('Stop failed: ' + err.message, 'error');
            btn.classList.remove('recording');
            txt.textContent = 'Record';
            isRecording = false;
        }
    } else {
        // Start recording
        try {
            const started = await window.pywebview.api.start_recording(currentEntryId);
            if (started) {
                btn.classList.add('recording');
                txt.textContent = 'Stop';
                isRecording = true;
                updateRecordingStatus('Recording...', 'info');
            } else {
                updateRecordingStatus('Could not start recording', 'error');
            }
        } catch (err) {
            console.error('Start failed:', err);
            updateRecordingStatus('Microphone access required', 'error');
        }
    }
}

async function playRecording() {
    try {
        const success = await window.pywebview.api.play_audio(currentEntryId);
        if (!success) {
            updateRecordingStatus('No recording available', 'error');
        }
    } catch (err) {
        console.error('Playback failed:', err);
        updateRecordingStatus('Playback failed', 'error');
    }
}

function updateRecordingStatus(msg, type = '') {
    const el = document.getElementById('recording-status');
    el.textContent = msg;
    el.className = 'status-message';
    if (type) el.classList.add(type);
    
    if (msg && type !== 'info') {
        setTimeout(() => {
            el.textContent = '';
            el.className = 'status-message';
        }, 3000);
    }
}

// All entries panel
async function openAllEntriesPanel() {
    document.getElementById('all-entries-panel').classList.add('open');
    document.getElementById('panel-overlay').classList.add('open');
    document.getElementById('entry-search').value = '';
    await populateEntryList();
}

function closeAllEntriesPanel() {
    document.getElementById('all-entries-panel').classList.remove('open');
    document.getElementById('panel-overlay').classList.remove('open');
}

async function populateEntryList(filterText = null) {
    const list = document.getElementById('entry-list');
    const summaries = await window.pywebview.api.list_all_entries(filterText);
    
    list.innerHTML = summaries.map((e, idx) => `
        <div class="entry-item" data-index="${idx}" data-id="${e.id}">
            <span class="entry-ref">${e.reference}</span>
            <span class="entry-gloss">${e.gloss}</span>
            <span class="entry-badge">${e.is_completed ? '✓' : ''}</span>
        </div>
    `).join('');
    
    // Add click handlers
    list.querySelectorAll('.entry-item').forEach(item => {
        item.addEventListener('click', async () => {
            await saveCurrentEntry();
            
            const id = parseInt(item.dataset.id);
            // Find index in current entries array
            const idx = entries.findIndex(e => e.id === id);
            if (idx !== -1) {
                currentEntryIndex = idx;
                displayCurrentEntry();
            }
            
            closeAllEntriesPanel();
        });
    });
}

async function filterEntryList(text) {
    await populateEntryList(text || null);
}

// Export functions
async function loadExportScreen() {
    const progress = await window.pywebview.api.get_progress();
    document.getElementById('export-total').textContent = progress.total;
    document.getElementById('export-completed').textContent = progress.completed;
    document.getElementById('export-audio').textContent = progress.withAudio;
    document.getElementById('export-transcribed').textContent = progress.transcribed;
}

async function exportData() {
    const status = document.getElementById('export-status');
    const btn = document.getElementById('export-data-btn');
    
    try {
        status.textContent = 'Selecting destination...';
        status.className = 'status-message info';
        btn.disabled = true;
        
        const destPath = await window.pywebview.api.select_export_path();
        if (!destPath) {
            status.textContent = '';
            status.className = 'status-message';
            btn.disabled = false;
            return;
        }
        
        status.textContent = 'Preparing export...';
        
        const result = await window.pywebview.api.export_zip(destPath);
        
        if (result.success) {
            status.textContent = `Export successful! Saved to: ${result.path}`;
            status.className = 'status-message success';
        } else {
            status.textContent = 'Export failed: ' + result.error;
            status.className = 'status-message error';
        }
    } catch (err) {
        console.error('Export failed:', err);
        status.textContent = 'Export failed: ' + err.message;
        status.className = 'status-message error';
    } finally {
        btn.disabled = false;
    }
}
