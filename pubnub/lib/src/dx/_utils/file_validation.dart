import 'package:pubnub/core.dart';

/// Custom exception for file validation errors
class FileValidationException extends PubNubException {
  FileValidationException(String message) : super(message);
}

/// Validates file-related input parameters to prevent path traversal attacks
/// and other security issues.
class FileValidation {
  /// List of dangerous patterns that could lead to path traversal attacks
  static const List<String> _dangerousPatterns = [
    '../',
    '..\\',
    './',
    '.\\',
    '~/',
    '~\\',
  ];

  /// List of dangerous characters that should not be allowed in file names
  /// Using actual character codes instead of escape sequences
  static final List<int> _dangerousCharacterCodes = [
    0,    // Null byte
    1,    // Start of heading
    2,    // Start of text
    3,    // End of text
    4,    // End of transmission
    5,    // Enquiry
    6,    // Acknowledge
    7,    // Bell
    8,    // Backspace
    9,    // Tab
    10,   // Line feed (newline)
    11,   // Vertical tab
    12,   // Form feed
    13,   // Carriage return
    14,   // Shift out
    15,   // Shift in
    16,   // Data link escape
    17,   // Device control 1
    18,   // Device control 2
    19,   // Device control 3
    20,   // Device control 4
    21,   // Negative acknowledge
    22,   // Synchronous idle
    23,   // End of transmission block
    24,   // Cancel
    25,   // End of medium
    26,   // Substitute
    27,   // Escape
    28,   // File separator
    29,   // Group separator
    30,   // Record separator
    31,   // Unit separator
    127,  // Delete
  ];

  /// Validates a file name for security issues
  /// 
  /// Throws [FileValidationException] if the file name contains:
  /// - Path traversal patterns (../, ..\, etc.)
  /// - Dangerous control characters
  /// - Is null, empty, or only whitespace
  /// - Contains only dots (., .., etc.)
  /// - Exceeds maximum length (255 characters)
  static void validateFileName(String? fileName) {
    if (fileName == null || fileName.trim().isEmpty) {
      throw FileValidationException(
        'File name cannot be null or empty'
      );
    }

    final trimmedFileName = fileName.trim();
    
    // Check for maximum length (common filesystem limit)
    if (trimmedFileName.length > 255) {
      throw FileValidationException(
        'File name cannot exceed 255 characters'
      );
    }

    // Check for dangerous patterns
    for (final pattern in _dangerousPatterns) {
      if (trimmedFileName.contains(pattern)) {
        throw FileValidationException(
          'File name contains dangerous path traversal pattern: "$pattern"'
        );
      }
    }

    // Check for dangerous characters
    for (final charCode in _dangerousCharacterCodes) {
      if (trimmedFileName.contains(String.fromCharCode(charCode))) {
        throw FileValidationException(
          'File name contains dangerous character: "${charCode.toRadixString(16)}"'
        );
      }
    }

    // Check if filename is only dots (., .., etc.)
    if (RegExp(r'^\.*$').hasMatch(trimmedFileName)) {
      throw FileValidationException(
        'File name cannot consist only of dots'
      );
    }

    // Check for reserved names on Windows (even though this is cross-platform)
    final reservedNames = [
      'CON', 'PRN', 'AUX', 'NUL',
      'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
      'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
    ];
    
    final fileNameUpper = trimmedFileName.toUpperCase();
    final baseNameUpper = fileNameUpper.split('.').first;
    
    if (reservedNames.contains(baseNameUpper)) {
      throw FileValidationException(
        'File name cannot be a reserved system name: "$baseNameUpper"'
      );
    }
  }

  /// Validates a file ID for security issues
  /// 
  /// Throws [FileValidationException] if the file ID contains:
  /// - Path traversal patterns
  /// - Dangerous control characters
  /// - Is null, empty, or only whitespace
  static void validateFileId(String? fileId) {
    if (fileId == null || fileId.trim().isEmpty) {
      throw FileValidationException(
        'File ID cannot be null or empty'
      );
    }

    final trimmedFileId = fileId.trim();
    
    // Check for maximum length
    if (trimmedFileId.length > 255) {
      throw FileValidationException(
        'File ID cannot exceed 255 characters'
      );
    }

    // Check for dangerous patterns
    for (final pattern in _dangerousPatterns) {
      if (trimmedFileId.contains(pattern)) {
        throw FileValidationException(
          'File ID contains dangerous path traversal pattern: "$pattern"'
        );
      }
    }

    // Check for dangerous characters
    for (final charCode in _dangerousCharacterCodes) {
      if (trimmedFileId.contains(String.fromCharCode(charCode))) {
        throw FileValidationException(
          'File ID contains dangerous character: "${charCode.toRadixString(16)}"'
        );
      }
    }

    // Check if file ID is only dots
    if (RegExp(r'^\.*$').hasMatch(trimmedFileId)) {
      throw FileValidationException(
        'File ID cannot consist only of dots'
      );
    }
  }

  /// Validates a channel name for security issues
  /// 
  /// Throws [FileValidationException] if the channel name contains:
  /// - Path traversal patterns
  /// - Dangerous control characters
  /// - Is null, empty, or only whitespace
  static void validateChannelName(String? channel) {
    if (channel == null || channel.trim().isEmpty) {
      throw FileValidationException(
        'Channel name cannot be null or empty'
      );
    }

    final trimmedChannel = channel.trim();
    
    // Check for maximum length
    if (trimmedChannel.length > 255) {
      throw FileValidationException(
        'Channel name cannot exceed 255 characters'
      );
    }

    // Check for dangerous patterns
    for (final pattern in _dangerousPatterns) {
      if (trimmedChannel.contains(pattern)) {
        throw FileValidationException(
          'Channel name contains dangerous path traversal pattern: "$pattern"'
        );
      }
    }

    // Check for dangerous characters
    for (final charCode in _dangerousCharacterCodes) {
      if (trimmedChannel.contains(String.fromCharCode(charCode))) {
        throw FileValidationException(
          'Channel name contains dangerous character: "${charCode.toRadixString(16)}"'
        );
      }
    }
  }
}

/// Extension to add custom message constructor to InvalidArgumentsException
extension InvalidArgumentsExceptionExtension on InvalidArgumentsException {
  /// Creates an InvalidArgumentsException with a custom message
  static InvalidArgumentsException _withMessage(String message) {
    return InvalidArgumentsException._custom(message);
  }
}

/// Custom InvalidArgumentsException with specific message
class InvalidArgumentsException extends PubNubException {
  static final String _defaultMessage = '''Invalid Arguments. This may be due to:
  - an invalid subscribe key,
  - missing or invalid timetoken or channelsTimetoken (values must be greater than 0),
  - mismatched number of channels and timetokens,
  - invalid characters in a channel name,
  - other invalid request data.''';

  InvalidArgumentsException() : super(_defaultMessage);
  
  InvalidArgumentsException._custom(String message) : super(message);
} 