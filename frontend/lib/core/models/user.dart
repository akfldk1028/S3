/// User data model returned by GET /me
///
/// JSON field names match the Workers API response shape.
class RuleSlots {
  final int used;
  final int max;

  const RuleSlots({required this.used, required this.max});

  factory RuleSlots.fromJson(Map<String, dynamic> json) => RuleSlots(
        used: (json['used'] as num?)?.toInt() ?? 0,
        max: (json['max'] as num?)?.toInt() ?? 0,
      );

  @override
  String toString() => 'RuleSlots(used: $used, max: $max)';
}

/// Authenticated user state from the Workers /me endpoint.
class User {
  final String userId;
  final String plan; // 'free' | 'pro'
  final int credits;
  final int activeJobs;
  final RuleSlots ruleSlots;

  const User({
    required this.userId,
    required this.plan,
    required this.credits,
    required this.activeJobs,
    required this.ruleSlots,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
        plan: json['plan'] as String? ?? 'free',
        credits: (json['credits'] as num?)?.toInt() ?? 0,
        activeJobs: (json['active_jobs'] as num?)?.toInt() ?? 0,
        ruleSlots: json['rule_slots'] != null
            ? RuleSlots.fromJson(
                json['rule_slots'] as Map<String, dynamic>,
              )
            : const RuleSlots(used: 0, max: 2),
      );

  bool get isPro => plan.toLowerCase() == 'pro';

  @override
  String toString() =>
      'User(userId: $userId, plan: $plan, credits: $credits, activeJobs: $activeJobs, ruleSlots: $ruleSlots)';
}
