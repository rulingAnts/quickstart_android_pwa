"""ZIP export functionality for wordlist data."""
import zipfile
import json
import os
from typing import Dict, Any, List, Optional
from datetime import datetime
from io import BytesIO

from .xml_io import generate_xml_utf16le


APP_VERSION = "2.0.0"


def create_export_zip(
    entries: List[Dict[str, Any]],
    audio_data: List[Dict[str, Any]],
    consent_records: List[Dict[str, Any]],
    dest_path: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create an export ZIP file containing wordlist data.
    
    Args:
        entries: List of entry dictionaries
        audio_data: List of dicts with 'filename' and 'data' keys
        consent_records: List of consent record dictionaries
        dest_path: Optional destination path. If None, generates timestamped filename.
        
    Returns:
        ExportSummary dict with path, counts, and status
    """
    # Generate destination path if not provided
    if dest_path is None:
        now = datetime.now()
        timestamp = now.strftime("%Y%m%d_%H%M%S")
        dest_path = f"wordlist_export_{timestamp}.zip"
    
    # Ensure .zip extension
    if not dest_path.endswith(".zip"):
        dest_path += ".zip"
    
    # Create ZIP in memory first, then write to file
    zip_buffer = BytesIO()
    
    try:
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
            # Add wordlist.xml with UTF-16LE BOM
            xml_data = generate_xml_utf16le(entries)
            zf.writestr("wordlist.xml", xml_data)
            
            # Add audio files
            for audio in audio_data:
                if audio.get("data"):
                    zf.writestr(f"audio/{audio['filename']}", audio["data"])
            
            # Add consent log if records exist
            if consent_records:
                consent_json = generate_consent_json(consent_records)
                zf.writestr("consent_log.json", consent_json)
            
            # Add metadata
            metadata_json = generate_metadata_json(entries)
            zf.writestr("metadata.json", metadata_json)
        
        # Write to file
        zip_buffer.seek(0)
        with open(dest_path, 'wb') as f:
            f.write(zip_buffer.read())
        
        # Calculate stats
        completed_count = sum(1 for e in entries if e.get("is_completed"))
        audio_count = sum(1 for e in entries if e.get("audio_filename"))
        transcription_count = sum(1 for e in entries if e.get("local_transcription"))
        
        return {
            "success": True,
            "path": os.path.abspath(dest_path),
            "total_entries": len(entries),
            "completed_entries": completed_count,
            "entries_with_audio": audio_count,
            "entries_with_transcription": transcription_count,
            "audio_files_included": len(audio_data),
            "consent_records_included": len(consent_records)
        }
    
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "path": None
        }


def generate_consent_json(records: List[Dict[str, Any]]) -> str:
    """Generate consent log JSON."""
    return json.dumps({
        "generatedAt": datetime.utcnow().isoformat() + "Z",
        "records": [
            {
                "id": r.get("id"),
                "timestamp": r.get("timestamp"),
                "deviceId": r.get("device_id"),
                "type": r.get("type"),
                "response": r.get("response"),
                "verbalConsentFilename": r.get("verbal_consent_filename")
            }
            for r in records
        ]
    }, indent=2)


def generate_metadata_json(entries: List[Dict[str, Any]]) -> str:
    """Generate export metadata JSON."""
    return json.dumps({
        "exportedAt": datetime.utcnow().isoformat() + "Z",
        "appVersion": APP_VERSION,
        "totalEntries": len(entries),
        "completedEntries": sum(1 for e in entries if e.get("is_completed")),
        "entriesWithAudio": sum(1 for e in entries if e.get("audio_filename")),
        "entriesWithTranscription": sum(1 for e in entries if e.get("local_transcription"))
    }, indent=2)


def get_export_stats(entries: List[Dict[str, Any]]) -> Dict[str, int]:
    """
    Get statistics for export preview.
    
    Args:
        entries: List of entry dictionaries
        
    Returns:
        Dict with total, completed, withAudio, transcribed counts
    """
    return {
        "total": len(entries),
        "completed": sum(1 for e in entries if e.get("is_completed")),
        "withAudio": sum(1 for e in entries if e.get("audio_filename")),
        "transcribed": sum(1 for e in entries if e.get("local_transcription"))
    }
