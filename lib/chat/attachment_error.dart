import '../l10n/app_localizations.dart';

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

/// The message for an attachment that was refused, in the user's language.
/// A [FormatException] that is not an [AttachmentException] keeps its own
/// text.
String attachmentErrorMessage(AppLocalizations l10n, FormatException e) {
  if (e is! AttachmentException) return e.message;
  return switch (e.problem) {
    AttachmentProblem.imageUnsupported => l10n.chatAttachImageUnsupported,
    AttachmentProblem.imageEmpty => l10n.chatAttachImageEmpty,
    AttachmentProblem.imageTooLarge => l10n.chatAttachImageTooLarge(
      e.sizeMb ?? '',
      e.limitMb ?? 0,
    ),
    AttachmentProblem.pdfUnsupported => l10n.chatAttachPdfUnsupported,
    AttachmentProblem.binaryFormatUnsupported =>
      l10n.chatAttachBinaryUnsupported(e.formatName ?? ''),
    AttachmentProblem.fileEmpty => l10n.chatAttachFileEmpty,
    AttachmentProblem.binaryFile => l10n.chatAttachBinaryFile,
    AttachmentProblem.notUtf8 => l10n.chatAttachNotUtf8,
    AttachmentProblem.noText => l10n.chatAttachNoText,
  };
}
