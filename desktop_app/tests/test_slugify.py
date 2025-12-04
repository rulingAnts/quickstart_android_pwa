#!/usr/bin/env python3
"""
Tests for slugify and filename generation rules.

Tests verify:
1. Lowercase conversion
2. Spaces converted to dots
3. Non-alphanumeric characters stripped (except . _ -)
4. Max 64 character limit
5. Audio filename format: {reference}_{slug}.wav
"""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.utils import slugify_gloss, generate_audio_filename, normalize_reference


def test_lowercase():
    """Test that gloss is converted to lowercase."""
    assert slugify_gloss("HELLO") == "hello"
    assert slugify_gloss("Hello World") == "hello.world"
    assert slugify_gloss("MiXeD CaSe") == "mixed.case"
    print("✓ Lowercase conversion works")


def test_spaces_to_dots():
    """Test that spaces are converted to dots."""
    assert slugify_gloss("hello world") == "hello.world"
    assert slugify_gloss("one two three") == "one.two.three"
    assert slugify_gloss("multiple   spaces") == "multiple...spaces"
    print("✓ Spaces converted to dots")


def test_strip_special_characters():
    """Test that special characters are stripped."""
    assert slugify_gloss("hello!") == "hello"
    assert slugify_gloss("café") == "caf"  # é is stripped
    assert slugify_gloss("test@#$%") == "test"
    assert slugify_gloss("hello(world)") == "helloworld"
    print("✓ Special characters stripped")


def test_preserve_allowed_characters():
    """Test that allowed characters are preserved."""
    assert slugify_gloss("hello-world") == "hello-world"
    assert slugify_gloss("hello_world") == "hello_world"
    assert slugify_gloss("hello.world") == "hello.world"
    assert slugify_gloss("test123") == "test123"
    print("✓ Allowed characters preserved (. _ - 0-9)")


def test_max_length():
    """Test that output is limited to 64 characters."""
    long_string = "a" * 100
    result = slugify_gloss(long_string)
    assert len(result) <= 64, f"Length {len(result)} exceeds 64"
    assert result == "a" * 64
    print("✓ Max length 64 enforced")


def test_empty_input():
    """Test handling of empty input."""
    assert slugify_gloss("") == ""
    assert slugify_gloss(None) == ""
    print("✓ Empty input handled")


def test_numbers_only():
    """Test handling of numeric input."""
    assert slugify_gloss("123") == "123"
    assert slugify_gloss("456 789") == "456.789"
    print("✓ Numbers handled correctly")


def test_all_special_chars():
    """Test input with all special characters."""
    assert slugify_gloss("!@#$%^&*()") == ""
    assert slugify_gloss("日本語") == ""  # Non-ASCII stripped
    print("✓ All-special-char input handled")


def test_generate_audio_filename_basic():
    """Test basic audio filename generation."""
    result = generate_audio_filename("1", "body")
    assert result == "0001_body.wav"
    print("✓ Basic audio filename generation works")


def test_generate_audio_filename_padding():
    """Test reference padding in filename."""
    assert generate_audio_filename("1", "test") == "0001_test.wav"
    assert generate_audio_filename("12", "test") == "0012_test.wav"
    assert generate_audio_filename("123", "test") == "0123_test.wav"
    assert generate_audio_filename("1234", "test") == "1234_test.wav"
    assert generate_audio_filename("12345", "test") == "12345_test.wav"
    print("✓ Reference padding works")


def test_generate_audio_filename_complex():
    """Test filename with complex gloss."""
    result = generate_audio_filename("42", "Hello World!")
    assert result == "0042_hello.world.wav"
    print("✓ Complex gloss handling works")


def test_normalize_reference():
    """Test reference normalization."""
    assert normalize_reference("1") == "0001"
    assert normalize_reference("12") == "0012"
    assert normalize_reference("0001") == "0001"
    assert normalize_reference("abc123def") == "0123"  # Strips non-digits
    assert normalize_reference("") == "0000"
    assert normalize_reference("no-digits") == "0000"
    print("✓ Reference normalization works")


def test_real_world_examples():
    """Test with real-world linguistic data."""
    examples = [
        ("body", "body"),
        ("head (anatomy)", "head.anatomy"),
        ("father's brother", "fathers.brother"),
        ("water/rain", "waterrain"),
        ("1st person singular", "1st.person.singular"),
    ]
    
    for input_gloss, expected in examples:
        result = slugify_gloss(input_gloss)
        assert result == expected, f"'{input_gloss}' -> '{result}', expected '{expected}'"
    
    print("✓ Real-world examples pass")


def run_all_tests():
    """Run all slugify tests."""
    print("=" * 50)
    print("Running Slugify and Filename Tests")
    print("=" * 50)
    
    tests = [
        test_lowercase,
        test_spaces_to_dots,
        test_strip_special_characters,
        test_preserve_allowed_characters,
        test_max_length,
        test_empty_input,
        test_numbers_only,
        test_all_special_chars,
        test_generate_audio_filename_basic,
        test_generate_audio_filename_padding,
        test_generate_audio_filename_complex,
        test_normalize_reference,
        test_real_world_examples,
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
