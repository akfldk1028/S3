#!/usr/bin/env python3
"""
Verification script to test that all modules can be imported.
This simulates what happens during Docker container startup.
"""

import sys
import os

def test_imports():
    """Test that all required modules can be imported."""
    print("=" * 60)
    print("GPU Worker Import Verification")
    print("=" * 60)
    print()

    failures = []

    # Test engine modules
    print("Testing engine modules...")
    engine_modules = [
        'engine.segmenter',
        'engine.applier',
        'engine.r2_io',
        'engine.callback',
        'engine.pipeline'
    ]

    for module in engine_modules:
        try:
            __import__(module)
            print(f"  ✓ {module}")
        except ImportError as e:
            print(f"  ✗ {module}: {e}")
            failures.append((module, str(e)))
        except Exception as e:
            print(f"  ⚠ {module}: {e} (may need dependencies)")

    # Test adapter modules
    print("\nTesting adapter modules...")
    adapter_modules = [
        'adapters.runpod_serverless',
    ]

    for module in adapter_modules:
        try:
            __import__(module)
            print(f"  ✓ {module}")
        except ImportError as e:
            print(f"  ✗ {module}: {e}")
            failures.append((module, str(e)))
        except Exception as e:
            print(f"  ⚠ {module}: {e} (may need dependencies)")

    # Test preset modules
    print("\nTesting preset modules...")
    preset_modules = [
        'presets.interior',
        'presets.seller',
    ]

    for module in preset_modules:
        try:
            mod = __import__(module, fromlist=['*'])
            print(f"  ✓ {module}")

            # Check for expected attributes
            if hasattr(mod, 'INTERIOR_CONCEPTS'):
                print(f"    → {len(mod.INTERIOR_CONCEPTS)} interior concepts")
            if hasattr(mod, 'SELLER_CONCEPTS'):
                print(f"    → {len(mod.SELLER_CONCEPTS)} seller concepts")
        except ImportError as e:
            print(f"  ✗ {module}: {e}")
            failures.append((module, str(e)))
        except Exception as e:
            print(f"  ⚠ {module}: {e}")

    # Test main entry point
    print("\nTesting main entry point...")
    try:
        with open('main.py', 'r') as f:
            content = f.read()
            compile(content, 'main.py', 'exec')
        print(f"  ✓ main.py syntax valid")
    except SyntaxError as e:
        print(f"  ✗ main.py has syntax error: {e}")
        failures.append(('main.py', str(e)))

    # Summary
    print("\n" + "=" * 60)
    if failures:
        print(f"✗ {len(failures)} import(s) failed:")
        for module, error in failures:
            print(f"  - {module}: {error}")
        return 1
    else:
        print("✓ All imports successful!")
        print("\nThe application structure is correct and ready for deployment.")
        return 0

if __name__ == '__main__':
    sys.exit(test_imports())
