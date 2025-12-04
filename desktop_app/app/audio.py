"""Audio recording and playback with 16-bit PCM WAV support."""
import struct
import wave
import os
import tempfile
import threading
from typing import Optional, Callable
from datetime import datetime

# Optional imports for audio capture
try:
    import sounddevice as sd
    import numpy as np
    SOUNDDEVICE_AVAILABLE = True
except ImportError:
    SOUNDDEVICE_AVAILABLE = False

try:
    import pyaudio
    PYAUDIO_AVAILABLE = True
except ImportError:
    PYAUDIO_AVAILABLE = False


class AudioRecorder:
    """Records and plays back 16-bit PCM WAV audio."""
    
    # Audio settings
    SAMPLE_RATE = 44100
    CHANNELS = 1
    SAMPLE_WIDTH = 2  # 16-bit = 2 bytes
    BITS_PER_SAMPLE = 16
    
    def __init__(self):
        self.is_recording = False
        self._recorded_data = []
        self._recording_thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()
        self._playback_thread: Optional[threading.Thread] = None
        self._current_stream = None
    
    @staticmethod
    def check_audio_support() -> dict:
        """
        Check audio recording/playback support.
        
        Returns:
            Dict with 'supported' bool and 'message' string
        """
        if SOUNDDEVICE_AVAILABLE:
            try:
                devices = sd.query_devices()
                input_devices = [d for d in devices if d['max_input_channels'] > 0]
                if input_devices:
                    return {"supported": True, "message": "Audio supported via sounddevice"}
                return {"supported": False, "message": "No input devices found"}
            except Exception as e:
                return {"supported": False, "message": f"sounddevice error: {e}"}
        
        if PYAUDIO_AVAILABLE:
            try:
                p = pyaudio.PyAudio()
                device_count = p.get_device_count()
                p.terminate()
                if device_count > 0:
                    return {"supported": True, "message": "Audio supported via PyAudio"}
                return {"supported": False, "message": "No audio devices found"}
            except Exception as e:
                return {"supported": False, "message": f"PyAudio error: {e}"}
        
        return {
            "supported": False,
            "message": "No audio library available. Install sounddevice or pyaudio."
        }
    
    def start_recording(self) -> bool:
        """
        Start audio recording.
        
        Returns:
            True if recording started successfully
        """
        if self.is_recording:
            return False
        
        self._recorded_data = []
        self._stop_event.clear()
        
        if SOUNDDEVICE_AVAILABLE:
            self._recording_thread = threading.Thread(target=self._record_sounddevice)
        elif PYAUDIO_AVAILABLE:
            self._recording_thread = threading.Thread(target=self._record_pyaudio)
        else:
            return False
        
        self._recording_thread.start()
        self.is_recording = True
        return True
    
    def stop_recording(self) -> Optional[bytes]:
        """
        Stop recording and return WAV data.
        
        Returns:
            16-bit PCM WAV data as bytes, or None if not recording
        """
        if not self.is_recording:
            return None
        
        self._stop_event.set()
        
        if self._recording_thread:
            self._recording_thread.join(timeout=2.0)
            self._recording_thread = None
        
        self.is_recording = False
        
        if not self._recorded_data:
            return None
        
        return self._create_wav(self._recorded_data)
    
    def _record_sounddevice(self):
        """Record audio using sounddevice."""
        chunk_size = 1024
        
        def callback(indata, frames, time_info, status):
            if not self._stop_event.is_set():
                self._recorded_data.append(indata.copy())
        
        try:
            with sd.InputStream(
                samplerate=self.SAMPLE_RATE,
                channels=self.CHANNELS,
                dtype='int16',
                blocksize=chunk_size,
                callback=callback
            ):
                while not self._stop_event.is_set():
                    self._stop_event.wait(0.1)
        except Exception as e:
            print(f"Recording error: {e}")
    
    def _record_pyaudio(self):
        """Record audio using PyAudio."""
        p = pyaudio.PyAudio()
        chunk_size = 1024
        
        try:
            stream = p.open(
                format=pyaudio.paInt16,
                channels=self.CHANNELS,
                rate=self.SAMPLE_RATE,
                input=True,
                frames_per_buffer=chunk_size
            )
            
            while not self._stop_event.is_set():
                data = stream.read(chunk_size, exception_on_overflow=False)
                self._recorded_data.append(data)
            
            stream.stop_stream()
            stream.close()
        except Exception as e:
            print(f"Recording error: {e}")
        finally:
            p.terminate()
    
    def _create_wav(self, audio_data) -> bytes:
        """
        Create WAV file from recorded audio data.
        
        Returns:
            Complete WAV file as bytes
        """
        # Combine all audio chunks
        if SOUNDDEVICE_AVAILABLE and len(audio_data) > 0 and hasattr(audio_data[0], 'tobytes'):
            # numpy arrays from sounddevice
            raw_data = b''.join(chunk.tobytes() for chunk in audio_data)
        else:
            # bytes from pyaudio
            raw_data = b''.join(audio_data)
        
        # Create WAV in memory
        import io
        buffer = io.BytesIO()
        
        with wave.open(buffer, 'wb') as wf:
            wf.setnchannels(self.CHANNELS)
            wf.setsampwidth(self.SAMPLE_WIDTH)
            wf.setframerate(self.SAMPLE_RATE)
            wf.writeframes(raw_data)
        
        return buffer.getvalue()
    
    def play_audio(self, wav_data: bytes, on_complete: Optional[Callable] = None) -> bool:
        """
        Play WAV audio data.
        
        Args:
            wav_data: WAV file data as bytes
            on_complete: Optional callback when playback finishes
            
        Returns:
            True if playback started successfully
        """
        if SOUNDDEVICE_AVAILABLE:
            self._playback_thread = threading.Thread(
                target=self._play_sounddevice,
                args=(wav_data, on_complete)
            )
            self._playback_thread.start()
            return True
        
        if PYAUDIO_AVAILABLE:
            self._playback_thread = threading.Thread(
                target=self._play_pyaudio,
                args=(wav_data, on_complete)
            )
            self._playback_thread.start()
            return True
        
        return False
    
    def _play_sounddevice(self, wav_data: bytes, on_complete: Optional[Callable]):
        """Play audio using sounddevice."""
        import io
        try:
            buffer = io.BytesIO(wav_data)
            with wave.open(buffer, 'rb') as wf:
                samplerate = wf.getframerate()
                channels = wf.getnchannels()
                frames = wf.readframes(wf.getnframes())
            
            audio_array = np.frombuffer(frames, dtype=np.int16)
            if channels > 1:
                audio_array = audio_array.reshape(-1, channels)
            
            sd.play(audio_array, samplerate)
            sd.wait()
            
            if on_complete:
                on_complete()
        except Exception as e:
            print(f"Playback error: {e}")
    
    def _play_pyaudio(self, wav_data: bytes, on_complete: Optional[Callable]):
        """Play audio using PyAudio."""
        import io
        p = pyaudio.PyAudio()
        
        try:
            buffer = io.BytesIO(wav_data)
            wf = wave.open(buffer, 'rb')
            
            stream = p.open(
                format=p.get_format_from_width(wf.getsampwidth()),
                channels=wf.getnchannels(),
                rate=wf.getframerate(),
                output=True
            )
            
            chunk_size = 1024
            data = wf.readframes(chunk_size)
            
            while data:
                stream.write(data)
                data = wf.readframes(chunk_size)
            
            stream.stop_stream()
            stream.close()
            wf.close()
            
            if on_complete:
                on_complete()
        except Exception as e:
            print(f"Playback error: {e}")
        finally:
            p.terminate()
    
    def cleanup(self):
        """Clean up resources."""
        if self.is_recording:
            self.stop_recording()


def validate_wav_16bit(wav_data: bytes) -> bool:
    """
    Validate that WAV data is 16-bit PCM.
    
    Args:
        wav_data: WAV file data as bytes
        
    Returns:
        True if valid 16-bit PCM WAV
    """
    import io
    try:
        buffer = io.BytesIO(wav_data)
        with wave.open(buffer, 'rb') as wf:
            return wf.getsampwidth() == 2  # 16-bit = 2 bytes
    except Exception:
        return False
