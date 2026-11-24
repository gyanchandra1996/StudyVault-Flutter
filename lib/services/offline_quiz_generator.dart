import '../models/question.dart';

class OfflineQuizGenerator {
  static final List<QuizQuestion> _allCuratedQuestions = [
    // ---------------- POLITY & CONSTITUTION ----------------
    QuizQuestion(
      questionText: 'Which Article of the Indian Constitution is known as the "Heart and Soul of the Constitution" according to Dr. B.R. Ambedkar?',
      optionA: 'Article 14',
      optionB: 'Article 19',
      optionC: 'Article 21',
      optionD: 'Article 32',
      correctOptionIndex: 3,
      explanation: 'Article 32 confers the Right to Constitutional Remedies, enabling citizens to approach the Supreme Court directly for the enforcement of Fundamental Rights.',
      subject: 'Polity',
    ),
    QuizQuestion(
      questionText: 'Under which Schedule of the Indian Constitution are the Official Languages listed?',
      optionA: 'Seventh Schedule',
      optionB: 'Eighth Schedule',
      optionC: 'Ninth Schedule',
      optionD: 'Tenth Schedule',
      correctOptionIndex: 1,
      explanation: 'The Eighth Schedule lists the 22 official languages recognized by the Constitution of India.',
      subject: 'Polity',
    ),
    QuizQuestion(
      questionText: 'Who acts as the ex-officio Chairman of the Rajya Sabha in India?',
      optionA: 'The President',
      optionB: 'The Vice-President',
      optionC: 'The Prime Minister',
      optionD: 'The Speaker of Lok Sabha',
      correctOptionIndex: 1,
      explanation: 'Under Article 64, the Vice-President of India is the ex-officio Chairman of the Council of States (Rajya Sabha).',
      subject: 'Polity',
    ),
    QuizQuestion(
      questionText: 'The concept of "Fundamental Duties" in the Indian Constitution was borrowed from which country?',
      optionA: 'USA',
      optionB: 'USSR (Russia)',
      optionC: 'United Kingdom',
      optionD: 'Ireland',
      correctOptionIndex: 1,
      explanation: 'Fundamental Duties under Article 51A were incorporated by the 42nd Amendment Act, 1976, inspired by the Constitution of the erstwhile USSR.',
      subject: 'Polity',
    ),
    QuizQuestion(
      questionText: 'What is the minimum age required to become a member of the Lok Sabha?',
      optionA: '18 years',
      optionB: '21 years',
      optionC: '25 years',
      optionD: '30 years',
      correctOptionIndex: 2,
      explanation: 'Article 84(b) prescribes a minimum age of 25 years for Lok Sabha and 30 years for Rajya Sabha membership.',
      subject: 'Polity',
    ),
    QuizQuestion(
      questionText: 'भारतीय संविधान की प्रस्तावना में "धर्मनिरपेक्ष" और "समाजवादी" शब्द किस संशोधन द्वारा जोड़े गए?',
      optionA: '42वां संविधान संशोधन (1976)',
      optionB: '44वां संविधान संशोधन (1978)',
      optionC: '52वां संविधान संशोधन (1985)',
      optionD: '73वां संविधान संशोधन (1992)',
      correctOptionIndex: 0,
      explanation: '42वें संविधान संशोधन अधिनियम 1976 द्वारा प्रस्तावना में समाजवादी, धर्मनिरपेक्ष और अखंडता शब्द जोड़े गए थे।',
      subject: 'Polity',
    ),

    // ---------------- HISTORY ----------------
    QuizQuestion(
      questionText: 'In which year was the historic Battle of Plassey fought?',
      optionA: '1757',
      optionB: '1764',
      optionC: '1857',
      optionD: '1761',
      correctOptionIndex: 0,
      explanation: 'The Battle of Plassey took place on 23 June 1757 between the British East India Company led by Robert Clive and Nawab Siraj-ud-Daulah of Bengal.',
      subject: 'History',
    ),
    QuizQuestion(
      questionText: 'Who was the founder of the Maurya Empire in ancient India?',
      optionA: 'Ashoka the Great',
      optionB: 'Bindusara',
      optionC: 'Chandragupta Maurya',
      optionD: 'Samudragupta',
      correctOptionIndex: 2,
      explanation: 'Chandragupta Maurya founded the Maurya Empire in 322 BCE with the strategic guidance of Chanakya (Kautilya).',
      subject: 'History',
    ),
    QuizQuestion(
      questionText: 'The famous "Quit India Movement" was launched in which year?',
      optionA: '1920',
      optionB: '1930',
      optionC: '1942',
      optionD: '1947',
      correctOptionIndex: 2,
      explanation: 'Mahatma Gandhi launched the Quit India Movement on 8 August 1942 at the Bombay session of the All-India Congress Committee.',
      subject: 'History',
    ),
    QuizQuestion(
      questionText: 'Who founded the "Arya Samaj" in 1875?',
      optionA: 'Raja Ram Mohan Roy',
      optionB: 'Swami Dayanand Saraswati',
      optionC: 'Swami Vivekananda',
      optionD: 'Ishwar Chandra Vidyasagar',
      correctOptionIndex: 1,
      explanation: 'Swami Dayanand Saraswati founded the Arya Samaj in Bombay in 1875 promoting Vedic revival and social reform.',
      subject: 'History',
    ),
    QuizQuestion(
      questionText: 'सिंधु घाटी सभ्यता का प्रमुख बंदरगाह नगर कौन सा था?',
      optionA: 'हड़प्पा',
      optionB: 'मोहनजोदड़ो',
      optionC: 'लोथल',
      optionD: 'कालीबंगा',
      correctOptionIndex: 2,
      explanation: 'गुजरात में भोगवा नदी के तट पर स्थित लोथल सिंधु घाटी सभ्यता का प्रमुख गोदीवाड़ा (बंदरगाह) था।',
      subject: 'History',
    ),

    // ---------------- GEOGRAPHY ----------------
    QuizQuestion(
      questionText: 'Which river is famously known as the "Sorrow of Bihar"?',
      optionA: 'Damodar River',
      optionB: 'Kosi River',
      optionC: 'Son River',
      optionD: 'Gandak River',
      correctOptionIndex: 1,
      explanation: 'The Kosi river is called the "Sorrow of Bihar" due to its frequent shifting of course and devastating annual monsoon floods.',
      subject: 'Geography',
    ),
    QuizQuestion(
      questionText: 'What is the highest mountain peak in India (located within Indian territory)?',
      optionA: 'K2 (Godwin Austen)',
      optionB: 'Kangchenjunga',
      optionC: 'Nanda Devi',
      optionD: 'Kamet',
      correctOptionIndex: 1,
      explanation: 'Kangchenjunga (8,586 m) in Sikkim is the highest peak situated within undisputed Indian territory.',
      subject: 'Geography',
    ),
    QuizQuestion(
      questionText: 'Which state in India has the longest coastline?',
      optionA: 'Maharashtra',
      optionB: 'Tamil Nadu',
      optionC: 'Andhra Pradesh',
      optionD: 'Gujarat',
      correctOptionIndex: 3,
      explanation: 'Gujarat has the longest mainland coastline in India, extending over approximately 1,600 km.',
      subject: 'Geography',
    ),
    QuizQuestion(
      questionText: 'Which strait separates India and Sri Lanka?',
      optionA: 'Malacca Strait',
      optionB: 'Palk Strait',
      optionC: 'Sunda Strait',
      optionD: 'Hormuz Strait',
      correctOptionIndex: 1,
      explanation: 'The Palk Strait and Gulf of Mannar connect the Bay of Bengal with the Palk Bay, separating Tamil Nadu from Sri Lanka.',
      subject: 'Geography',
    ),
    QuizQuestion(
      questionText: 'भारत में सर्वाधिक वर्षा किस स्थान पर दर्ज की जाती है?',
      optionA: 'चेरापूंजी',
      optionB: 'मौसिनराम',
      optionC: 'लेह',
      optionD: 'शिलांग',
      correctOptionIndex: 1,
      explanation: 'मेघालय का मौसिनराम विश्व में सर्वाधिक औसत वार्षिक वर्षा प्राप्त करने वाला स्थान है।',
      subject: 'Geography',
    ),

    // ---------------- GENERAL SCIENCE ----------------
    QuizQuestion(
      questionText: 'What is the powerhouse of the eukaryotic cell?',
      optionA: 'Nucleus',
      optionB: 'Ribosome',
      optionC: 'Mitochondria',
      optionD: 'Endoplasmic Reticulum',
      correctOptionIndex: 2,
      explanation: 'Mitochondria generate most of the chemical energy needed to power the cell via adenosine triphosphate (ATP).',
      subject: 'Science',
    ),
    QuizQuestion(
      questionText: 'What is the chemical formula of common table salt?',
      optionA: 'NaHCO3',
      optionB: 'NaCl',
      optionC: 'KCl',
      optionD: 'Na2CO3',
      correctOptionIndex: 1,
      explanation: 'Sodium chloride (NaCl) is the ionic compound commonly known as table salt.',
      subject: 'Science',
    ),
    QuizQuestion(
      questionText: 'Which vitamin is synthesized in the human body with the help of sunlight?',
      optionA: 'Vitamin A',
      optionB: 'Vitamin B12',
      optionC: 'Vitamin C',
      optionD: 'Vitamin D',
      correctOptionIndex: 3,
      explanation: 'Vitamin D3 (cholecalciferol) is synthesized in the human skin through the action of ultraviolet B (UVB) rays from sunlight.',
      subject: 'Science',
    ),
    QuizQuestion(
      questionText: 'What is the SI unit of electric current?',
      optionA: 'Volt',
      optionB: 'Ohm',
      optionC: 'Ampere',
      optionD: 'Watt',
      correctOptionIndex: 2,
      explanation: 'The Ampere (symbol: A) is the base SI unit of electric current.',
      subject: 'Science',
    ),
    QuizQuestion(
      questionText: 'ध्वनि की चाल किस माध्यम में सबसे अधिक होती है?',
      optionA: 'निर्वात (Vacuum)',
      optionB: 'वायु (Air)',
      optionC: 'जल (Water)',
      optionD: 'ठोस/इस्पात (Steel/Solid)',
      correctOptionIndex: 3,
      explanation: 'ठोस पदार्थों में कण सबसे पास होते हैं, इसलिए ध्वनि का वेग ठोसों (जैसे इस्पात) में सर्वाधिक होता है (लगभग 5000 m/s)।',
      subject: 'Science',
    ),

    // ---------------- REASONING & APTITUDE ----------------
    QuizQuestion(
      questionText: 'If a clock shows 3:15, what is the angle between the hour hand and the minute hand?',
      optionA: '0 degrees',
      optionB: '7.5 degrees',
      optionC: '15 degrees',
      optionD: '22.5 degrees',
      correctOptionIndex: 1,
      explanation: 'At 3:15, minute hand is at 90 deg. The hour hand moves 0.5 deg/min, so at 15 min it has moved 15 * 0.5 = 7.5 degrees ahead.',
      subject: 'Reasoning',
    ),
    QuizQuestion(
      questionText: 'Complete the number series: 2, 6, 12, 20, 30, ?',
      optionA: '36',
      optionB: '40',
      optionC: '42',
      optionD: '44',
      correctOptionIndex: 2,
      explanation: 'Differences are +4, +6, +8, +10. Next difference is +12, so 30 + 12 = 42 (or n^2 + n formula).',
      subject: 'Reasoning',
    ),
    QuizQuestion(
      questionText: 'A man sells an article for ₹450 at a loss of 10%. At what price should he sell it to gain 20%?',
      optionA: '₹500',
      optionB: '₹550',
      optionC: '₹600',
      optionD: '₹620',
      correctOptionIndex: 2,
      explanation: 'CP = 450 / 0.9 = ₹500. For 20% profit, SP = 500 * 1.2 = ₹600.',
      subject: 'Math',
    ),
    QuizQuestion(
      questionText: 'If "CAT" is coded as 24 and "DOG" is coded as 26, what is the code for "PIG"?',
      optionA: '30',
      optionB: '32',
      optionC: '34',
      optionD: '36',
      correctOptionIndex: 1,
      explanation: 'Sum of alphabetical positions: P(16) + I(9) + G(7) = 32.',
      subject: 'Reasoning',
    ),

    // ---------------- HINDI GRAMMAR (VYAKARAN) ----------------
    QuizQuestion(
      questionText: '"सूर्योदय" शब्द का सही संधि विच्छेद क्या है?',
      optionA: 'सूर्य + दय',
      optionB: 'सूर्य + उदय',
      optionC: 'सूर्यो + दय',
      optionD: 'सूर्य + दयः',
      correctOptionIndex: 1,
      explanation: 'सूर्य + उदय = सूर्योदय (गुण स्वर संधि: अ/आ + उ/ऊ = ओ)।',
      subject: 'Hindi',
    ),
    QuizQuestion(
      questionText: '"यथाशक्ति" शब्द में कौन सा समास है?',
      optionA: 'तत्पुरुष समास',
      optionB: 'द्विगु समास',
      optionC: 'अव्ययीभाव समास',
      optionD: 'कर्मधारय समास',
      correctOptionIndex: 2,
      explanation: 'जिस समास का पहला पद अव्यय/उपसर्ग हो और प्रधान हो, वह अव्ययीभाव समास कहलाता है (यथाशक्ति = शक्ति के अनुसार)।',
      subject: 'Hindi',
    ),
    QuizQuestion(
      questionText: '"अंधे की लाठी" मुहावरे का सही अर्थ क्या है?',
      optionA: 'बहुत कमजोर होना',
      optionB: 'एकमात्र सहारा',
      optionC: 'रास्ता दिखाना',
      optionD: 'लाठी लेकर चलना',
      correctOptionIndex: 1,
      explanation: '"अंधे की लाठी" का प्रसिद्ध लोकोक्ति/मुहावरा अर्थ "एकमात्र सहारा" या असहाय का एकमात्र संबल होता है।',
      subject: 'Hindi',
    ),

    // ---------------- COMPUTER / IT ----------------
    QuizQuestion(
      questionText: 'In computer science, which data structure operates on a Last-In, First-Out (LIFO) principle?',
      optionA: 'Queue',
      optionB: 'Stack',
      optionC: 'Binary Tree',
      optionD: 'Linked List',
      correctOptionIndex: 1,
      explanation: 'A Stack follows the LIFO (Last In First Out) principle, where the element inserted last is removed first.',
      subject: 'Computer',
    ),
    QuizQuestion(
      questionText: 'Which protocol is used to securely transfer web pages over the internet?',
      optionA: 'HTTP',
      optionB: 'FTP',
      optionC: 'HTTPS',
      optionD: 'SMTP',
      correctOptionIndex: 2,
      explanation: 'HTTPS (HyperText Transfer Protocol Secure) encrypts communication using TLS/SSL to protect transmitted data.',
      subject: 'Computer',
    ),
    QuizQuestion(
      questionText: 'What does "SQL" stand for in relational database management systems?',
      optionA: 'Structured Question Language',
      optionB: 'Structured Query Language',
      optionC: 'Sequential Query Logic',
      optionD: 'System Query Language',
      correctOptionIndex: 1,
      explanation: 'SQL stands for Structured Query Language, the domain-specific standard language used in managing relational databases.',
      subject: 'Computer',
    ),
  ];

  /// Generates questions offline based on topic keywords and category
  static List<QuizQuestion> generateOfflineQuestions({
    required String topic,
    String? category,
    int count = 5,
    int? examId,
    int? categoryId,
  }) {
    final lowerTopic = topic.toLowerCase();
    final lowerCat = (category ?? '').toLowerCase();

    // Check matching subjects
    List<QuizQuestion> matched = [];

    if (lowerTopic.contains('polity') || lowerTopic.contains('constitution') || lowerTopic.contains('संविधान') || lowerCat.contains('polity')) {
      matched.addAll(_allCuratedQuestions.where((q) => q.subject == 'Polity'));
    }
    if (lowerTopic.contains('history') || lowerTopic.contains('इतिहास') || lowerTopic.contains('ancient') || lowerTopic.contains('modern') || lowerCat.contains('history')) {
      matched.addAll(_allCuratedQuestions.where((q) => q.subject == 'History'));
    }
    if (lowerTopic.contains('geo') || lowerTopic.contains('भूगोल') || lowerTopic.contains('river') || lowerCat.contains('geo')) {
      matched.addAll(_allCuratedQuestions.where((q) => q.subject == 'Geography'));
    }
    if (lowerTopic.contains('sci') || lowerTopic.contains('विज्ञान') || lowerTopic.contains('physics') || lowerTopic.contains('bio') || lowerTopic.contains('chem') || lowerCat.contains('sci')) {
      matched.addAll(_allCuratedQuestions.where((q) => q.subject == 'Science'));
    }
    if (lowerTopic.contains('math') || lowerTopic.contains('aptitude') || lowerTopic.contains('गणित') || lowerCat.contains('math')) {
      matched.addAll(_allCuratedQuestions.where((q) => q.subject == 'Math'));
    }
    if (lowerTopic.contains('reasoning') || lowerTopic.contains('तर्क') || lowerTopic.contains('logic') || lowerCat.contains('reasoning')) {
      matched.addAll(_allCuratedQuestions.where((q) => q.subject == 'Reasoning'));
    }
    if (lowerTopic.contains('hindi') || lowerTopic.contains('हिंदी') || lowerTopic.contains('व्याकरण') || lowerCat.contains('hindi')) {
      matched.addAll(_allCuratedQuestions.where((q) => q.subject == 'Hindi'));
    }
    if (lowerTopic.contains('computer') || lowerTopic.contains('it') || lowerTopic.contains('python') || lowerTopic.contains('dbms') || lowerCat.contains('computer')) {
      matched.addAll(_allCuratedQuestions.where((q) => q.subject == 'Computer'));
    }

    // If no specific match or not enough, use all curated questions
    if (matched.length < count) {
      final remaining = _allCuratedQuestions.where((q) => !matched.contains(q)).toList()..shuffle();
      matched.addAll(remaining);
    } else {
      matched.shuffle();
    }

    final selected = matched.take(count.clamp(1, 30)).toList();
    final effectiveSubject = (category != null && category.trim().isNotEmpty && category != 'General')
        ? category.trim()
        : (topic.trim().isNotEmpty ? topic.trim().split('\n').first : 'General');

    return selected.map((q) => QuizQuestion(
      questionText: q.questionText,
      optionA: q.optionA,
      optionB: q.optionB,
      optionC: q.optionC,
      optionD: q.optionD,
      correctOptionIndex: q.correctOptionIndex,
      explanation: q.explanation,
      subject: effectiveSubject,
      examId: examId,
      categoryId: categoryId,
    )).toList();
  }
}
