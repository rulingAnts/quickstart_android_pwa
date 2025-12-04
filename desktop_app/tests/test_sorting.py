#!/usr/bin/env python3
"""
Tests for numeric reference sorting in XML import.

Tests verify:
1. Entries are sorted by numeric reference value
2. Non-numeric characters are stripped for sorting
3. Padded and non-padded references sort correctly
4. Edge cases handled (empty, non-numeric)
"""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.xml_io import parse_wordlist
from app.utils import parse_reference_numeric


def test_parse_reference_numeric():
    """Test numeric parsing of reference strings."""
    assert parse_reference_numeric("1") == 1
    assert parse_reference_numeric("0001") == 1
    assert parse_reference_numeric("42") == 42
    assert parse_reference_numeric("0042") == 42
    assert parse_reference_numeric("123") == 123
    print("✓ Basic numeric parsing works")


def test_parse_reference_with_text():
    """Test numeric parsing with text in reference."""
    assert parse_reference_numeric("ref-1") == 1
    assert parse_reference_numeric("item_42_a") == 42
    assert parse_reference_numeric("abc123def456") == 123456
    print("✓ Numeric parsing extracts digits from text")


def test_parse_reference_empty():
    """Test numeric parsing of empty/non-numeric strings."""
    assert parse_reference_numeric("") == 0
    assert parse_reference_numeric("abc") == 0
    assert parse_reference_numeric("no-numbers") == 0
    print("✓ Empty/non-numeric returns 0")


def test_basic_sorting():
    """Test basic numeric sorting of entries."""
    xml = """<?xml version="1.0"?>
    <Wordlist>
        <Word><Reference>0003</Reference><Gloss>third</Gloss></Word>
        <Word><Reference>0001</Reference><Gloss>first</Gloss></Word>
        <Word><Reference>0002</Reference><Gloss>second</Gloss></Word>
    </Wordlist>"""
    
    entries = parse_wordlist(xml)
    
    assert len(entries) == 3
    assert entries[0]["reference"] == "0001"
    assert entries[1]["reference"] == "0002"
    assert entries[2]["reference"] == "0003"
    print("✓ Basic sorting works")


def test_mixed_padding_sorting():
    """Test sorting with mixed padding."""
    xml = """<?xml version="1.0"?>
    <Wordlist>
        <Word><Reference>10</Reference><Gloss>ten</Gloss></Word>
        <Word><Reference>0002</Reference><Gloss>two</Gloss></Word>
        <Word><Reference>1</Reference><Gloss>one</Gloss></Word>
    </Wordlist>"""
    
    entries = parse_wordlist(xml)
    
    # Should sort numerically: 1, 2, 10
    assert entries[0]["gloss"] == "one"
    assert entries[1]["gloss"] == "two"
    assert entries[2]["gloss"] == "ten"
    print("✓ Mixed padding sorting works")


def test_large_number_sorting():
    """Test sorting with large numbers."""
    xml = """<?xml version="1.0"?>
    <Wordlist>
        <Word><Reference>1000</Reference><Gloss>thousand</Gloss></Word>
        <Word><Reference>100</Reference><Gloss>hundred</Gloss></Word>
        <Word><Reference>10</Reference><Gloss>ten</Gloss></Word>
        <Word><Reference>1</Reference><Gloss>one</Gloss></Word>
    </Wordlist>"""
    
    entries = parse_wordlist(xml)
    
    assert entries[0]["gloss"] == "one"
    assert entries[1]["gloss"] == "ten"
    assert entries[2]["gloss"] == "hundred"
    assert entries[3]["gloss"] == "thousand"
    print("✓ Large number sorting works")


def test_reference_normalization():
    """Test that references are normalized to 4 digits."""
    xml = """<?xml version="1.0"?>
    <Wordlist>
        <Word><Reference>1</Reference><Gloss>one</Gloss></Word>
        <Word><Reference>42</Reference><Gloss>fortytwo</Gloss></Word>
    </Wordlist>"""
    
    entries = parse_wordlist(xml)
    
    assert entries[0]["reference"] == "0001"
    assert entries[1]["reference"] == "0042"
    print("✓ Reference normalization to 4 digits works")


def test_missing_reference():
    """Test that missing references get auto-generated."""
    xml = """<?xml version="1.0"?>
    <Wordlist>
        <Word><Gloss>no-ref-1</Gloss></Word>
        <Word><Gloss>no-ref-2</Gloss></Word>
    </Wordlist>"""
    
    entries = parse_wordlist(xml)
    
    assert len(entries) == 2
    # Should have generated references
    assert entries[0]["reference"].isdigit()
    assert entries[1]["reference"].isdigit()
    print("✓ Missing reference auto-generation works")


def test_duplicate_references():
    """Test handling of duplicate references."""
    xml = """<?xml version="1.0"?>
    <Wordlist>
        <Word><Reference>0001</Reference><Gloss>first</Gloss></Word>
        <Word><Reference>0001</Reference><Gloss>also-first</Gloss></Word>
        <Word><Reference>0002</Reference><Gloss>second</Gloss></Word>
    </Wordlist>"""
    
    entries = parse_wordlist(xml)
    
    # All entries should be kept
    assert len(entries) == 3
    # Duplicates should be adjacent after sorting
    assert entries[0]["reference"] == "0001"
    assert entries[1]["reference"] == "0001"
    assert entries[2]["reference"] == "0002"
    print("✓ Duplicate references handled")


def test_alternative_element_names():
    """Test sorting with alternative element names."""
    xml = """<?xml version="1.0"?>
    <phon_data>
        <data_form><Reference>3</Reference><Gloss>three</Gloss></data_form>
        <data_form><Reference>1</Reference><Gloss>one</Gloss></data_form>
        <data_form><Reference>2</Reference><Gloss>two</Gloss></data_form>
    </phon_data>"""
    
    entries = parse_wordlist(xml)
    
    assert len(entries) == 3
    assert entries[0]["gloss"] == "one"
    assert entries[1]["gloss"] == "two"
    assert entries[2]["gloss"] == "three"
    print("✓ Alternative element names work with sorting")


def test_empty_wordlist():
    """Test parsing empty wordlist."""
    xml = """<?xml version="1.0"?><Wordlist></Wordlist>"""
    
    entries = parse_wordlist(xml)
    
    assert len(entries) == 0
    print("✓ Empty wordlist handled")


def test_entries_without_gloss():
    """Test that entries without gloss are filtered out."""
    xml = """<?xml version="1.0"?>
    <Wordlist>
        <Word><Reference>1</Reference><Gloss>valid</Gloss></Word>
        <Word><Reference>2</Reference></Word>
        <Word><Reference>3</Reference><Gloss>also-valid</Gloss></Word>
    </Wordlist>"""
    
    entries = parse_wordlist(xml)
    
    # Entry without gloss should be filtered
    assert len(entries) == 2
    assert entries[0]["gloss"] == "valid"
    assert entries[1]["gloss"] == "also-valid"
    print("✓ Entries without gloss filtered")


def run_all_tests():
    """Run all sorting tests."""
    print("=" * 50)
    print("Running Reference Sorting Tests")
    print("=" * 50)
    
    tests = [
        test_parse_reference_numeric,
        test_parse_reference_with_text,
        test_parse_reference_empty,
        test_basic_sorting,
        test_mixed_padding_sorting,
        test_large_number_sorting,
        test_reference_normalization,
        test_missing_reference,
        test_duplicate_references,
        test_alternative_element_names,
        test_empty_wordlist,
        test_entries_without_gloss,
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
