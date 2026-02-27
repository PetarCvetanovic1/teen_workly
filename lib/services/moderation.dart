import 'package:cloud_functions/cloud_functions.dart';

class ModerationResult {
  final bool approved;
  final String? reason;
  const ModerationResult({required this.approved, this.reason});
}

class ModerationService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static const _bannedWords = [
    'goon', 'gooning', 'goonin', 'porn', 'onlyfans', 'nsfw', 'nude', 'nudes',
    'naked', 'sex', 'sexual', 'sexy', 'xxx', 'dick', 'penis', 'vagina',
    'boob', 'boobs', 'tits', 'titty', 'titties', 'ass', 'asshole',
    'fuck', 'fucker', 'fuckin', 'fucking', 'fck', 'fuk',
    'shit', 'shitty', 'bitch', 'bitches',
    'whore', 'slut', 'slutty', 'hoe', 'hoes', 'thot',
    'retard', 'retarded', 'faggot', 'fag', 'nigger', 'nigga', 'negro',
    'kill', 'murder', 'suicide', 'kys',
    'drugs', 'weed', 'cocaine', 'meth', 'heroin', 'molly', 'ecstasy',
    'lsd', 'crack', 'fentanyl', 'xanax', 'percocet',
    'stripper', 'escort', 'prostitut', 'trafficking', 'scam',
    'catfish', 'predator', 'creep', 'creepy', 'stalk', 'stalker',
    'molest', 'rape', 'rapist',
    'pedo', 'pedophile', 'child abuse', 'gun', 'weapon', 'bomb', 'terrorist',
    'racist', 'slavery',
    'femboy', 'femboys', 'furry', 'furries', 'hentai', 'ahegao',
    'milf', 'dilf', 'dildo', 'vibrator', 'orgasm', 'cum', 'cumming',
    'jerk off', 'jerking', 'wank', 'wanker', 'masturbat',
    'onlyfan', 'skibidi', 'rizz',
    'cunt', 'twat', 'bollocks', 'wanking', 'shag',
    'damn', 'dammit', 'bastard', 'piss', 'pissed',
    'brainrot', 'brain rot', 'edging',
    'motherfucker', 'mother fucker', 'mfer', 'mf',
    'bullshit', 'bs', 'wtf', 'stfu', 'douche', 'douchebag',
    'jackass', 'prick', 'pussy', 'cock',
    'chink', 'kike', 'spic', 'dih', 'puh', 'bih', 
    'femboy', 'femboys', 'furry', 'furries', 'futa', 'trap',
    'simp', 'incel', 'cuck', 'gooner', 'coomer',
    'anal', 'blowjob', 'bj', 'handjob', 'rimjob', 'deepthroat',
    'gangbang', 'threesome', 'nudes', 'nudity', 'naked',
    'nsfl', 'gore', 'beheading', 'decapitate',
    'selfharm', 'self harm', 'kms', 'unalive',
    'die', 'hang yourself', 'cut yourself',
    'fraud', 'phish', 'phishing', 'steal card', 'stolen card',
    'dox', 'doxx', 'doxxing', 'swat',
  ];

  // Extra strict local hard-block layer for when AI is unavailable.
  // NOTE: This intentionally over-blocks risky content.
  static const _hardBlockRegexes = <String>[
    // Severe profanity / harassment
    r'\b(f+[\W_]*u+[\W_]*c+[\W_]*k+)\b',
    r'\b(s+[\W_]*h+[\W_]*i+[\W_]*t+)\b',
    r'\b(b+[\W_]*i+[\W_]*t+[\W_]*c+[\W_]*h+)\b',
    r'\b(c+[\W_]*u+[\W_]*n+[\W_]*t+)\b',
    r'\b(a+[\W_]*s+[\W_]*s+[\W_]*h+[\W_]*o+[\W_]*l+[\W_]*e+)\b',
    r'\b(n+[\W_]*i+[\W_]*g+[\W_]*g+[\W_]*a+)\b',
    r'\b(n+[\W_]*i+[\W_]*g+[\W_]*g+[\W_]*e+[\W_]*r+)\b',
    r'\b(f+[\W_]*a+[\W_]*g+[\W_]*g*[\W_]*o+[\W_]*t*)\b',
    r'\b(r+[\W_]*e+[\W_]*t+[\W_]*a+[\W_]*r+[\W_]*d+)\b',

    // Sexual / explicit
    r'\b(sex|sexual|sexy|xxx|porn|onlyfans|nsfw|nude|nudes|naked)\b',
    r'\b(dick|penis|vagina|boob|boobs|tits|titty|titties|cock|pussy)\b',
    r'\b(blow[\W_]*job|hand[\W_]*job|rim[\W_]*job|deep[\W_]*throat)\b',
    r'\b(orgasm|cum+|cumming|ejaculat(e|ion)|masturbat(e|ion|ing))\b',
    r'\b(femboy|femboys|furry|furries|hentai|ahegao|milf|dilf)\b',

    // Predatory / unsafe meetup
    r'\b(come\s+alone|no\s+parents|dont\s+tell\s+anyone|do\s+not\s+tell\s+anyone)\b',
    r'\b(send\s+(pics|photos|nudes)|show\s+me\s+your\s+body)\b',
    r'\b(overnight\s+stay|sleep\s+over\s+alone|private\s+meet)\b',

    // Violence / self-harm
    r'\b(kill|murder|rape|rapist|molest|pedo|pedophile)\b',
    r'\b(kys|kms|hang\s+yourself|cut\s+yourself|self[\W_]*harm|unalive)\b',
    r'\b(gun|weapon|bomb|terrorist|behead(ing)?|decapitat(e|ion))\b',

    // Drugs / scams
    r'\b(cocaine|meth|heroin|fentanyl|lsd|ecstasy|molly|xanax|percocet|crack)\b',
    r'\b(scam|scammer|fraud|phish(ing)?|wire\s+transfer|gift\s+card\s+payment)\b',
    r'\b(venmo\s+me\s+first|cashapp\s+me\s+first|pay\s+upfront)\b',
  ];

  // Stems used to catch masked/censored variants like f***, sh!t, bi7ch, etc.
  static const _blockedStems = <String>[
    'fuck', 'shit', 'bitch', 'asshole', 'cunt', 'faggot', 'retard',
    'nigga', 'nigger', 'whore', 'slut', 'motherfucker',
    'dick', 'cock', 'pussy', 'penis', 'vagina',
    'porn', 'nude', 'nudes', 'nsfw', 'sex', 'sexual',
    'rape', 'rapist', 'molest', 'pedo', 'pedophile',
    'dih', 'puh', 'bih', 'nethnyaho', 
    'kys', 'kms', 'selfharm', 'suicide',
    'femboy', 'furry', 'hentai',
  ];

  static const _suspiciousPatterns = [
    'send nudes', 'come to my house alone', 'no parents',
    'don\'t tell anyone', 'secret', 'late night only',
    'overnight stay', 'must be attractive', 'good looking only',
    'send pics', 'send photos of yourself', 'sugar daddy',
    'sugar mommy', 'easy money no work', 'get rich quick',
    'pyramid', 'mlm', 'crypto investment', 'make money fast',
    'cashapp me', 'venmo me first', 'pay upfront',
    'wire transfer', 'western union', 'gift cards',
  ];

  static const _maxReasonableHourly = 75.0;
  static const _maxReasonableOneTime = 500.0;

  static Future<ModerationResult> moderateJob({
    required String title,
    required String description,
    required String type,
    double? paymentHint,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final allText = '$title $description'.toLowerCase();

    final profanity = _checkProfanity(allText);
    if (profanity != null) return profanity;

    final suspicious = _checkSuspicious(allText);
    if (suspicious != null) return suspicious;

    if (title.trim().length < 5) {
      return const ModerationResult(
        approved: false,
        reason: 'Job title is too short. Please write a clear, descriptive title.',
      );
    }

    if (description.trim().length < 8) {
      return const ModerationResult(
        approved: false,
        reason: 'Description is too short. Give applicants enough detail to understand the job.',
      );
    }

    if (_isAllCaps(title) && title.length > 8) {
      return const ModerationResult(
        approved: false,
        reason: 'Please don\'t use ALL CAPS in the title. Keep it professional.',
      );
    }

    if (_hasExcessiveRepetition(allText)) {
      return const ModerationResult(
        approved: false,
        reason: 'Your post looks like spam. Please write a genuine job listing.',
      );
    }

    if (paymentHint != null) {
      if (paymentHint > _maxReasonableHourly &&
          (type == 'Part-time' || type == 'Seasonal')) {
        return ModerationResult(
          approved: false,
          reason:
              'Pay of \$${paymentHint.toStringAsFixed(0)}/hr seems unrealistic for a teen job. '
              'Most gigs pay \$10–\$30/hr. Please set a fair rate.',
        );
      }
      if (paymentHint > _maxReasonableOneTime && type == 'One-time') {
        return ModerationResult(
          approved: false,
          reason:
              'Payment of \$${paymentHint.toStringAsFixed(0)} for a one-time job seems unusually high. '
              'Please double-check or add more detail about why.',
        );
      }
    }

    final payMentions = _extractPayFromText(description);
    if (payMentions != null) {
      if (payMentions > _maxReasonableHourly &&
          description.toLowerCase().contains('/hr')) {
        return ModerationResult(
          approved: false,
          reason:
              'The hourly rate mentioned (\$${payMentions.toStringAsFixed(0)}/hr) seems unrealistically high. '
              'Please set a fair rate.',
        );
      }
      if (payMentions > _maxReasonableOneTime * 2) {
        return ModerationResult(
          approved: false,
          reason:
              'The payment mentioned (\$${payMentions.toStringAsFixed(0)}) is unusually high for a teen job. '
              'Please verify the amount.',
        );
      }
    }

    final aiResult = await _validateWithAi(
      [
        'Job title: $title',
        'Job type: $type',
        'Description: $description',
        if (paymentHint != null) 'Payment: \$${paymentHint.toStringAsFixed(2)}',
      ].join('\n'),
    );
    if (!aiResult.approved) return aiResult;

    return const ModerationResult(approved: true);
  }

  static Future<ModerationResult> moderateService({
    required String providerName,
    required String bio,
    required Set<String> skills,
    String? otherSkill,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final allText = '$providerName $bio ${skills.join(' ')} ${otherSkill ?? ''}'
        .toLowerCase();

    final profanity = _checkProfanity(allText);
    if (profanity != null) return profanity;

    final suspicious = _checkSuspicious(allText);
    if (suspicious != null) return suspicious;

    if (bio.trim().length < 10) {
      return const ModerationResult(
        approved: false,
        reason: 'Your bio is too short. Tell people a bit about yourself and what you can do.',
      );
    }

    if (_isAllCaps(bio) && bio.length > 15) {
      return const ModerationResult(
        approved: false,
        reason: 'Please don\'t write your bio in ALL CAPS. Keep it readable.',
      );
    }

    if (_hasExcessiveRepetition(allText)) {
      return const ModerationResult(
        approved: false,
        reason: 'Your post looks like spam. Please write a genuine service listing.',
      );
    }

    return const ModerationResult(approved: true);
  }

  static ModerationResult? _checkProfanity(String text) {
    final normalized = _normalizeForProfanity(text);
    final compact = normalized.replaceAll(' ', '');
    final lower = text.toLowerCase();

    for (final pattern in _hardBlockRegexes) {
      final re = RegExp(pattern, caseSensitive: false);
      if (re.hasMatch(lower) || re.hasMatch(normalized) || re.hasMatch(compact)) {
        return const ModerationResult(
          approved: false,
          reason:
              'Your post contains inappropriate language and has been blocked. '
              'Please keep all content family-friendly and professional.',
        );
      }
    }

    if (_looksLikeObfuscatedProfanity(text)) {
      return const ModerationResult(
        approved: false,
        reason:
            'Your post contains inappropriate language and has been blocked. '
            'Please keep all content family-friendly and professional.',
      );
    }

    for (final word in _bannedWords) {
      final needle = _normalizeForProfanity(word).trim();
      if (needle.isEmpty) continue;
      final isPhrase = needle.contains(' ');
      final regex = RegExp(
        isPhrase
            ? '\\b${RegExp.escape(needle).replaceAll(' ', r'\s+')}\\b'
            : '\\b${RegExp.escape(needle)}\\b',
        caseSensitive: false,
      );
      final inNormalized = regex.hasMatch(normalized);
      // Catch obfuscated spacing/punctuation for longer words only.
      final inCompact =
          !isPhrase && needle.length >= 4 && compact.contains(needle);

      if (inNormalized || inCompact) {
        return const ModerationResult(
          approved: false,
          reason:
              'Your post contains inappropriate language and has been blocked. '
              'Please keep all content family-friendly and professional.',
        );
      }
    }
    return null;
  }

  static String _normalizeForProfanity(String text) {
    final lower = text.toLowerCase();
    final leetNormalized = lower
        .replaceAll('@', 'a')
        .replaceAll('4', 'a')
        .replaceAll('3', 'e')
        .replaceAll('1', 'i')
        .replaceAll('!', 'i')
        .replaceAll('|', 'i')
        .replaceAll('0', 'o')
        .replaceAll('5', 's')
        .replaceAll(r'$', 's')
        .replaceAll('7', 't');

    return leetNormalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _looksLikeObfuscatedProfanity(String text) {
    // Fast-path: masked profanity shapes like f***, sh!t, b!tch, etc.
    final obviousMask = RegExp(
      r'\b[a-z][a-z0-9]*[\*\!@#\$%&]+[a-z0-9]*\b',
      caseSensitive: false,
    );
    final hasObviousMask = obviousMask.hasMatch(text);

    final tokens = text.split(RegExp(r'\s+'));
    for (final raw in tokens) {
      final token = raw.trim();
      if (token.length < 3) continue;

      final hasMaskChars = RegExp(r'[\*\!@#\$%&0-9_]').hasMatch(token);
      if (!hasMaskChars && !hasObviousMask) continue;

      final normalizedToken = _normalizeForProfanity(token).replaceAll(' ', '');
      if (normalizedToken.length < 3) continue;

      for (final stem in _blockedStems) {
        if (stem.length < 3) continue;
        if (normalizedToken.contains(stem)) {
          return true;
        }
      }
    }

    return false;
  }

  static ModerationResult? _checkSuspicious(String text) {
    for (final pattern in _suspiciousPatterns) {
      if (text.contains(pattern.toLowerCase())) {
        return const ModerationResult(
          approved: false,
          reason:
              'Your post was flagged for containing suspicious content. '
              'Please make sure your listing is safe, appropriate, and genuine.',
        );
      }
    }
    return null;
  }

  static bool _isAllCaps(String text) {
    final letters = text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.length < 5) return false;
    return letters == letters.toUpperCase();
  }

  static bool _hasExcessiveRepetition(String text) {
    final repeating = RegExp(r'(.)\1{5,}');
    if (repeating.hasMatch(text)) return true;

    final words = text.split(RegExp(r'\s+'));
    if (words.length >= 5) {
      final unique = words.toSet();
      if (unique.length <= words.length * 0.2) return true;
    }
    return false;
  }

  static Future<ModerationResult> moderateMessage(String text) async {
    final lower = text.toLowerCase();

    final profanity = _checkProfanity(lower);
    if (profanity != null) return profanity;

    final suspicious = _checkSuspicious(lower);
    if (suspicious != null) return suspicious;

    if (_hasExcessiveRepetition(lower)) {
      return const ModerationResult(
        approved: false,
        reason: 'Your message looks like spam.',
      );
    }

    final aiResult = await _validateWithAi(text);
    if (!aiResult.approved) return aiResult;

    return const ModerationResult(approved: true);
  }

  static Future<ModerationResult> _validateWithAi(String text) async {
    try {
      final callable = _functions.httpsCallable('validatePost');
      final res = await callable
          .call({'text': text})
          .timeout(const Duration(seconds: 12));
      final data = res.data;
      if (data is Map && data['safe'] == true) {
        return const ModerationResult(approved: true);
      }
      final reason = data is Map ? data['reason']?.toString() : null;
      return ModerationResult(
        approved: false,
        reason: reason?.isNotEmpty == true
            ? reason
            : 'Blocked by AI safety checks.',
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied') {
        return ModerationResult(
          approved: false,
          reason: e.message?.isNotEmpty == true
              ? e.message
              : 'Blocked by AI safety checks.',
        );
      }
      // Fail open for temporary backend issues; local moderation already ran.
      return const ModerationResult(approved: true);
    } catch (_) {
      // Fail open for temporary backend issues; local moderation already ran.
      return const ModerationResult(approved: true);
    }
  }

  // --- Profile validation ---

  static ModerationResult validateProfileField(String field, String value) {
    if (value.isEmpty) return const ModerationResult(approved: true);

    final lower = value.toLowerCase();

    final profanity = _checkProfanity(lower);
    if (profanity != null) {
      return ModerationResult(
        approved: false,
        reason: 'Your $field contains inappropriate language.',
      );
    }

    if (_hasExcessiveRepetition(lower)) {
      return ModerationResult(
        approved: false,
        reason: 'Your $field looks like gibberish. Please enter something real.',
      );
    }

    if (_isGibberish(value)) {
      return ModerationResult(
        approved: false,
        reason: 'Your $field doesn\'t look right. Please enter real information.',
      );
    }

    return const ModerationResult(approved: true);
  }

  static ModerationResult validateName(String name) {
    if (name.isEmpty) {
      return const ModerationResult(
          approved: false, reason: 'Name is required.');
    }
    if (name.length < 2) {
      return const ModerationResult(
          approved: false, reason: 'Name is too short.');
    }
    if (!RegExp(r"^[a-zA-Z\s\-'\.]+$").hasMatch(name)) {
      return const ModerationResult(
        approved: false,
        reason: 'Name should only contain letters, spaces, and hyphens.',
      );
    }
    return validateProfileField('name', name);
  }

  /// Returns true if the text contains inappropriate/banned content.
  static bool containsProfanity(String text) {
    final lower = text.toLowerCase();
    return _checkProfanity(lower) != null;
  }

  /// Cleans harsh/insulting tone from text, replacing insults with neutral
  /// factual language. Returns the cleaned text.
  static String cleanTone(String text) {
    var result = text;

    for (final entry in _toneReplacements.entries) {
      result = result.replaceAll(
        RegExp(entry.key, caseSensitive: false),
        entry.value,
      );
    }

    return result;
  }

  static const _toneReplacements = <String, String>{
    r'\bgarbage\b': 'unreliable',
    r'\btrash\b': 'unreliable',
    r'\bterrible\b': 'poor',
    r'\bhorrible\b': 'poor',
    r'\bawful\b': 'poor',
    r'\buseless\b': 'unhelpful',
    r'\bworthless\b': 'unhelpful',
    r'\bstupid\b': 'inexperienced',
    r'\bidiot\b': 'inexperienced',
    r'\bmoron\b': 'inexperienced',
    r'\bdumb\b': 'inexperienced',
    r"\bdidn'?t\s+do\s+(anything|nothing|crap|jack|squat)\b": "didn't complete the work",
    r'\blazy\b': 'not motivated',
    r'\bpathetic\b': 'disappointing',
    r'\bjoke\b': 'disappointing',
    r'\bscam(?:mer)?\b': 'not trustworthy',
    r'\brip\s*off\b': 'overcharging',
    r'\bripped\s+(?:me|us)\s+off\b': 'overcharged',
    r'\bwaste\s+of\s+(time|money)\b': 'not worth the cost',
    r'\bthe\s+worst\b': 'very poor',
    r'\bsucks?\b': 'was disappointing',
    r'\bsucked\b': 'was disappointing',
    r'\bcrap(?:py)?\b': 'poor quality',
    r'\bliar\b': 'dishonest',
    r'\blied\b': 'was not truthful',
    r'\bfake\b': 'misleading',
    r'\bnever\s+showed\s+up\b': 'did not show up',
    r'\bghosts?\b': 'stopped responding',
    r'\bghosted\b': 'stopped responding',
    r'\bincompetent\b': 'not skilled enough',
    r'\bhalf[- ]?assed\b': 'incomplete',
    r'\bsloppy\b': 'careless',
    r'\brunning\s+a\s+scam\b': 'not being transparent',
  };

  /// Returns true if text contains harsh tone that should be cleaned.
  static bool hasHarshTone(String text) {
    final lower = text.toLowerCase();
    return _toneReplacements.keys.any(
      (pattern) => RegExp(pattern, caseSensitive: false).hasMatch(lower),
    );
  }

  /// Returns true if the word looks like a plausible real name (not gibberish).
  static bool isPlausibleName(String word) {
    if (word.length < 2) return false;
    if (word.length <= 3) return true;
    if (_isSingleWordGibberish(word.toLowerCase())) return false;
    return true;
  }

  /// Returns true if the email local part looks like a real identifier.
  static bool isPlausibleEmailLocal(String email) {
    final local = email.split('@').first.toLowerCase()
        .replaceAll(RegExp(r'[^a-z]'), '');
    if (local.length < 3) return true;
    if (_isSingleWordGibberish(local)) return false;
    return true;
  }

  static ModerationResult validateLocation(String location) {
    if (location.isEmpty) return const ModerationResult(approved: true);

    if (location.length < 3) {
      return const ModerationResult(
        approved: false,
        reason: 'Location is too short. Enter a city or neighborhood.',
      );
    }

    if (!RegExp(r'[a-zA-Z]').hasMatch(location)) {
      return const ModerationResult(
        approved: false,
        reason: 'Location should contain a place name.',
      );
    }

    if (_isGibberish(location)) {
      return const ModerationResult(
        approved: false,
        reason: 'That doesn\'t look like a real location. Try something like "Toronto, ON".',
      );
    }

    return validateProfileField('location', location);
  }

  static ModerationResult validateAge(String ageStr) {
    if (ageStr.isEmpty) return const ModerationResult(approved: true);
    final age = int.tryParse(ageStr);
    if (age == null) {
      return const ModerationResult(
          approved: false, reason: 'Age must be a number.');
    }
    if (age < 13 || age > 19) {
      return const ModerationResult(
        approved: false,
        reason: 'TeenWorkly is for teens aged 13–19.',
      );
    }
    return const ModerationResult(approved: true);
  }

  static ModerationResult validateBio(String bio) {
    if (bio.isEmpty) return const ModerationResult(approved: true);
    if (_isGibberish(bio) && bio.length > 5) {
      return const ModerationResult(
        approved: false,
        reason: 'Your bio doesn\'t look right. Write a real description of yourself.',
      );
    }
    return validateProfileField('bio', bio);
  }

  static Future<ModerationResult> validateAiBuilderInputs({
    required String skills,
    required String likes,
    required String personality,
    required String goal,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (skills.isEmpty && likes.isEmpty && personality.isEmpty && goal.isEmpty) {
      return const ModerationResult(
        approved: false,
        reason: 'Please fill in at least one field so we can build your profile.',
      );
    }

    for (final entry in {
      'skills': skills,
      'interests': likes,
      'personality': personality,
      'goal': goal,
    }.entries) {
      if (entry.value.isEmpty) continue;

      final check = validateProfileField(entry.key, entry.value);
      if (!check.approved) return check;
    }

    return const ModerationResult(approved: true);
  }

  static const _commonWords = <String>{
    'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'is', 'it', 'my', 'me', 'we', 'he', 'so', 'do', 'no', 'up',
    'i', 'am', 'are', 'was', 'be', 'has', 'had', 'not', 'you', 'all',
    'can', 'her', 'his', 'one', 'our', 'out', 'day', 'get', 'how', 'its',
    'may', 'new', 'now', 'old', 'see', 'two', 'way', 'who', 'did', 'let',
    'say', 'she', 'too', 'use', 'boy', 'man', 'run', 'big', 'set', 'try',
    'ask', 'own', 'put', 'end', 'why', 'lot', 'car', 'pay', 'job', 'dog',
    'cat', 'kid', 'fun', 'help', 'good', 'great', 'like', 'just', 'know',
    'take', 'come', 'make', 'find', 'give', 'tell', 'call', 'work', 'keep',
    'them', 'then', 'than', 'been', 'have', 'many', 'some', 'when', 'what',
    'with', 'this', 'that', 'from', 'they', 'will', 'each', 'about', 'which',
    'their', 'there', 'would', 'other', 'into', 'more', 'time', 'very',
    'your', 'also', 'back', 'after', 'year', 'much', 'most', 'over', 'such',
    'only', 'long', 'made', 'well', 'want', 'look', 'here', 'need', 'home',
    'love', 'hard', 'nice', 'best', 'fast', 'play', 'read', 'walk', 'done',
    'sure', 'goes', 'went', 'able', 'feel', 'care', 'cook', 'lawn', 'mow',
    'snow', 'wash', 'tech', 'math', 'code', 'draw', 'sing', 'swim', 'ride',
    'bake', 'game', 'move', 'shop', 'plan', 'team', 'hand', 'yard', 'baby',
    'clean', 'house', 'paint', 'teach', 'learn', 'study', 'drive', 'build',
    'money', 'school', 'people', 'really', 'doing', 'being', 'thing',
    'think', 'still', 'every', 'never', 'world', 'start', 'might', 'while',
    'where', 'those', 'these', 'right', 'place', 'small', 'large', 'young',
    'first', 'last', 'going', 'little', 'under', 'water', 'human',
    'spend', 'creative', 'reliable', 'funny', 'working', 'strong', 'smart',
    'honest', 'friendly', 'patient', 'kind', 'enjoy', 'skill', 'save',
    'experience', 'community', 'guitar', 'coding', 'cooking', 'gardening',
    'tutoring', 'walking', 'running', 'helping', 'earning', 'investing',
    'sitting', 'shoveling', 'landscaping', 'delivering', 'organizing',
    'babysitting', 'photography', 'design', 'music', 'sports', 'art',
    'writing', 'fitness', 'cleaning', 'shopping', 'moving', 'packing',
    'painting', 'mowing', 'raking', 'weeding', 'trimming', 'fixing',
    'detail', 'focused', 'motivated', 'dedicated', 'responsible',
    'trustworthy', 'energetic', 'outgoing', 'positive', 'determined',
    'around', 'city', 'town', 'area', 'street', 'road', 'park', 'east',
    'west', 'north', 'south', 'lake', 'river', 'hill', 'high', 'middle',
    'college', 'university', 'academy', 'prep', 'secondary', 'public',
    'private', 'toronto', 'vancouver', 'calgary', 'ottawa', 'montreal',
    'edmonton', 'winnipeg', 'halifax', 'york', 'chicago', 'boston',
    'seattle', 'austin', 'denver', 'miami', 'atlanta', 'dallas', 'houston',
    'phoenix', 'angeles', 'francisco', 'diego', 'jose', 'portland',
    'london', 'paris', 'berlin', 'sydney', 'melbourne', 'brampton',
    'mississauga', 'hamilton', 'surrey', 'burnaby', 'richmond',
    'etobicoke', 'scarborough', 'markham', 'oakville', 'burlington',
    'invest', 'future', 'goal', 'dream', 'independence', 'cash', 'pocket',
    'tuition', 'savings', 'summer', 'spring', 'winter', 'fall',
    'weekend', 'evening', 'morning', 'afternoon', 'available', 'flexible',
    'dogs', 'pets', 'stuff', 'things', 'anything',
  };

  static const _keyboardRows = [
    'qwertyuiop',
    'asdfghjkl',
    'zxcvbnm',
  ];

  static bool _isGibberish(String text) {
    if (text.length < 3) return false;

    final words = text
        .toLowerCase()
        .split(RegExp(r'[\s,;.!?/\-]+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return false;

    if (words.length == 1 && words[0].length >= 4) {
      return _isSingleWordGibberish(words[0]);
    }

    int realWords = 0;
    int gibberishWords = 0;
    for (final w in words) {
      if (_commonWords.contains(w) || w.length <= 2) {
        realWords++;
      } else if (_isSingleWordGibberish(w)) {
        gibberishWords++;
      } else {
        realWords++;
      }
    }

    if (words.length >= 2 && gibberishWords >= words.length * 0.6) return true;
    if (gibberishWords > 0 && realWords == 0) return true;

    return false;
  }

  static const _englishBigrams = <String>{
    'th', 'he', 'in', 'er', 'an', 're', 'nd', 'at', 'on', 'nt',
    'ha', 'es', 'st', 'en', 'ed', 'to', 'it', 'ou', 'ea', 'hi',
    'is', 'or', 'ti', 'as', 'te', 'et', 'ng', 'of', 'al', 'de',
    'se', 'le', 'sa', 'si', 'ar', 've', 'ra', 'ri', 'ro', 'ne',
    'li', 'la', 'io', 'ic', 'ce', 'ta', 'el', 'ma', 'me', 'mi',
    'mo', 'na', 'no', 'ni', 'pe', 'pl', 'pr', 'po', 'pa', 'co',
    'ca', 'ch', 'cl', 'cr', 'cu', 'da', 'di', 'do', 'dr', 'du',
    'fi', 'fo', 'fr', 'fu', 'ge', 'gi', 'go', 'gr', 'gu', 'ho',
    'hu', 'id', 'ig', 'il', 'im', 'ir', 'iv', 'ke', 'ki', 'kn',
    'lo', 'lu', 'ly', 'mu', 'oi', 'ol', 'om', 'op', 'ow', 'oo',
    'os', 'ot', 'ph', 'qu', 'sc', 'sh', 'sk', 'sl', 'sm', 'sn',
    'so', 'sp', 'su', 'sw', 'tr', 'tu', 'tw', 'ty', 'un', 'up',
    'ur', 'us', 'ut', 'wa', 'we', 'wi', 'wo', 'wh', 'wr', 'yo',
    'ab', 'ac', 'ad', 'ag', 'ai', 'ak', 'am', 'ap', 'au', 'av',
    'aw', 'ay', 'ba', 'be', 'bi', 'bl', 'bo', 'br', 'bu', 'by',
    'ci', 'ct', 'cy', 'dy', 'ee', 'ef', 'eg', 'em', 'ep', 'ev',
    'ex', 'ey', 'fe', 'fl', 'ga', 'gl', 'gn', 'gy', 'ib', 'ie',
    'if', 'ip', 'iz', 'ja', 'jo', 'ju', 'ld', 'lf', 'lk', 'll',
    'lm', 'ln', 'ls', 'lt', 'lv', 'mb', 'mm', 'mn', 'mp', 'ms',
    'nc', 'nk', 'nn', 'ns', 'nu', 'ny', 'ob', 'oc', 'od', 'og',
    'ok', 'ov', 'ox', 'oy', 'pi', 'pt', 'pu', 'rb', 'rc',
    'rd', 'rf', 'rg', 'rk', 'rl', 'rm', 'rn', 'rp', 'rs', 'rt',
    'ru', 'rv', 'ry', 'sb', 'ss', 'sy', 'tt', 'ua', 'ub', 'uc',
    'ud', 'ue', 'ug', 'ui', 'uk', 'ul', 'um', 'vi', 'vo',
  };

  static bool _hasEnglishStructure(String word) {
    if (word.length < 4) return true;
    final lower = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (lower.length < 4) return true;

    int commonPairs = 0;
    final totalPairs = lower.length - 1;
    for (int i = 0; i < totalPairs; i++) {
      if (_englishBigrams.contains(lower.substring(i, i + 2))) {
        commonPairs++;
      }
    }

    return commonPairs / totalPairs >= 0.5;
  }

  static bool _isSingleWordGibberish(String word) {
    if (_commonWords.contains(word)) return false;
    if (word.length < 4) return false;

    final letters = word.replaceAll(RegExp(r'[^a-z]'), '');
    if (letters.isEmpty) return false;

    final uniqueChars = letters.split('').toSet();
    if (uniqueChars.length <= 2 && letters.length >= 4) return true;

    if (_hasRepeatingPattern(letters)) return true;

    if (_isKeyboardMash(letters)) return true;

    if (!_hasEnglishStructure(letters)) return true;

    final consonants = letters.replaceAll(RegExp(r'[aeiou]'), '');
    final vowelRatio =
        (letters.length - consonants.length) / letters.length;
    if (vowelRatio < 0.1 && letters.length > 4) return true;

    if (letters.length >= 6) {
      if (RegExp(r'[bcdfghjklmnpqrstvwxyz]{5,}').hasMatch(letters)) {
        return true;
      }
    }

    if (RegExp(r'([a-z])\1{3,}').hasMatch(letters)) return true;

    return false;
  }

  static bool _hasRepeatingPattern(String text) {
    if (text.length < 4) return false;

    for (int patLen = 1; patLen <= 3; patLen++) {
      if (text.length < patLen * 2) continue;
      final pattern = text.substring(0, patLen);
      final repeated = pattern * ((text.length ~/ patLen) + 1);
      if (repeated.startsWith(text)) return true;
    }

    for (int patLen = 2; patLen <= 3; patLen++) {
      int repeats = 0;
      for (int i = 0; i <= text.length - patLen; i += patLen) {
        final chunk = text.substring(i, (i + patLen).clamp(0, text.length));
        if (chunk == text.substring(0, chunk.length.clamp(0, patLen))) {
          repeats++;
        }
      }
      if (repeats >= 2 && repeats * patLen >= text.length * 0.7) return true;
    }

    return false;
  }

  static bool _isKeyboardMash(String text) {
    if (text.length < 4) return false;

    int adjacentPairs = 0;
    for (int i = 0; i < text.length - 1; i++) {
      if (_areKeysAdjacent(text[i], text[i + 1])) {
        adjacentPairs++;
      }
    }

    final ratio = adjacentPairs / (text.length - 1);
    if (ratio > 0.75 && text.length >= 4) return true;

    return false;
  }

  static bool _areKeysAdjacent(String a, String b) {
    if (a == b) return true;
    for (final row in _keyboardRows) {
      final idxA = row.indexOf(a);
      final idxB = row.indexOf(b);
      if (idxA >= 0 && idxB >= 0 && (idxA - idxB).abs() <= 1) return true;
    }
    for (int r = 0; r < _keyboardRows.length - 1; r++) {
      final idxA = _keyboardRows[r].indexOf(a);
      final idxB = _keyboardRows[r + 1].indexOf(b);
      if (idxA >= 0 && idxB >= 0 && (idxA - idxB).abs() <= 1) return true;
      final idxA2 = _keyboardRows[r + 1].indexOf(a);
      final idxB2 = _keyboardRows[r].indexOf(b);
      if (idxA2 >= 0 && idxB2 >= 0 && (idxA2 - idxB2).abs() <= 1) return true;
    }
    return false;
  }

  static double? _extractPayFromText(String text) {
    final match = RegExp(r'\$\s*(\d+(?:\.\d{1,2})?)').firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }
}
