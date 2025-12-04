# Wordlist Elicitation Tool - Desktop Application

A desktop version of the Wordlist Elicitation Tool built with Python and pywebview. This application is designed for linguistic fieldwork, allowing users to import wordlists, record audio transcriptions, and export data in a standardized format.

## Features

- **Import Wordlists**: Load XML wordlists from local files or URLs
  - Supports UTF-8, UTF-16LE, and UTF-16BE encodings with automatic BOM detection
  - Tolerant parsing handles multiple XML schemas
  - Numeric reference sorting

- **Elicitation Interface**: Record transcriptions and audio for each word
  - Large, easy-to-use recording button
  - 16-bit PCM WAV audio format
  - Resume from last position
  - Quick navigation panel with search

- **Export Data**: Create ZIP archives with:
  - `wordlist.xml` - UTF-16LE encoded with single BOM
  - `audio/` folder with WAV recordings
  - `consent_log.json` (if applicable)
  - `metadata.json` with export statistics

## Requirements

- Python 3.8 or higher
- Platform-specific audio library (installed automatically)

## Installation

### macOS (Recommended)

```bash
# Navigate to the desktop_app directory
cd desktop_app

# Create a virtual environment
python3 -m venv .venv

# Activate the virtual environment
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

**Note for macOS**: You may need to install PortAudio for sounddevice:
```bash
brew install portaudio
```

### Windows

```bash
# Navigate to the desktop_app directory
cd desktop_app

# Create a virtual environment
python -m venv .venv

# Activate the virtual environment
.venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

**Note for Windows**: PyAudio may require Visual C++ Build Tools. If installation fails:
1. Download and install [Visual C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
2. Or use a pre-built wheel: `pip install pipwin && pipwin install pyaudio`

### Linux

```bash
# Navigate to the desktop_app directory
cd desktop_app

# Create a virtual environment
python3 -m venv .venv

# Activate the virtual environment
source .venv/bin/activate

# Install system dependencies (Ubuntu/Debian)
sudo apt-get install python3-dev libportaudio2 libportaudiocpp0 portaudio19-dev

# Install Python dependencies
pip install -r requirements.txt
```

## Running the Application

From the repository root:

```bash
# Activate virtual environment first
source desktop_app/.venv/bin/activate  # macOS/Linux
# or
desktop_app\.venv\Scripts\activate  # Windows

# Run the application
python desktop_app/main.py
```

Or from within the desktop_app directory:

```bash
source .venv/bin/activate
python main.py
```

## Usage

### Import a Wordlist

1. Click "Import Wordlist" on the home screen
2. Select an XML file using the file picker, OR
3. Enter a URL and click "Import from URL"

Supported XML formats include Dekereke-style wordlists with various element names (`Word`, `Entry`, `Item`, `data_form`).

### Elicitation

1. Click "Start Elicitation" on the home screen
2. For each word:
   - Enter the local transcription in the text field
   - Click the Record button to capture audio
   - Click again to stop recording
   - Use the Play button to review
3. Navigate with Previous/Next buttons
4. Click the list icon to jump to any entry

### Export Data

1. Click "Export Data" on the home screen
2. Choose a destination for the ZIP file
3. The export includes:
   - UTF-16LE encoded XML with BOM
   - All recorded audio files
   - Metadata with statistics

## File Format Details

### Import XML

The application accepts XML with various element structures:
- `<Word>`, `<Entry>`, `<Item>`, or `<data_form>` elements
- Fields: `Reference`, `Gloss`, `LocalTranscription`, `SoundFile`, `Picture`

### Export XML

Exports use the `<phon_data>/<data_form>` schema:
```xml
<?xml version="1.0" encoding="UTF-16"?>
<phon_data>
  <data_form>
    <Reference>0001</Reference>
    <Gloss>body</Gloss>
    <LocalTranscription>soma</LocalTranscription>
    <SoundFile>0001_body.wav</SoundFile>
  </data_form>
</phon_data>
```

The XML is encoded as UTF-16LE with a single BOM (`FF FE`) at the start.

### Audio Files

- Format: WAV, 16-bit PCM, mono, 44.1kHz
- Naming: `{reference}_{gloss_slug}.wav`
- Gloss slug rules: lowercase, spaces→dots, alphanumeric only, max 64 chars

## Data Storage

Application data is stored in:
- **macOS/Linux**: `~/.wordlist_elicitation/wordlist.db`
- **Windows**: `%USERPROFILE%\.wordlist_elicitation\wordlist.db`

## Running Tests

```bash
# From the desktop_app directory
python -m pytest tests/ -v

# Or run individual test scripts
python tests/test_bom.py
python tests/test_slugify.py
python tests/test_sorting.py
```

## Troubleshooting

### Audio not working

- **macOS**: Ensure microphone permissions are granted in System Preferences → Security & Privacy → Privacy → Microphone
- **Windows**: Check microphone permissions in Settings → Privacy → Microphone
- **Linux**: Ensure PulseAudio or ALSA is configured correctly

### Import fails

- Check that the XML file is well-formed
- Verify the encoding matches the BOM (if present)
- Ensure entries have at least a Gloss field

### Application doesn't start

- Verify Python 3.8+ is installed
- Check that all dependencies are installed
- On Linux, ensure webkit2gtk is installed: `sudo apt-get install gir1.2-webkit2-4.0`

## License

See the repository LICENSE file for licensing information.
