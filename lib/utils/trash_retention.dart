/// Pure "days left until permanent purge" computation for a trashed file,
/// extracted out of TrashScreen so it's independently testable.
///
/// Prefers a server-provided `purgeAfter` timestamp when the API response
/// actually includes one -- that's the real value the backend's purge cron
/// (silvora_backend's files/management/commands/purge_trashed_files.py) acts
/// on, so reading it directly can never drift from real server behavior even
/// if the retention window is ever changed.
///
/// KNOWN GAP (documented, not silently papered over): as of 2026-09-06,
/// silvora_backend's list_trash() view does not actually serialize
/// `purge_after` in its response -- only `deleted_at` -- so in practice the
/// fallback below is what runs today. That fallback (deletedAt +
/// [defaultRetentionDays]) reproduces the exact drift risk the original
/// review finding flagged: if the server's real retention window is ever
/// changed, this hardcoded default silently goes stale until the backend
/// also starts returning purge_after. The one remaining piece to fully close
/// this is a one-line backend change (serializing FileRecord.purge_after in
/// list_trash's response dict); this class picks it up automatically the
/// moment it's present, with no further client change needed.
class TrashRetention {
  /// Must match FileRecord.mark_deleted()'s current default retention_days=7
  /// in silvora_backend/files/models.py -- used only as a fallback when the
  /// server hasn't told us the real purge_after for this file.
  static const int defaultRetentionDays = 7;

  /// Human-readable "days left" label for one trashed-file API response
  /// entry. [purgeAfter] and [deletedAt] are passed as `dynamic` because
  /// they arrive as whatever the JSON decoder produced (a String, or null).
  static String daysLeftLabel({
    required dynamic purgeAfter,
    required dynamic deletedAt,
    int fallbackRetentionDays = defaultRetentionDays,
  }) {
    if (purgeAfter != null) {
      try {
        final diff = DateTime.parse(purgeAfter.toString()).difference(DateTime.now()).inDays;
        return diff <= 0 ? "Expires soon" : "$diff days left";
      } catch (_) {
        // Unparseable purge_after -- fall through to the deletedAt estimate.
      }
    }

    if (deletedAt == null) return "Unknown";
    try {
      final dt = DateTime.parse(deletedAt.toString());
      final purge = dt.add(Duration(days: fallbackRetentionDays));
      final diff = purge.difference(DateTime.now()).inDays;
      return diff <= 0 ? "Expires soon" : "$diff days left";
    } catch (_) {
      return "$fallbackRetentionDays days";
    }
  }
}
