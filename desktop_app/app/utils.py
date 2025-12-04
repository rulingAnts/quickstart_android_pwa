"""Utility functions for filename generation, slugification, and encoding detection."""
import re
from typing import Tuple


# UTF-16 BOM markers
UTF16LE_BOM = b"\xFF\xFE"
UTF16BE_BOM = b"\xFE\xFF"
UTF8_BOM = b"\xEF\xBB\xBF"


def slugify_gloss(gloss: str) -> str:
    """
    Convert a gloss string to a valid filename slug.
    
    Rules:
    - Convert to lowercase
    - Replace spaces with dots
    - Strip characters not in [a-z0-9._-]
    - Max 64 characters
    
    Args:
        gloss: The gloss string to slugify
        
    Returns:
        A slugified string suitable for filenames
    """
    if not gloss:
        return ""
    
    slug = gloss.lower()
    slug = slug.replace(" ", ".")
    slug = re.sub(r"[^a-z0-9._-]", "", slug)
    return slug[:64]


def generate_audio_filename(reference: str, gloss: str) -> str:
    """
    Generate a valid audio filename from reference and gloss.
    
    Format: ${reference}_${slug(gloss)}.wav
    
    Args:
        reference: The entry reference number (will be padded to 4 digits)
        gloss: The gloss string
        
    Returns:
        A valid audio filename
    """
    padded_ref = str(reference).zfill(4)
    slug = slugify_gloss(gloss)
    return f"{padded_ref}_{slug}.wav"


def detect_encoding(data: bytes) -> Tuple[str, int]:
    """
    Detect the encoding of a byte sequence by examining BOM.
    
    Args:
        data: Raw bytes to examine
        
    Returns:
        Tuple of (encoding_name, bom_length)
    """
    if data.startswith(UTF16LE_BOM):
        return ("utf-16-le", 2)
    elif data.startswith(UTF16BE_BOM):
        return ("utf-16-be", 2)
    elif data.startswith(UTF8_BOM):
        return ("utf-8", 3)
    else:
        return ("utf-8", 0)


def decode_text(data: bytes) -> str:
    """
    Decode bytes to string, detecting encoding from BOM.
    
    Args:
        data: Raw bytes to decode
        
    Returns:
        Decoded string
    """
    encoding, bom_len = detect_encoding(data)
    return data[bom_len:].decode(encoding)


def normalize_reference(reference: str) -> str:
    """
    Normalize a reference to 4-digit padded string.
    
    Strips non-digit characters and pads to 4 digits.
    
    Args:
        reference: Raw reference string
        
    Returns:
        Normalized 4-digit reference string
    """
    digits = re.sub(r"\D", "", reference)
    if not digits:
        return "0000"
    return digits.zfill(4)


def parse_reference_numeric(reference: str) -> int:
    """
    Parse a reference string to integer for sorting.
    
    Args:
        reference: Reference string (may contain non-digits)
        
    Returns:
        Integer value of the reference
    """
    digits = re.sub(r"\D", "", reference)
    if not digits:
        return 0
    return int(digits)
