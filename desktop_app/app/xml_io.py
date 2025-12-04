"""XML import/export with UTF-8/UTF-16 encoding support and BOM handling."""
import xml.etree.ElementTree as ET
from typing import List, Dict, Any, Optional
from .utils import (
    detect_encoding, decode_text, normalize_reference, 
    parse_reference_numeric, UTF16LE_BOM
)


def escape_xml(text: str) -> str:
    """Escape special characters for XML content."""
    if not text:
        return ""
    return (str(text)
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;")
            .replace("'", "&apos;"))


def parse_wordlist_from_bytes(data: bytes) -> List[Dict[str, Any]]:
    """
    Parse a wordlist XML from raw bytes, detecting encoding.
    
    Args:
        data: Raw bytes of XML file
        
    Returns:
        List of entry dictionaries, sorted by numeric reference
    """
    text = decode_text(data)
    return parse_wordlist(text)


def parse_wordlist(xml_string: str) -> List[Dict[str, Any]]:
    """
    Parse a wordlist XML string.
    
    Tolerant parsing that handles multiple XML schemas.
    
    Args:
        xml_string: XML content as string
        
    Returns:
        List of entry dictionaries, sorted by numeric reference
    """
    try:
        root = ET.fromstring(xml_string)
    except ET.ParseError as e:
        raise ValueError(f"XML parse error: {e}")
    
    # Find word elements - try multiple element names
    elements = find_word_elements(root)
    
    entries = []
    for i, el in enumerate(elements):
        entry = parse_word_element(el, i)
        if entry:
            entries.append(entry)
    
    # Sort by numeric reference ascending
    entries.sort(key=lambda e: parse_reference_numeric(e["reference"]))
    
    return entries


def find_word_elements(root: ET.Element) -> List[ET.Element]:
    """
    Find word/entry elements in XML tree.
    
    Tries multiple element names for compatibility.
    """
    element_names = ["Word", "Entry", "Item", "word", "entry", "item", "data_form"]
    
    for name in element_names:
        elements = root.findall(f".//{name}")
        if elements:
            return elements
    
    # Fallback: direct children of root
    return list(root)


def parse_word_element(el: ET.Element, index: int) -> Optional[Dict[str, Any]]:
    """
    Parse a single word element into an entry dictionary.
    
    Args:
        el: XML element representing a word entry
        index: Position index for default reference
        
    Returns:
        Entry dictionary or None if no gloss found
    """
    reference = get_text(el, ["Reference", "Ref", "Number", "reference", "ref", "number"])
    gloss = get_text(el, ["Gloss", "English", "Word", "gloss", "english", "word"])
    picture = get_text(el, ["Picture", "Image", "picture", "image"])
    local_transcription = get_text(el, ["LocalTranscription", "local_transcription", "Transcription"])
    sound_file = get_text(el, ["SoundFile", "sound_file", "Audio", "audio"])
    recorded_at = get_text(el, ["RecordedAt", "recorded_at"])
    
    if not gloss:
        return None
    
    return {
        "reference": normalize_reference(reference) if reference else str(index + 1).zfill(4),
        "gloss": gloss,
        "local_transcription": local_transcription or "",
        "audio_filename": sound_file if sound_file else None,
        "picture_filename": picture if picture else None,
        "recorded_at": recorded_at if recorded_at else None,
        "is_completed": bool(local_transcription or sound_file)
    }


def get_text(parent: ET.Element, names: List[str]) -> str:
    """Get text content from first matching child element."""
    for name in names:
        el = parent.find(name)
        if el is not None and el.text:
            return el.text.strip()
    return ""


def generate_xml_utf16le(entries: List[Dict[str, Any]]) -> bytes:
    """
    Generate XML as UTF-16LE bytes WITH SINGLE BOM.
    
    Uses <phon_data> root with <data_form> entries per spec.
    
    Args:
        entries: List of entry dictionaries
        
    Returns:
        UTF-16LE encoded bytes with BOM
    """
    xml_str = generate_xml_string(entries)
    
    # Encode as UTF-16LE without BOM first
    xml_bytes = xml_str.encode("utf-16-le")
    
    # Ensure single BOM at start
    final = UTF16LE_BOM + xml_bytes
    
    # Validation: ensure BOM is present exactly once and precedes XML declaration
    validate_bom(final)
    
    return final


def generate_xml_string(entries: List[Dict[str, Any]]) -> str:
    """
    Generate XML string with UTF-16 declaration.
    
    Uses <phon_data> root with <data_form> entries per spec.
    """
    xml = '<?xml version="1.0" encoding="UTF-16"?>\n<phon_data>\n'
    
    for entry in entries:
        xml += "  <data_form>\n"
        xml += f"    <Reference>{escape_xml(entry.get('reference', ''))}</Reference>\n"
        xml += f"    <Gloss>{escape_xml(entry.get('gloss', ''))}</Gloss>\n"
        
        if entry.get("local_transcription"):
            xml += f"    <LocalTranscription>{escape_xml(entry['local_transcription'])}</LocalTranscription>\n"
        
        if entry.get("audio_filename"):
            xml += f"    <SoundFile>{escape_xml(entry['audio_filename'])}</SoundFile>\n"
        
        if entry.get("picture_filename"):
            xml += f"    <Picture>{escape_xml(entry['picture_filename'])}</Picture>\n"
        
        if entry.get("recorded_at"):
            xml += f"    <RecordedAt>{escape_xml(entry['recorded_at'])}</RecordedAt>\n"
        
        xml += "  </data_form>\n"
    
    xml += "</phon_data>"
    return xml


def validate_bom(data: bytes) -> None:
    """
    Validate that UTF-16LE data has exactly one BOM at the start.
    
    Raises:
        ValueError: If BOM is missing, duplicated, or misplaced
    """
    if not data.startswith(UTF16LE_BOM):
        raise ValueError("UTF-16LE BOM is missing")
    
    # Check that BOM appears only at start
    rest = data[len(UTF16LE_BOM):]
    if UTF16LE_BOM in rest:
        raise ValueError("UTF-16LE BOM appears more than once")
    
    # Check that XML declaration follows BOM
    xml_decl_le = "<?xml".encode("utf-16-le")
    if not rest.startswith(xml_decl_le):
        raise ValueError("XML declaration must immediately follow BOM")


def has_valid_bom(data: bytes) -> bool:
    """
    Check if data has a valid single BOM.
    
    Args:
        data: Bytes to check
        
    Returns:
        True if data starts with BOM and XML declaration
    """
    try:
        validate_bom(data)
        return True
    except ValueError:
        return False
