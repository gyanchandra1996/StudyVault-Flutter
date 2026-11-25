import '../models/user_profile.dart';
import '../models/target_exam_reminder.dart';

class AarnaLocalService {
  /// Generates a local, offline response from Aarna using user profile, exams context, and study heuristics.
  static String generateOfflineResponse({
    required String query,
    required UserProfile profile,
    List<TargetExamReminder> targetExams = const [],
    int totalQuestions = 0,
    int dueFlashcards = 0,
    String? contextNotes,
  }) {
    final q = query.toLowerCase().trim();
    final name = profile.name.isNotEmpty ? profile.name : 'Aspirant';

    // 1. Identity & "About Me" / Personal Information Queries
    if (q.contains('who am i') || q.contains('about me') || q.contains('my profile') || q.contains('mera naam') || q.contains('who are you') || q.contains('who is aarna')) {
      final examsStr = profile.targetExams.isNotEmpty ? profile.targetExams.join(', ') : 'Competitive Exams';
      final focusStr = profile.focusSubjects.isNotEmpty ? profile.focusSubjects.join(', ') : 'All general subjects';

      if (q.contains('who are you') || q.contains('who is aarna')) {
        return '''Namaste $name! 🙏 I am **Aarna (आर्ना)**, your personal AI study companion and academic mentor in Medhavi.

I am built to know your target goals, track your revision, and help you crack your exams:
• **Your Name**: $name
• **Target Exams**: $examsStr
• **Focus Subjects**: $focusStr
• **Daily Target**: ${profile.dailyGoalHours} hours/day
• **Active AI Mode**: Built-in Local Engine (Offline & Private)

You can ask me questions on formulas, study plans, key concepts, or link me with **Google Gemini** in Settings for cloud-powered answers!''';
      }

      return '''Here is what I remember about you, **$name**:

👤 **Student Profile**:
• **Name**: $name
• **Target Exams**: $examsStr
• **Focus Subjects**: $focusStr
• **Core Strengths**: ${profile.strongAreas}
• **Focus/Weak Areas**: ${profile.weakAreas}
• **Daily Goal**: ${profile.dailyGoalHours} Hours / Day
• **Preferred Language**: ${profile.preferredLanguage}
• **Personal Notes**: ${profile.customBioNotes.isNotEmpty ? profile.customBioNotes : 'None added yet'}

💡 *Tip: You can update your information anytime by tapping the profile badge at the top of this screen!*''';
    }

    // 2. Target Exams & Schedule Queries
    if (q.contains('exam') || q.contains('target') || q.contains('countdown') || q.contains('kab hai') || q.contains('days left')) {
      if (targetExams.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln('Here is your live **Target Exam Countdown**, $name:\n');
        for (final exam in targetExams) {
          final days = exam.daysRemaining;
          final status = days > 0
              ? '⏳ **$days days remaining**'
              : (days == 0 ? '🚨 **EXAM IS TODAY!**' : '✅ Completed');
          buffer.writeln('• **${exam.title}** (${exam.examDate}): $status');
          if (exam.targetScore.isNotEmpty) {
            buffer.writeln('  *Target Score:* ${exam.targetScore}');
          }
        }
        buffer.writeln('\n🎯 **Aarna\'s Advice for Today**:');
        buffer.writeln('Prioritize your weakest topics in **${profile.weakAreas}** and review your $dueFlashcards due flashcards today!');
        return buffer.toString();
      } else {
        return '''You currently have **${profile.targetExams.join(', ')}** set as your primary target!

To see live countdowns and get automated daily alerts, add your specific exam dates in the **Target Exam Countdown** widget on your Dashboard!''';
      }
    }

    // 3. Weak Areas & Study Plan / Strategy Queries
    if (q.contains('weak') || q.contains('plan') || q.contains('timetable') || q.contains('strategy') || q.contains('kaise padhe') || q.contains('schedule')) {
      return '''### 🎯 High-Yield Study Plan for $name (${profile.targetExams.firstOrNull ?? 'Exam'})

Based on your profile, your primary focus should be on: **${profile.weakAreas}**.

**Recommended Daily ${profile.dailyGoalHours}-Hour Routine**:
1. 🌅 **Block 1 (90 Mins) - Peak Cognitive Time**:
   • Focus on difficult concepts in *${profile.weakAreas}*.
   • Use the **Feynman Technique**: Explain each concept in simple language on paper.
2. ⚡ **Block 2 (60 Mins) - Active Recall & Practice**:
   • Attempt at least 15-20 practice questions from the Quizzes tab.
   • Review your **$dueFlashcards due flashcards**.
3. 📖 **Block 3 (90 Mins) - High-Scoring Revision**:
   • Consolidate notes in *${profile.strongAreas}* to ensure maximum accuracy and zero negative marks.
4. 🌙 **Block 4 (30 Mins) - Nightly Micro-Review**:
   • Solve 1 round of **Brain Games (Speed Math or Schulte Grid)** to maintain mental sharpness!''';
    }

    // 4. Study Methods (Pomodoro, Feynman, Active Recall)
    if (q.contains('pomodoro') || q.contains('feynman') || q.contains('active recall') || q.contains('spaced repetition') || q.contains('focus') || q.contains('memorize')) {
      return '''### 🧠 Scientifically Proven Study Methods (Built-in Aarna Guide)

1. **🍅 The Pomodoro Technique**:
   • 25 minutes of 100% focused study + 5 minutes absolute break.
   • After 4 cycles, take a longer 20-minute restorative walk or water break.
   • *You can use the built-in Pomodoro timer in Medhavi!*

2. **📝 The Feynman Technique**:
   • Step 1: Pick a complex concept (e.g., Article 32 or Newton's 3rd Law).
   • Step 2: Explain it as if teaching a 10-year-old without technical jargon.
   • Step 3: Identify knowledge gaps and re-read source notes.

3. **🗂️ SuperMemo Spaced Repetition (SM-2)**:
   • Review information right at the forgetting curve threshold ($1, 3, 7, 14, 30$ days).
   • *Medhavi\'s Flashcard section uses this exact SM-2 algorithm automatically!*''';
    }

    // 5. Subject Concept Heuristics: Indian Polity
    if (q.contains('polity') || q.contains('constitution') || q.contains('article') || q.contains('fundamental right') || q.contains('preamble')) {
      return '''### 🏛️ High-Yield Indian Polity Quick Reference:

• **Preamble**: Declares India as *Sovereign, Socialist, Secular, Democratic, Republic* and secures Justice, Liberty, Equality, Fraternity. Added by 42nd Amendment (1976): Socialist, Secular, Integrity.
• **Part III - Fundamental Rights (Articles 12-35)**:
  - Art 14: Equality before law
  - Art 19: Six freedoms (speech, assembly, association, movement, residence, profession)
  - Art 21: Right to Life & Personal Liberty
  - Art 21A: Right to Education (86th Amendment, 2002)
  - Art 32: Right to Constitutional Remedies (*"Heart and Soul of the Constitution"* - Dr. B.R. Ambedkar; Habeas Corpus, Mandamus, Prohibition, Quo-Warranto, Certiorari)
• **Emergency Provisions**:
  - Art 352: National Emergency (War, External Aggression, Armed Rebellion)
  - Art 356: President's Rule (State Emergency)
  - Art 360: Financial Emergency (Never declared in India so far)''';
    }

    // 6. Subject Concept Heuristics: Modern History
    if (q.contains('history') || q.contains('gandhi') || q.contains('1857') || q.contains('congress') || q.contains('movement')) {
      return '''### ⚔️ Modern Indian History Chronology Cheat Sheet:

• **1857**: First War of Indian Independence / Revolt of 1857 (Bahadur Shah Zafar, Rani Lakshmibai, Mangal Pandey).
• **1885**: Formation of Indian National Congress (A.O. Hume, 1st President: W.C. Bonnerjee, Bombay).
• **1905**: Partition of Bengal (Lord Curzon) & Swadeshi Movement.
• **1919**: Rowlatt Act & Jallianwala Bagh Massacre (13 April 1919, General Dyer).
• **1920-22**: Non-Cooperation Movement (Suspended after Chauri Chaura incident, Feb 1922).
• **1930**: Dandi March & Civil Disobedience Movement (Salt Satyagraha, 12 March to 6 April).
• **1931**: Gandhi-Irwin Pact & 2nd Round Table Conference.
• **1942**: Quit India Movement (8 August 1942, "Do or Die" call by Gandhiji).
• **1947**: Indian Independence Act (Mountbatten Plan).''';
    }

    // 7. Subject Concept Heuristics: General Science
    if (q.contains('science') || q.contains('physics') || q.contains('chemistry') || q.contains('biology') || q.contains('vitamin')) {
      return '''### 🔬 General Science High-Probability Points:

• **Important Vitamins & Deficiency Diseases**:
  - Vitamin A (Retinol) $\\to$ Night Blindness, Xerophthalmia
  - Vitamin B1 (Thiamine) $\\to$ Beriberi
  - Vitamin C (Ascorbic Acid) $\\to$ Scurvy
  - Vitamin D (Calciferol) $\\to$ Rickets (children), Osteomalacia
  - Vitamin K (Phylloquinone) $\\to$ Delayed blood clotting
• **Physics Laws**:
  - Newton's 1st Law: Law of Inertia
  - Newton's 2nd Law: $F = m \\times a$ (Force equals rate of change of momentum)
  - Newton's 3rd Law: Every action has an equal and opposite reaction
• **Chemistry Essentials**:
  - pH Scale: $<7$ Acidic, $7$ Neutral, $>7$ Basic. Human blood pH: $\\approx 7.35 - 7.45$.
  - Rusting of iron is a chemical change (Oxidation: $Fe_2O_3 \\cdot xH_2O$).''';
    }

    // 8. Math & Quantitative Aptitude Tricks
    if (q.contains('math') || q.contains('aptitude') || q.contains('formula') || q.contains('percentage') || q.contains('profit') || q.contains('speed')) {
      return '''### 🔢 High-Speed Math & Calculation Shortcuts:

1. **Square of numbers ending in 5**:
   • Example: $65^2$: Multiply $6 \\times (6 + 1) = 42$, append $25 \\to 4225$.
   • Example: $85^2 = 8 \\times 9 = 72 \\to 7225$.
2. **Speed, Distance & Time**:
   • $\\text{Speed} = \\frac{\\text{Distance}}{\\text{Time}}$
   • $\\text{km/h} \\to \\text{m/s}$: Multiply by $\\frac{5}{18}$
   • $\\text{m/s} \\to \\text{km/h}$: Multiply by $\\frac{18}{5}$
3. **Compound Interest Shortcuts**:
   • Difference between CI and SI for 2 years: $D = P \\left(\\frac{R}{100}\\right)^2$
4. **Profit & Loss**:
   • $\\text{Profit \\%} = \\frac{\\text{Profit}}{\\text{Cost Price}} \\times 100$
   • If selling price of $x$ items equals cost price of $y$ items: $\\text{Gain \\%} = \\frac{y - x}{x} \\times 100$.''';
    }

    // 9. Document Context Query (if student is reviewing PDF notes)
    if (contextNotes != null && contextNotes.trim().isNotEmpty) {
      return '''Based on your active study notes:

$contextNotes

💡 **Aarna's Observation**:
You asked: "$query"
Make sure to convert the key points of these notes into flashcards in the Flashcards tab so they are scheduled for spaced repetition review!''';
    }

    // 10. Default General Encouragement & Offline Guidance
    return '''Hello $name! 🌟 As your study companion **Aarna**, here is my guidance on **"$query"**:

1. **Break it Down**:
   Divide this topic into 3 core sub-concepts. Focus on definitions first, followed by previous year questions (PYQs).

2. **Personalized Next Step for ${profile.targetExams.firstOrNull ?? 'Your Exam'}**:
   • Read the relevant chapter in your Document Vault notes.
   • Head to the **Quizzes** tab to test your recall.
   • Don't forget to practice today's **Speed Math Blitz** in Tools!

💡 *Note: I am running on my built-in offline engine. To ask open-ended questions powered by Google Gemini, enable Gemini in Settings!*''';
  }
}
