// XML Parser for Dekereke Wordlist Format

class XMLParser {
    parseWordlist(xmlString) {
        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(xmlString, 'text/xml');

        // Check for parsing errors
        const parserError = xmlDoc.querySelector('parsererror');
        if (parserError) {
            throw new Error('XML parsing error: ' + parserError.textContent);
        }

        const entries = [];
        
        // Find all word entries - support multiple possible element names
        const wordElements = this.findWordElements(xmlDoc);

        wordElements.forEach((element, index) => {
            const entry = this.parseWordElement(element, index);
            if (entry) {
                entries.push(entry);
            }
        });

        return entries;
    }

    findWordElements(xmlDoc) {
        // Try different common element names for wordlist entries
        const possibleNames = ['Word', 'Entry', 'Item', 'word', 'entry', 'item', 'data_form'];
        
        for (const name of possibleNames) {
            const elements = xmlDoc.getElementsByTagName(name);
            if (elements.length > 0) {
                return Array.from(elements);
            }
        }

        // If no standard names found, try to get all children of the root
        const root = xmlDoc.documentElement;
        if (root && root.children.length > 0) {
            return Array.from(root.children);
        }

        return [];
    }

    parseWordElement(element, index) {
        const entry = {
            reference: this.getElementText(element, ['Reference', 'Ref', 'Number', 'reference', 'ref', 'number']),
            gloss: this.getElementText(element, ['Gloss', 'English', 'Word', 'gloss', 'english', 'word']),
            localTranscription: '',
            audioFilename: null,
            pictureFilename: this.getElementText(element, ['Picture', 'Image', 'picture', 'image']),
            recordedAt: null,
            isCompleted: false
        };

        // If no reference found, generate one
        if (!entry.reference) {
            entry.reference = String(index + 1).padStart(4, '0');
        }

        // If no gloss found, skip this entry
        if (!entry.gloss) {
            return null;
        }

        return entry;
    }

    getElementText(parentElement, possibleNames) {
        for (const name of possibleNames) {
            const element = parentElement.getElementsByTagName(name)[0];
            if (element && element.textContent) {
                return element.textContent.trim();
            }
        }
        return '';
    }

    generateXML(entries) {
        // Create XML document
        let xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
        xml += '<Wordlist>\n';

        entries.forEach(entry => {
            xml += '  <Word>\n';
            xml += `    <Reference>${this.escapeXml(entry.reference)}</Reference>\n`;
            xml += `    <Gloss>${this.escapeXml(entry.gloss)}</Gloss>\n`;
            
            if (entry.localTranscription) {
                xml += `    <LocalTranscription>${this.escapeXml(entry.localTranscription)}</LocalTranscription>\n`;
            }
            
            if (entry.audioFilename) {
                xml += `    <SoundFile>${this.escapeXml(entry.audioFilename)}</SoundFile>\n`;
            }
            
            if (entry.pictureFilename) {
                xml += `    <Picture>${this.escapeXml(entry.pictureFilename)}</Picture>\n`;
            }
            
            if (entry.recordedAt) {
                xml += `    <RecordedAt>${this.escapeXml(entry.recordedAt)}</RecordedAt>\n`;
            }
            
            xml += '  </Word>\n';
        });

        xml += '</Wordlist>';
        return xml;
    }

    escapeXml(text) {
        if (!text) return '';
        return String(text)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&apos;');
    }
}

const xmlParser = new XMLParser();
