"""SQLite storage for entries, audio, and consent data."""
import sqlite3
import os
from typing import Optional, Dict, Any, List
from contextlib import contextmanager
from datetime import datetime


class StorageManager:
    """Manages SQLite database for wordlist entries, audio, and consent."""
    
    def __init__(self, db_path: str = None):
        """
        Initialize storage manager.
        
        Args:
            db_path: Path to SQLite database file. Defaults to app data directory.
        """
        if db_path is None:
            app_dir = os.path.expanduser("~/.wordlist_elicitation")
            os.makedirs(app_dir, exist_ok=True)
            db_path = os.path.join(app_dir, "wordlist.db")
        
        self.db_path = db_path
        self._init_db()
    
    def _init_db(self):
        """Initialize database schema."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            
            # Entries table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS entries (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    reference TEXT NOT NULL,
                    gloss TEXT NOT NULL,
                    local_transcription TEXT DEFAULT '',
                    audio_filename TEXT,
                    picture_filename TEXT,
                    recorded_at TEXT,
                    is_completed INTEGER DEFAULT 0
                )
            """)
            
            # Audio table (stores blobs)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS audio (
                    filename TEXT PRIMARY KEY,
                    data BLOB NOT NULL,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Consent table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS consent (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    device_id TEXT,
                    type TEXT,
                    response TEXT,
                    verbal_consent_filename TEXT
                )
            """)
            
            # Settings table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS settings (
                    key TEXT PRIMARY KEY,
                    value TEXT
                )
            """)
            
            conn.commit()
    
    @contextmanager
    def _get_connection(self):
        """Context manager for database connections."""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
        finally:
            conn.close()
    
    # Entry operations
    def add_entry(self, entry: Dict[str, Any]) -> int:
        """Add a new entry and return its ID."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO entries (reference, gloss, local_transcription, audio_filename, 
                                   picture_filename, recorded_at, is_completed)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                entry.get("reference", "0000"),
                entry.get("gloss", ""),
                entry.get("local_transcription", ""),
                entry.get("audio_filename"),
                entry.get("picture_filename"),
                entry.get("recorded_at"),
                1 if entry.get("is_completed") else 0
            ))
            conn.commit()
            return cursor.lastrowid
    
    def get_all_entries(self) -> List[Dict[str, Any]]:
        """Get all entries sorted by numeric reference."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM entries ORDER BY id")
            rows = cursor.fetchall()
            return [self._row_to_dict(row) for row in rows]
    
    def get_entry(self, entry_id: int) -> Optional[Dict[str, Any]]:
        """Get a single entry by ID."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM entries WHERE id = ?", (entry_id,))
            row = cursor.fetchone()
            return self._row_to_dict(row) if row else None
    
    def update_entry(self, entry: Dict[str, Any]) -> bool:
        """Update an existing entry."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE entries SET 
                    reference = ?, gloss = ?, local_transcription = ?,
                    audio_filename = ?, picture_filename = ?, recorded_at = ?, is_completed = ?
                WHERE id = ?
            """, (
                entry.get("reference", "0000"),
                entry.get("gloss", ""),
                entry.get("local_transcription", ""),
                entry.get("audio_filename"),
                entry.get("picture_filename"),
                entry.get("recorded_at"),
                1 if entry.get("is_completed") else 0,
                entry.get("id")
            ))
            conn.commit()
            return cursor.rowcount > 0
    
    def delete_all_entries(self) -> None:
        """Delete all entries."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM entries")
            conn.commit()
    
    def get_total_count(self) -> int:
        """Get total number of entries."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM entries")
            return cursor.fetchone()[0]
    
    def get_completed_count(self) -> int:
        """Get number of completed entries."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM entries WHERE is_completed = 1")
            return cursor.fetchone()[0]
    
    def get_with_audio_count(self) -> int:
        """Get number of entries with audio."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM entries WHERE audio_filename IS NOT NULL")
            return cursor.fetchone()[0]
    
    def get_with_transcription_count(self) -> int:
        """Get number of entries with transcription."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM entries WHERE local_transcription != ''")
            return cursor.fetchone()[0]
    
    # Audio operations
    def save_audio(self, filename: str, data: bytes) -> None:
        """Save audio data."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT OR REPLACE INTO audio (filename, data, created_at)
                VALUES (?, ?, ?)
            """, (filename, data, datetime.utcnow().isoformat()))
            conn.commit()
    
    def get_audio(self, filename: str) -> Optional[bytes]:
        """Get audio data by filename."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT data FROM audio WHERE filename = ?", (filename,))
            row = cursor.fetchone()
            return row[0] if row else None
    
    def get_all_audio(self) -> List[Dict[str, Any]]:
        """Get all audio records."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT filename, data FROM audio")
            return [{"filename": row[0], "data": row[1]} for row in cursor.fetchall()]
    
    def delete_all_audio(self) -> None:
        """Delete all audio data."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM audio")
            conn.commit()
    
    # Consent operations
    def add_consent_record(self, record: Dict[str, Any]) -> int:
        """Add a consent record and return its ID."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO consent (timestamp, device_id, type, response, verbal_consent_filename)
                VALUES (?, ?, ?, ?, ?)
            """, (
                record.get("timestamp", datetime.utcnow().isoformat()),
                record.get("device_id"),
                record.get("type"),
                record.get("response"),
                record.get("verbal_consent_filename")
            ))
            conn.commit()
            return cursor.lastrowid
    
    def get_all_consent_records(self) -> List[Dict[str, Any]]:
        """Get all consent records."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM consent ORDER BY timestamp")
            rows = cursor.fetchall()
            return [self._row_to_dict(row) for row in rows]
    
    # Settings operations
    def set_setting(self, key: str, value: str) -> None:
        """Set a setting value."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)
            """, (key, value))
            conn.commit()
    
    def get_setting(self, key: str, default: str = None) -> Optional[str]:
        """Get a setting value."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT value FROM settings WHERE key = ?", (key,))
            row = cursor.fetchone()
            return row[0] if row else default
    
    def _row_to_dict(self, row: sqlite3.Row) -> Dict[str, Any]:
        """Convert a sqlite3.Row to a dictionary."""
        if row is None:
            return None
        d = dict(row)
        # Convert is_completed to boolean
        if "is_completed" in d:
            d["is_completed"] = bool(d["is_completed"])
        return d
