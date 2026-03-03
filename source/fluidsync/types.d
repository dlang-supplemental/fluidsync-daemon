module fluidsync.types;

/**
 * The memory-mapped state exposed to GUI clients.
 * This needs to be alignment-safe and contain only primitive types (no pointers/references)
 * as it is shared across process boundaries.
 */
align(4) struct FluidSyncState
{
  /// Incremented every time the daemon updates the metrics
  uint version_tick;

  /// The maximum total frame budget in milliseconds (e.g. 16.6 for 60Hz, 6.9 for 144Hz)
  float current_budget_ms;

  /// If true, the system is under load (e.g., resizing) or dropping frames.
  /// UI applications should fall back to skeleton rendering.
  bool urgent_mode;

  /// The recommended maximum time the UI thread should spend doing layout math.
  float ideal_layout_ms;
}
