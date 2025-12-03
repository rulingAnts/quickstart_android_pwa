#!/usr/bin/env python3
"""
Wordlist Elicitation Tool - Desktop Application

A pywebview-based desktop application for linguistic fieldwork.
Run with: python desktop_app/main.py
"""
import os
import sys
from datetime import datetime
from typing import List, Dict, Any, Optional

import webview

# Add app directory to path
app_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, app_dir)

from app.storage import StorageManager
from app.xml_io import parse_wordlist_from_bytes, parse_wordlist, generate_xml_utf16le
from app.audio import AudioRecorder
from app.export_zip import create_export_zip, get_export_stats
from app.utils import generate_audio_filename, normalize_reference, parse_reference_numeric


class WordlistAPI:
    """
    API exposed to JavaScript via pywebview.
    
    All methods are accessible from JS as window.pywebview.api.<method>()
    """
    
    def __init__(self):
        self.storage = StorageManager()
        self.audio_recorder = AudioRecorder()
        self._current_recording_entry_id: Optional[int] = None
    
    # Entry operations
    def load_entries(self) -> List[Dict[str, Any]]:
        """Load all entries sorted by numeric reference."""
        entries = self.storage.get_all_entries()
        # Sort by numeric reference
        entries.sort(key=lambda e: parse_reference_numeric(e.get("reference", "0")))
        return entries
    
    def import_from_file(self, path: str) -> Dict[str, Any]:
        """
        Import wordlist from a local XML file.
        
        Args:
            path: Path to XML file
            
        Returns:
            ImportSummary with count and status
        """
        try:
            with open(path, 'rb') as f:
                data = f.read()
            
            entries = parse_wordlist_from_bytes(data)
            
            if not entries:
                return {"success": False, "error": "No entries found in file", "count": 0}
            
            # Clear existing entries and audio
            self.storage.delete_all_entries()
            self.storage.delete_all_audio()
            
            # Add new entries
            for entry in entries:
                self.storage.add_entry(entry)
            
            return {"success": True, "count": len(entries), "error": None}
        
        except Exception as e:
            return {"success": False, "error": str(e), "count": 0}
    
    def import_from_url(self, url: str) -> Dict[str, Any]:
        """
        Import wordlist from a URL.
        
        Args:
            url: URL to XML file
            
        Returns:
            ImportSummary with count and status
        """
        try:
            import urllib.request
            import ssl
            
            # Create SSL context that doesn't verify certificates (for testing)
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            
            with urllib.request.urlopen(url, timeout=30, context=ctx) as response:
                data = response.read()
            
            entries = parse_wordlist_from_bytes(data)
            
            if not entries:
                return {"success": False, "error": "No entries found at URL", "count": 0}
            
            # Clear existing entries and audio
            self.storage.delete_all_entries()
            self.storage.delete_all_audio()
            
            # Add new entries
            for entry in entries:
                self.storage.add_entry(entry)
            
            return {"success": True, "count": len(entries), "error": None}
        
        except Exception as e:
            return {"success": False, "error": str(e), "count": 0}
    
    def save_transcription(self, entry_id: int, text: str) -> bool:
        """Save transcription for an entry."""
        entry = self.storage.get_entry(entry_id)
        if not entry:
            return False
        
        entry["local_transcription"] = text
        entry["is_completed"] = bool(text.strip()) or bool(entry.get("audio_filename"))
        return self.storage.update_entry(entry)
    
    # Audio operations
    def check_audio_support(self) -> Dict[str, Any]:
        """Check if audio recording is supported."""
        return AudioRecorder.check_audio_support()
    
    def start_recording(self, entry_id: int) -> bool:
        """Start recording audio for an entry."""
        self._current_recording_entry_id = entry_id
        return self.audio_recorder.start_recording()
    
    def stop_recording(self, entry_id: int) -> Dict[str, Any]:
        """
        Stop recording and save audio.
        
        Returns:
            Dict with filename or error
        """
        wav_data = self.audio_recorder.stop_recording()
        
        if not wav_data:
            return {"success": False, "error": "No audio data recorded", "filename": None}
        
        entry = self.storage.get_entry(entry_id)
        if not entry:
            return {"success": False, "error": "Entry not found", "filename": None}
        
        # Generate filename
        filename = generate_audio_filename(entry["reference"], entry["gloss"])
        
        # Save audio
        self.storage.save_audio(filename, wav_data)
        
        # Update entry
        entry["audio_filename"] = filename
        entry["recorded_at"] = datetime.utcnow().isoformat() + "Z"
        entry["is_completed"] = True
        self.storage.update_entry(entry)
        
        self._current_recording_entry_id = None
        
        return {"success": True, "filename": filename, "error": None}
    
    def play_audio(self, entry_id: int) -> bool:
        """Play audio for an entry."""
        entry = self.storage.get_entry(entry_id)
        if not entry or not entry.get("audio_filename"):
            return False
        
        audio_data = self.storage.get_audio(entry["audio_filename"])
        if not audio_data:
            return False
        
        return self.audio_recorder.play_audio(audio_data)
    
    # Export operations
    def export_zip(self, dest_path: str = None) -> Dict[str, Any]:
        """
        Export data as ZIP file.
        
        Args:
            dest_path: Optional destination path
            
        Returns:
            ExportSummary with path and counts
        """
        entries = self.load_entries()
        audio_data = self.storage.get_all_audio()
        consent_records = self.storage.get_all_consent_records()
        
        return create_export_zip(entries, audio_data, consent_records, dest_path)
    
    def get_progress(self) -> Dict[str, int]:
        """Get progress statistics."""
        return {
            "total": self.storage.get_total_count(),
            "completed": self.storage.get_completed_count(),
            "withAudio": self.storage.get_with_audio_count(),
            "transcribed": self.storage.get_with_transcription_count()
        }
    
    # Navigation operations
    def list_all_entries(self, filter_text: str = None) -> List[Dict[str, Any]]:
        """
        Get summary list of all entries for navigation panel.
        
        Args:
            filter_text: Optional text to filter by reference or gloss
            
        Returns:
            List of entry summaries (id, reference, gloss, is_completed)
        """
        entries = self.load_entries()
        
        if filter_text:
            filter_lower = filter_text.lower()
            entries = [
                e for e in entries
                if filter_lower in e.get("reference", "").lower()
                or filter_lower in e.get("gloss", "").lower()
            ]
        
        return [
            {
                "id": e["id"],
                "reference": e["reference"],
                "gloss": e["gloss"],
                "is_completed": e.get("is_completed", False)
            }
            for e in entries
        ]
    
    def jump_to(self, reference_or_index) -> Optional[Dict[str, Any]]:
        """
        Jump to an entry by reference string or index.
        
        Args:
            reference_or_index: Reference string or numeric index
            
        Returns:
            Entry dict or None if not found
        """
        entries = self.load_entries()
        
        if isinstance(reference_or_index, int):
            if 0 <= reference_or_index < len(entries):
                return entries[reference_or_index]
        else:
            # Search by reference
            ref = str(reference_or_index)
            for entry in entries:
                if entry.get("reference") == ref:
                    return entry
        
        return None
    
    def get_last_position(self) -> int:
        """Get last saved entry position."""
        pos = self.storage.get_setting("last_entry_index", "0")
        return int(pos)
    
    def set_last_position(self, index: int) -> None:
        """Save last entry position."""
        self.storage.set_setting("last_entry_index", str(index))
    
    def get_entry_by_id(self, entry_id: int) -> Optional[Dict[str, Any]]:
        """Get a single entry by ID."""
        return self.storage.get_entry(entry_id)
    
    # File dialog helpers
    def select_import_file(self) -> Optional[str]:
        """Open file dialog for XML import."""
        result = webview.windows[0].create_file_dialog(
            webview.OPEN_DIALOG,
            file_types=('XML Files (*.xml)',)
        )
        if result and len(result) > 0:
            return result[0]
        return None
    
    def select_export_path(self) -> Optional[str]:
        """Open file dialog for ZIP export."""
        result = webview.windows[0].create_file_dialog(
            webview.SAVE_DIALOG,
            save_filename="wordlist_export.zip",
            file_types=('ZIP Files (*.zip)',)
        )
        if result:
            return result
        return None


def main():
    """Launch the desktop application."""
    # Get the web directory path
    web_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "web")
    index_path = os.path.join(web_dir, "index.html")
    
    if not os.path.exists(index_path):
        print(f"Error: {index_path} not found")
        sys.exit(1)
    
    # Create API instance
    api = WordlistAPI()
    
    # Create window
    window = webview.create_window(
        "Wordlist Elicitation Tool",
        index_path,
        js_api=api,
        width=1024,
        height=768,
        min_size=(800, 600)
    )
    
    # Start webview
    webview.start(debug=False)


if __name__ == "__main__":
    main()
