#!/usr/bin/env python3
"""
Tests for UTF-16LE BOM correctness in XML export.

Tests verify:
1. BOM is present exactly once at file start
2. BOM immediately precedes XML declaration
3. No duplicate BOMs in output
"""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.xml_io import generate_xml_utf16le, validate_bom, has_valid_bom
from app.utils import UTF16LE_BOM


def test_bom_present():
    """Test that BOM is present in output."""
    entries = [
        {"reference": "0001", "gloss": "body", "local_transcription": "soma"}
    ]
    
    result = generate_xml_utf16le(entries)
    
    assert result.startswith(UTF16LE_BOM), "BOM should be at start of output"
    print("✓ BOM is present at start of output")


def test_single_bom():
    """Test that only one BOM exists in output."""
    entries = [
        {"reference": "0001", "gloss": "body", "local_transcription": "soma"},
        {"reference": "0002", "gloss": "head", "local_transcription": "kichwa"},
    ]
    
    result = generate_xml_utf16le(entries)
    
    # Count BOMs
    bom_count = result.count(UTF16LE_BOM)
    assert bom_count == 1, f"Expected exactly 1 BOM, found {bom_count}"
    print("✓ Exactly one BOM in output")


def test_bom_before_xml_declaration():
    """Test that BOM immediately precedes XML declaration."""
    entries = [
        {"reference": "0001", "gloss": "test"}
    ]
    
    result = generate_xml_utf16le(entries)
    
    # After BOM, should be XML declaration
    after_bom = result[len(UTF16LE_BOM):]
    xml_decl_le = "<?xml".encode("utf-16-le")
    
    assert after_bom.startswith(xml_decl_le), "XML declaration should follow BOM"
    print("✓ XML declaration immediately follows BOM")


def test_validate_bom_valid():
    """Test validate_bom passes for valid data."""
    entries = [{"reference": "0001", "gloss": "test"}]
    result = generate_xml_utf16le(entries)
    
    # Should not raise
    validate_bom(result)
    print("✓ validate_bom passes for valid output")


def test_validate_bom_missing():
    """Test validate_bom fails for missing BOM."""
    # Create data without BOM
    data = "<?xml version=\"1.0\"?>".encode("utf-16-le")
    
    try:
        validate_bom(data)
        assert False, "Should have raised ValueError"
    except ValueError as e:
        assert "missing" in str(e).lower()
        print("✓ validate_bom detects missing BOM")


def test_validate_bom_duplicate():
    """Test validate_bom fails for duplicate BOM."""
    entries = [{"reference": "0001", "gloss": "test"}]
    valid = generate_xml_utf16le(entries)
    
    # Add extra BOM
    invalid = UTF16LE_BOM + valid
    
    try:
        validate_bom(invalid)
        assert False, "Should have raised ValueError"
    except ValueError as e:
        assert "more than once" in str(e).lower() or "declaration" in str(e).lower()
        print("✓ validate_bom detects duplicate BOM")


def test_has_valid_bom():
    """Test has_valid_bom helper function."""
    entries = [{"reference": "0001", "gloss": "test"}]
    valid = generate_xml_utf16le(entries)
    
    assert has_valid_bom(valid) is True, "Valid data should pass"
    assert has_valid_bom(b"invalid") is False, "Invalid data should fail"
    print("✓ has_valid_bom works correctly")


def test_empty_entries():
    """Test BOM handling with empty entries list."""
    result = generate_xml_utf16le([])
    
    assert result.startswith(UTF16LE_BOM), "BOM should be present even for empty list"
    validate_bom(result)
    print("✓ BOM correct for empty entries")


def test_special_characters():
    """Test BOM handling with special characters in content."""
    entries = [
        {
            "reference": "0001",
            "gloss": "café",
            "local_transcription": "日本語テスト"
        }
    ]
    
    result = generate_xml_utf16le(entries)
    
    assert result.startswith(UTF16LE_BOM), "BOM should be present"
    validate_bom(result)
    
    # Verify content is properly encoded
    content = result[len(UTF16LE_BOM):].decode("utf-16-le")
    assert "café" in content, "Special characters should be preserved"
    assert "日本語テスト" in content, "Unicode should be preserved"
    print("✓ BOM correct with special characters")


def run_all_tests():
    """Run all BOM tests."""
    print("=" * 50)
    print("Running BOM Correctness Tests")
    print("=" * 50)
    
    tests = [
        test_bom_present,
        test_single_bom,
        test_bom_before_xml_declaration,
        test_validate_bom_valid,
        test_validate_bom_missing,
        test_validate_bom_duplicate,
        test_has_valid_bom,
        test_empty_entries,
        test_special_characters,
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            test()
            passed += 1
        except AssertionError as e:
            print(f"✗ {test.__name__}: {e}")
            failed += 1
        except Exception as e:
            print(f"✗ {test.__name__}: Unexpected error: {e}")
            failed += 1
    
    print("=" * 50)
    print(f"Results: {passed} passed, {failed} failed")
    print("=" * 50)
    
    return failed == 0


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
