// Local Storage Manager for Wordlist Elicitation Tool
// Uses IndexedDB for structured data and localStorage for simple settings

class StorageManager {
    constructor() {
        this.dbName = 'WordlistElicitationDB';
        this.dbVersion = 1;
        this.db = null;
    }

    async init() {
        return new Promise((resolve, reject) => {
            const request = indexedDB.open(this.dbName, this.dbVersion);

            request.onerror = () => reject(request.error);
            request.onsuccess = () => {
                this.db = request.result;
                resolve(this.db);
            };

            request.onupgradeneeded = (event) => {
                const db = event.target.result;

                // Create wordlist entries store
                if (!db.objectStoreNames.contains('entries')) {
                    const entryStore = db.createObjectStore('entries', { keyPath: 'id', autoIncrement: true });
                    entryStore.createIndex('reference', 'reference', { unique: false });
                    entryStore.createIndex('isCompleted', 'isCompleted', { unique: false });
                }

                // Create consent records store
                if (!db.objectStoreNames.contains('consent')) {
                    const consentStore = db.createObjectStore('consent', { keyPath: 'id', autoIncrement: true });
                    consentStore.createIndex('timestamp', 'timestamp', { unique: false });
                }

                // Create audio store for blob data
                if (!db.objectStoreNames.contains('audio')) {
                    const audioStore = db.createObjectStore('audio', { keyPath: 'filename' });
                }
            };
        });
    }

    // Wordlist Entry Operations
    async addEntry(entry) {
        const transaction = this.db.transaction(['entries'], 'readwrite');
        const store = transaction.objectStore('entries');
        return new Promise((resolve, reject) => {
            const request = store.add(entry);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    async getAllEntries() {
        const transaction = this.db.transaction(['entries'], 'readonly');
        const store = transaction.objectStore('entries');
        return new Promise((resolve, reject) => {
            const request = store.getAll();
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    async getEntry(id) {
        const transaction = this.db.transaction(['entries'], 'readonly');
        const store = transaction.objectStore('entries');
        return new Promise((resolve, reject) => {
            const request = store.get(id);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    async updateEntry(entry) {
        const transaction = this.db.transaction(['entries'], 'readwrite');
        const store = transaction.objectStore('entries');
        return new Promise((resolve, reject) => {
            const request = store.put(entry);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    async deleteAllEntries() {
        const transaction = this.db.transaction(['entries'], 'readwrite');
        const store = transaction.objectStore('entries');
        return new Promise((resolve, reject) => {
            const request = store.clear();
            request.onsuccess = () => resolve();
            request.onerror = () => reject(request.error);
        });
    }

    async getCompletedCount() {
        const entries = await this.getAllEntries();
        return entries.filter(e => e.isCompleted).length;
    }

    async getTotalCount() {
        const entries = await this.getAllEntries();
        return entries.length;
    }

    // Audio Operations
    async saveAudio(filename, audioBlob) {
        const transaction = this.db.transaction(['audio'], 'readwrite');
        const store = transaction.objectStore('audio');
        return new Promise((resolve, reject) => {
            const request = store.put({ filename, blob: audioBlob });
            request.onsuccess = () => resolve();
            request.onerror = () => reject(request.error);
        });
    }

    async getAudio(filename) {
        const transaction = this.db.transaction(['audio'], 'readonly');
        const store = transaction.objectStore('audio');
        return new Promise((resolve, reject) => {
            const request = store.get(filename);
            request.onsuccess = () => resolve(request.result ? request.result.blob : null);
            request.onerror = () => reject(request.error);
        });
    }

    async getAllAudio() {
        const transaction = this.db.transaction(['audio'], 'readonly');
        const store = transaction.objectStore('audio');
        return new Promise((resolve, reject) => {
            const request = store.getAll();
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    // Consent Operations
    async addConsentRecord(record) {
        const transaction = this.db.transaction(['consent'], 'readwrite');
        const store = transaction.objectStore('consent');
        return new Promise((resolve, reject) => {
            const request = store.add(record);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    async getAllConsentRecords() {
        const transaction = this.db.transaction(['consent'], 'readonly');
        const store = transaction.objectStore('consent');
        return new Promise((resolve, reject) => {
            const request = store.getAll();
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    // Settings (using localStorage)
    setSetting(key, value) {
        localStorage.setItem(key, JSON.stringify(value));
    }

    getSetting(key, defaultValue = null) {
        const value = localStorage.getItem(key);
        return value ? JSON.parse(value) : defaultValue;
    }
}

// Export singleton instance
const storageManager = new StorageManager();
