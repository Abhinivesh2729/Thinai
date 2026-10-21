/// Why an attachment was refused.
///
/// The UI turns this into a localized message; the English [message] on
/// [AttachmentException] stays for logs and for code that only reads it.
enum AttachmentProblem {
  imageUnsupported,
  imageEmpty,
  imageTooLarge,
  pdfUnsupported,
  binaryFormatUnsupported,
  fileEmpty,
  binaryFile,
  notUtf8,
  noText,
}

/// A [FormatException] that also says which [AttachmentProblem] it is, so the
/// message can be shown in the user's language.
class AttachmentException extends FormatException {
  const AttachmentException(
    this.problem,
    super.message, {
    this.formatName,
    this.sizeMb,
    this.limitMb,
  });

  final AttachmentProblem problem;

  /// For [AttachmentProblem.binaryFormatUnsupported]: the format named in the
  /// message, such as `Word` or `image`.
  final String? formatName;

  /// For [AttachmentProblem.imageTooLarge]: the image's size, already
  /// formatted to one decimal, and the limit.
  final String? sizeMb;
  final int? limitMb;
}
