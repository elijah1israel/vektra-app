class AppUser {
  AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.accountType,
    this.accountSize,
    this.tier,
    this.tierUntil,
    this.tierSource,
    this.usdtCreditCents = 0,
    this.telegramLinked = false,
    this.discoverable = true,
    this.referralCode,
    this.referralsCount = 0,
    this.followersCount = 0,
    this.following,
    this.isBotOwner = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        email: (json['email'] ?? '') as String,
        fullName: json['full_name'] as String?,
        accountType: json['account_type'] as String?,
        accountSize: (json['account_size'] as num?)?.toInt(),
        tier: json['tier'] is Map
            ? Tier.fromJson(json['tier'] as Map<String, dynamic>)
            : null,
        tierUntil: json['tier_until'] as String?,
        tierSource: json['tier_source'] as String?,
        usdtCreditCents: (json['usdt_credit_cents'] as num?)?.toInt() ?? 0,
        telegramLinked: json['telegram_linked'] == true,
        discoverable: json['discoverable'] != false,
        referralCode: json['referral_code'] as String?,
        referralsCount: (json['referrals_count'] as num?)?.toInt() ?? 0,
        followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
        following: json['following'] is Map
            ? Following.fromJson(json['following'] as Map<String, dynamic>)
            : null,
        isBotOwner: json['is_bot_owner'] == true,
      );

  final int id;
  final String email;
  final String? fullName;
  final String? accountType;
  final int? accountSize;
  final Tier? tier;
  final String? tierUntil;
  final String? tierSource;
  final int usdtCreditCents;
  final bool telegramLinked;
  final bool discoverable;
  final String? referralCode;
  final int referralsCount;
  final int followersCount;
  final Following? following;
  final bool isBotOwner;
}

class Tier {
  Tier({required this.key, required this.label});
  factory Tier.fromJson(Map<String, dynamic> j) => Tier(
        key: (j['key'] ?? '') as String,
        label: (j['label'] ?? '') as String,
      );
  final String key;
  final String label;
}

class Following {
  Following({
    required this.id,
    this.fullName,
    this.instrumentLabel,
    this.instrumentSymbol,
  });
  factory Following.fromJson(Map<String, dynamic> j) => Following(
        id: j['id'] as int,
        fullName: j['full_name'] as String?,
        instrumentLabel: j['instrument_label'] as String?,
        instrumentSymbol: j['instrument_symbol'] as String?,
      );
  final int id;
  final String? fullName;
  final String? instrumentLabel;
  final String? instrumentSymbol;
}
