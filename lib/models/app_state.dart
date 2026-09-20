class AppState {
  bool onboarded;
  bool isPro;
  int aiGenerationsUsed;
  int freeAiLimit;
  int streakDays;
  DateTime? lastStudyDate;
  int totalStudyMinutes;
  int dailyMinutesGoal;
  bool lastPlanWasAi;
  DateTime? lastPlanAt;

  AppState({
    this.onboarded = false,
    this.isPro = false,
    this.aiGenerationsUsed = 0,
    this.freeAiLimit = 3,
    this.streakDays = 0,
    this.lastStudyDate,
    this.totalStudyMinutes = 0,
    this.dailyMinutesGoal = 120,
    this.lastPlanWasAi = false,
    this.lastPlanAt,
  });

  Map<String, dynamic> toJson() => {
        'onboarded': onboarded,
        'isPro': isPro,
        'aiGenerationsUsed': aiGenerationsUsed,
        'freeAiLimit': freeAiLimit,
        'streakDays': streakDays,
        'lastStudyDate': lastStudyDate?.toIso8601String(),
        'totalStudyMinutes': totalStudyMinutes,
        'dailyMinutesGoal': dailyMinutesGoal,
        'lastPlanWasAi': lastPlanWasAi,
        'lastPlanAt': lastPlanAt?.toIso8601String(),
      };

  factory AppState.fromJson(Map<String, dynamic> json) => AppState(
        onboarded: json['onboarded'] as bool? ?? false,
        isPro: json['isPro'] as bool? ?? false,
        aiGenerationsUsed: (json['aiGenerationsUsed'] as num?)?.toInt() ?? 0,
        freeAiLimit: (json['freeAiLimit'] as num?)?.toInt() ?? 3,
        streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
        lastStudyDate: json['lastStudyDate'] == null
            ? null
            : DateTime.parse(json['lastStudyDate'] as String),
        totalStudyMinutes: (json['totalStudyMinutes'] as num?)?.toInt() ?? 0,
        dailyMinutesGoal: (json['dailyMinutesGoal'] as num?)?.toInt() ?? 120,
        lastPlanWasAi: json['lastPlanWasAi'] as bool? ?? false,
        lastPlanAt: json['lastPlanAt'] == null
            ? null
            : DateTime.parse(json['lastPlanAt'] as String),
      );
}
