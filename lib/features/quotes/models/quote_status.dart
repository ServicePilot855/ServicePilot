import 'package:flutter/material.dart';
import 'package:service_pilot/l10n/app_localizations.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Lifecycle states for a separate homeowner quote request (PLAN.md 4.8).
enum QuoteStatus {
  requested,
  quoted,
  approved,
  rejected,
}

extension QuoteStatusExtension on QuoteStatus {
  /// Serialized database string value.
  String get value {
    switch (this) {
      case QuoteStatus.requested:
        return 'requested';
      case QuoteStatus.quoted:
        return 'quoted';
      case QuoteStatus.approved:
        return 'approved';
      case QuoteStatus.rejected:
        return 'rejected';
    }
  }

  /// Default English label matching the Jira acceptance criteria.
  String get label {
    switch (this) {
      case QuoteStatus.requested:
        return 'Requested';
      case QuoteStatus.quoted:
        return 'Quoted';
      case QuoteStatus.approved:
        return 'Approved';
      case QuoteStatus.rejected:
        return 'Rejected';
    }
  }

  /// Localized display label for UI surfaces.
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case QuoteStatus.requested:
        return l10n.quoteStatusRequested;
      case QuoteStatus.quoted:
        return l10n.quoteStatusQuoted;
      case QuoteStatus.approved:
        return l10n.quoteStatusApproved;
      case QuoteStatus.rejected:
        return l10n.quoteStatusRejected;
    }
  }

  /// DESIGN.md tone pairing (`waiting` uses Tape Yellow while awaiting provider quote).
  SpTone get tone {
    switch (this) {
      case QuoteStatus.requested:
        return SpTone.waiting;
      case QuoteStatus.quoted:
        return SpTone.brand;
      case QuoteStatus.approved:
        return SpTone.success;
      case QuoteStatus.rejected:
        return SpTone.danger;
    }
  }

  IconData get icon {
    switch (this) {
      case QuoteStatus.requested:
        return Icons.hourglass_top_rounded;
      case QuoteStatus.quoted:
        return Icons.request_quote_rounded;
      case QuoteStatus.approved:
        return Icons.check_circle_outline_rounded;
      case QuoteStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  static QuoteStatus fromValue(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'quoted':
        return QuoteStatus.quoted;
      case 'approved':
        return QuoteStatus.approved;
      case 'rejected':
      case 'declined':
        return QuoteStatus.rejected;
      case 'requested':
      default:
        return QuoteStatus.requested;
    }
  }
}
