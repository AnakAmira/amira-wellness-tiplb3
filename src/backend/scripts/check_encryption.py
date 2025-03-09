#!/usr/bin/env python3
"""
check_encryption.py - Utility script for testing and verifying encryption functionality

This script performs various encryption and decryption operations to ensure that the
end-to-end encryption system of the Amira Wellness application is working correctly,
particularly for voice recordings and sensitive user data.
"""

import os
import sys
import argparse
import time
import json
import base64
from typing import Dict, List, Optional, Tuple, Union, Any

# Internal imports
from ..app.core.config import settings
from ..app.core.logging import logger, get_logger, setup_logging
from ..app.core.encryption import (
    EncryptionManager, 
    generate_encryption_key,
    generate_salt,
    derive_key_from_password,
    encode_encryption_data,
    decode_encryption_data,
    EncryptionError
)

# Configure logger for this script
LOGGER = get_logger('check_encryption')

# Test data sizes in bytes for performance testing
TEST_DATA_SIZES = [1024, 10240, 102400, 1048576]  # 1KB, 10KB, 100KB, 1MB


def setup_argument_parser() -> argparse.ArgumentParser:
    """Sets up command line argument parser for the script.
    
    Returns:
        Configured argument parser
    """
    parser = argparse.ArgumentParser(
        description='Test and verify encryption functionality of the Amira Wellness application'
    )
    parser.add_argument(
        '--mode',
        choices=['basic', 'performance', 'file', 'kms', 'all'],
        default='basic',
        help='Test mode to run (default: basic)'
    )
    parser.add_argument(
        '--password',
        type=str,
        help='Password to use for testing password-based encryption'
    )
    parser.add_argument(
        '--file',
        type=str,
        help='File path to use for testing file encryption'
    )
    parser.add_argument(
        '--output',
        type=str,
        help='File path to save test results (JSON format)'
    )
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Enable verbose logging'
    )
    
    return parser


def generate_test_data(size_bytes: int) -> bytes:
    """Generates random test data of specified size.
    
    Args:
        size_bytes: Size of data to generate in bytes
        
    Returns:
        Random test data
    """
    return os.urandom(size_bytes)


def test_basic_encryption(args: argparse.Namespace) -> bool:
    """Tests basic encryption and decryption functionality.
    
    Args:
        args: Command line arguments
        
    Returns:
        True if all tests pass, False otherwise
    """
    LOGGER.info("Starting basic encryption test")
    
    try:
        # Generate a random encryption key
        key = generate_encryption_key()
        LOGGER.debug(f"Generated encryption key of length {len(key)}")
        
        # Generate test data
        test_data = generate_test_data(1024)  # 1KB of test data
        LOGGER.debug(f"Generated {len(test_data)} bytes of test data")
        
        # Associated data for authentication
        associated_data = b"basic-encryption-test"
        
        # Create encryption manager
        encryption_manager = EncryptionManager()
        
        # Encrypt the data
        LOGGER.info("Encrypting test data...")
        encryption_result = encryption_manager.encrypt_data(
            test_data, key, associated_data
        )
        LOGGER.debug(f"Encryption result: {len(encryption_result['encrypted_data'])} bytes of encrypted data")
        
        # Decrypt the data
        LOGGER.info("Decrypting test data...")
        decrypted_data = encryption_manager.decrypt_data(
            encryption_result["encrypted_data"],
            key,
            encryption_result["iv"],
            encryption_result["tag"],
            associated_data
        )
        LOGGER.debug(f"Decrypted data length: {len(decrypted_data)} bytes")
        
        # Verify decryption
        if decrypted_data == test_data:
            LOGGER.info("Basic encryption test: SUCCESS - Data correctly encrypted and decrypted")
        else:
            LOGGER.error("Basic encryption test: FAILED - Decrypted data does not match original")
            return False
        
        # If password is provided, test password-based key derivation
        if args.password:
            LOGGER.info("Testing password-based key derivation...")
            salt = generate_salt()
            derived_key, _ = encryption_manager.generate_user_key(args.password, salt)
            
            # Encrypt with the derived key
            encryption_result = encryption_manager.encrypt_data(
                test_data, derived_key, associated_data
            )
            
            # Decrypt with the derived key
            decrypted_data = encryption_manager.decrypt_data(
                encryption_result["encrypted_data"],
                derived_key,
                encryption_result["iv"],
                encryption_result["tag"],
                associated_data
            )
            
            if decrypted_data == test_data:
                LOGGER.info("Password-based encryption test: SUCCESS")
            else:
                LOGGER.error("Password-based encryption test: FAILED")
                return False
        
        return True
        
    except Exception as e:
        LOGGER.error(f"Basic encryption test failed: {str(e)}", exc_info=True)
        return False


def test_file_encryption(args: argparse.Namespace) -> bool:
    """Tests file encryption and decryption functionality.
    
    Args:
        args: Command line arguments
        
    Returns:
        True if all tests pass, False otherwise
    """
    LOGGER.info("Starting file encryption test")
    
    try:
        # Check if a file is provided
        if args.file and os.path.exists(args.file):
            LOGGER.info(f"Using provided file: {args.file}")
            with open(args.file, 'rb') as f:
                file_data = f.read()
            LOGGER.debug(f"Read {len(file_data)} bytes from file")
        else:
            # Generate test file data
            LOGGER.info("No file provided or file not found. Generating test file data.")
            file_data = generate_test_data(102400)  # 100KB of test data
            LOGGER.debug(f"Generated {len(file_data)} bytes of test data")
        
        # Generate a random encryption key
        key = generate_encryption_key()
        
        # Associated data for authentication (could be file metadata)
        associated_data = b"file-encryption-test"
        
        # Create encryption manager
        encryption_manager = EncryptionManager()
        
        # Encrypt the file
        LOGGER.info("Encrypting file data...")
        encryption_result = encryption_manager.encrypt_file(
            file_data, key, associated_data
        )
        LOGGER.debug(f"Encryption result: {len(encryption_result['encrypted_data'])} bytes of encrypted data")
        
        # Decrypt the file
        LOGGER.info("Decrypting file data...")
        decrypted_data = encryption_manager.decrypt_file(
            encryption_result["encrypted_data"],
            key,
            encryption_result["iv"],
            encryption_result["tag"],
            associated_data
        )
        LOGGER.debug(f"Decrypted data length: {len(decrypted_data)} bytes")
        
        # Verify decryption
        if decrypted_data == file_data:
            LOGGER.info("File encryption test: SUCCESS - File correctly encrypted and decrypted")
            
            # If output file is specified, write test results
            if args.output:
                output_file = args.output
                if not output_file.endswith('.json'):
                    output_file += '.json'
                    
                result = {
                    "test": "file_encryption",
                    "success": True,
                    "file_size": len(file_data),
                    "encrypted_size": len(encryption_result["encrypted_data"]),
                    "timestamp": time.time()
                }
                
                with open(output_file, 'w') as f:
                    json.dump(result, f, indent=2)
                LOGGER.info(f"Test results written to {output_file}")
            
            return True
        else:
            LOGGER.error("File encryption test: FAILED - Decrypted data does not match original")
            return False
        
    except Exception as e:
        LOGGER.error(f"File encryption test failed: {str(e)}", exc_info=True)
        return False


def test_kms_encryption(args: argparse.Namespace) -> bool:
    """Tests AWS KMS integration for encryption.
    
    Args:
        args: Command line arguments
        
    Returns:
        True if all tests pass, False otherwise
    """
    LOGGER.info("Starting AWS KMS encryption test")
    
    # Check if KMS is enabled in settings
    if not settings.USE_AWS_KMS:
        LOGGER.warning("AWS KMS is not enabled in settings. Skipping test.")
        return False
    
    try:
        # Create encryption manager with KMS enabled
        encryption_manager = EncryptionManager(use_kms=True, kms_key_id=settings.ENCRYPTION_KEY_ID)
        
        # Generate test data
        test_data = generate_test_data(1024)  # 1KB of test data
        LOGGER.debug(f"Generated {len(test_data)} bytes of test data")
        
        # Generate a random encryption key
        key = generate_encryption_key()
        LOGGER.debug(f"Generated encryption key of length {len(key)}")
        
        # Associated data for authentication
        associated_data = b"kms-encryption-test"
        
        # Encrypt the data with KMS
        LOGGER.info("Encrypting data with KMS...")
        encryption_result = encryption_manager.encrypt_data(
            test_data, key, associated_data
        )
        
        LOGGER.debug(f"Encryption result: {len(encryption_result['encrypted_data'])} bytes of encrypted data")
        LOGGER.debug(f"Encrypted key present: {'encrypted_key' in encryption_result}")
        
        # Decrypt the data with KMS
        LOGGER.info("Decrypting data with KMS...")
        decrypted_data = encryption_manager.decrypt_data(
            encryption_result["encrypted_data"],
            None,  # Key will be decrypted from encrypted_key
            encryption_result["iv"],
            encryption_result["tag"],
            associated_data,
            encryption_result.get("encrypted_key")
        )
        LOGGER.debug(f"Decrypted data length: {len(decrypted_data)} bytes")
        
        # Verify decryption
        if decrypted_data == test_data:
            LOGGER.info("KMS encryption test: SUCCESS - Data correctly encrypted and decrypted using KMS")
            return True
        else:
            LOGGER.error("KMS encryption test: FAILED - Decrypted data does not match original")
            return False
        
    except Exception as e:
        LOGGER.error(f"KMS encryption test failed: {str(e)}", exc_info=True)
        return False


def test_encryption_performance(args: argparse.Namespace) -> Dict:
    """Tests encryption and decryption performance with different data sizes.
    
    Args:
        args: Command line arguments
        
    Returns:
        Performance test results
    """
    LOGGER.info("Starting encryption performance test")
    
    results = {
        "test": "encryption_performance",
        "timestamp": time.time(),
        "results": []
    }
    
    try:
        # Generate a random encryption key
        key = generate_encryption_key()
        
        # Create encryption manager
        encryption_manager = EncryptionManager()
        
        # Test with different data sizes
        for size in TEST_DATA_SIZES:
            LOGGER.info(f"Testing with data size: {size} bytes")
            
            # Generate test data
            test_data = generate_test_data(size)
            
            # Measure encryption time
            start_time = time.time()
            encryption_result = encryption_manager.encrypt_data(
                test_data, key, b"performance-test"
            )
            encryption_time = time.time() - start_time
            
            # Measure decryption time
            start_time = time.time()
            decryption_result = encryption_manager.decrypt_data(
                encryption_result["encrypted_data"],
                key,
                encryption_result["iv"],
                encryption_result["tag"],
                b"performance-test"
            )
            decryption_time = time.time() - start_time
            
            # Calculate throughput
            encryption_throughput = size / encryption_time / 1024 / 1024  # MB/s
            decryption_throughput = size / decryption_time / 1024 / 1024  # MB/s
            
            # Verify decryption
            success = decryption_result == test_data
            
            # Log results
            LOGGER.info(f"Data size: {size} bytes")
            LOGGER.info(f"Encryption time: {encryption_time:.6f} seconds")
            LOGGER.info(f"Decryption time: {decryption_time:.6f} seconds")
            LOGGER.info(f"Encryption throughput: {encryption_throughput:.2f} MB/s")
            LOGGER.info(f"Decryption throughput: {decryption_throughput:.2f} MB/s")
            LOGGER.info(f"Verification: {'SUCCESS' if success else 'FAILED'}")
            
            # Store results
            results["results"].append({
                "data_size": size,
                "encryption_time": encryption_time,
                "decryption_time": decryption_time,
                "encryption_throughput": encryption_throughput,
                "decryption_throughput": decryption_throughput,
                "success": success
            })
        
        # Calculate averages
        total_encryption_time = sum(r["encryption_time"] for r in results["results"])
        total_decryption_time = sum(r["decryption_time"] for r in results["results"])
        avg_encryption_throughput = sum(r["encryption_throughput"] for r in results["results"]) / len(results["results"])
        avg_decryption_throughput = sum(r["decryption_throughput"] for r in results["results"]) / len(results["results"])
        
        results["summary"] = {
            "total_encryption_time": total_encryption_time,
            "total_decryption_time": total_decryption_time,
            "avg_encryption_throughput": avg_encryption_throughput,
            "avg_decryption_throughput": avg_decryption_throughput,
            "all_succeeded": all(r["success"] for r in results["results"])
        }
        
        LOGGER.info(f"Performance test summary:")
        LOGGER.info(f"Total encryption time: {total_encryption_time:.6f} seconds")
        LOGGER.info(f"Total decryption time: {total_decryption_time:.6f} seconds")
        LOGGER.info(f"Average encryption throughput: {avg_encryption_throughput:.2f} MB/s")
        LOGGER.info(f"Average decryption throughput: {avg_decryption_throughput:.2f} MB/s")
        LOGGER.info(f"All tests succeeded: {results['summary']['all_succeeded']}")
        
        # If output file is provided, write performance results to JSON file
        if args.output:
            output_file = args.output
            if not output_file.endswith('.json'):
                output_file += '.json'
                
            with open(output_file, 'w') as f:
                json.dump(results, f, indent=2)
            LOGGER.info(f"Performance test results written to {output_file}")
        
        return results
        
    except Exception as e:
        LOGGER.error(f"Performance test failed: {str(e)}", exc_info=True)
        results["error"] = str(e)
        return results


def run_all_tests(args: argparse.Namespace) -> Dict:
    """Runs all encryption tests.
    
    Args:
        args: Command line arguments
        
    Returns:
        Test results for all tests
    """
    LOGGER.info("Running all encryption tests")
    
    results = {
        "test": "all_tests",
        "timestamp": time.time(),
        "results": {}
    }
    
    # Run basic encryption test
    LOGGER.info("Running basic encryption test...")
    basic_result = test_basic_encryption(args)
    results["results"]["basic_encryption"] = basic_result
    
    # Run file encryption test
    LOGGER.info("Running file encryption test...")
    file_result = test_file_encryption(args)
    results["results"]["file_encryption"] = file_result
    
    # Run KMS encryption test if enabled
    if settings.USE_AWS_KMS:
        LOGGER.info("Running KMS encryption test...")
        kms_result = test_kms_encryption(args)
        results["results"]["kms_encryption"] = kms_result
    else:
        LOGGER.warning("AWS KMS is not enabled. Skipping KMS test.")
        results["results"]["kms_encryption"] = False
    
    # Run performance test
    LOGGER.info("Running encryption performance test...")
    performance_result = test_encryption_performance(args)
    results["results"]["performance"] = performance_result
    
    # Calculate overall success
    all_succeeded = (
        basic_result and 
        file_result and 
        (not settings.USE_AWS_KMS or results["results"]["kms_encryption"]) and
        performance_result["summary"]["all_succeeded"]
    )
    
    results["success"] = all_succeeded
    
    LOGGER.info(f"All tests completed. Overall success: {all_succeeded}")
    
    # If output file specified, write all results to JSON file
    if args.output:
        output_file = args.output
        if not output_file.endswith('.json'):
            output_file += '.json'
            
        with open(output_file, 'w') as f:
            json.dump(results, f, indent=2)
        LOGGER.info(f"All test results written to {output_file}")
    
    return results


def main() -> int:
    """Main function that orchestrates the encryption tests.
    
    Returns:
        Exit code (0 for success, non-zero for failure)
    """
    # Set up logging
    setup_logging()
    
    # Parse command line arguments
    parser = setup_argument_parser()
    args = parser.parse_args()
    
    # Set log level based on verbose flag
    if args.verbose:
        LOGGER.setLevel(logging.DEBUG)
    
    LOGGER.info(f"Starting encryption test script with mode: {args.mode}")
    
    success = False
    
    try:
        # Run tests based on mode
        if args.mode == 'basic':
            success = test_basic_encryption(args)
        elif args.mode == 'file':
            success = test_file_encryption(args)
        elif args.mode == 'kms':
            success = test_kms_encryption(args)
        elif args.mode == 'performance':
            results = test_encryption_performance(args)
            success = results["summary"]["all_succeeded"]
        elif args.mode == 'all':
            results = run_all_tests(args)
            success = results["success"]
        
        LOGGER.info(f"Test completed. Success: {success}")
        
        return 0 if success else 1
    
    except Exception as e:
        LOGGER.error(f"Error running tests: {str(e)}", exc_info=True)
        return 2


if __name__ == "__main__":
    sys.exit(main())