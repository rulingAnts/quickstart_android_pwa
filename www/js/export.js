// Export functionality using JSZip

class ExportManager {
    constructor() {
        this.zipLibUrl = 'https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js';
        this.zipLoaded = false;
    }

    async ensureJSZip() {
        if (this.zipLoaded && typeof JSZip !== 'undefined') {
            return;
        }

        return new Promise((resolve, reject) => {
            const script = document.createElement('script');
            script.src = this.zipLibUrl;
            script.onload = () => {
                this.zipLoaded = true;
                resolve();
            };
            script.onerror = () => reject(new Error('Failed to load JSZip library'));
            document.head.appendChild(script);
        });
    }

    async exportData() {
        try {
            // Load JSZip if needed
            await this.ensureJSZip();

            const zip = new JSZip();

            // Get all entries and audio
            const entries = await storageManager.getAllEntries();
            const audioFiles = await storageManager.getAllAudio();
            const consentRecords = await storageManager.getAllConsentRecords();

            // Generate XML (string) and encode as UTF-16LE with BOM
            const xmlContent = xmlParser.generateXML(entries);
            const xmlUtf16 = this.encodeUtf16LeWithBom(xmlContent);
            zip.file('wordlist.xml', xmlUtf16);

            // Add audio files
            const audioFolder = zip.folder('audio');
            for (const audioFile of audioFiles) {
                if (audioFile.blob) {
                    audioFolder.file(audioFile.filename, audioFile.blob);
                }
            }

            // Add consent log
            if (consentRecords.length > 0) {
                const consentLog = this.generateConsentLog(consentRecords);
                zip.file('consent_log.json', consentLog);
            }

            // Add metadata
            const metadata = this.generateMetadata(entries);
            zip.file('metadata.json', metadata);

            // Generate ZIP file
            const blob = await zip.generateAsync({ 
                type: 'blob',
                compression: 'DEFLATE',
                compressionOptions: { level: 6 }
            });

            // Download the file
            this.downloadBlob(blob, this.generateFilename());

            return true;
        } catch (error) {
            console.error('Export failed:', error);
            throw error;
        }
    }

    // Encode a JS string to UTF-16LE with BOM (0xFF,0xFE)
    encodeUtf16LeWithBom(str) {
        const buf = new Uint8Array(2 + str.length * 2);
        // BOM FF FE
        buf[0] = 0xFF; buf[1] = 0xFE;
        let o = 2;
        for (let i = 0; i < str.length; i++) {
            const code = str.charCodeAt(i);
            buf[o++] = code & 0xFF;        // low byte
            buf[o++] = (code >> 8) & 0xFF; // high byte
        }
        return buf;
    }

    generateConsentLog(records) {
        const log = {
            generatedAt: new Date().toISOString(),
            records: records.map(r => ({
                id: r.id,
                timestamp: r.timestamp,
                deviceId: r.deviceId,
                type: r.type,
                response: r.response,
                verbalConsentFilename: r.verbalConsentFilename || null
            }))
        };
        return JSON.stringify(log, null, 2);
    }

    generateMetadata(entries) {
        const metadata = {
            exportedAt: new Date().toISOString(),
            appVersion: '1.0.0',
            totalEntries: entries.length,
            completedEntries: entries.filter(e => e.isCompleted).length,
            entriesWithAudio: entries.filter(e => e.audioFilename).length,
            entriesWithTranscription: entries.filter(e => e.localTranscription).length
        };
        return JSON.stringify(metadata, null, 2);
    }

    generateFilename() {
        const now = new Date();
        const dateStr = now.toISOString().split('T')[0].replace(/-/g, '');
        const timeStr = now.toTimeString().split(' ')[0].replace(/:/g, '');
        return `wordlist_export_${dateStr}_${timeStr}.zip`;
    }

    downloadBlob(blob, filename) {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    async getExportStats() {
        const entries = await storageManager.getAllEntries();
        return {
            total: entries.length,
            completed: entries.filter(e => e.isCompleted).length,
            withAudio: entries.filter(e => e.audioFilename).length
        };
    }
}

const exportManager = new ExportManager();
