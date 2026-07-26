/// A single slice of the user's life-balance breakdown: how much of their
/// recent activity a skill area accounts for, and whether it's being neglected.
class LifeBalanceSlice {
  const LifeBalanceSlice({
    required this.key,
    required this.name,
    required this.share,
    required this.neglected,
  });

  final String key;
  final String name;

  /// Fraction of overall activity, 0..1.
  final double share;
  final bool neglected;
}
