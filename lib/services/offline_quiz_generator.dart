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
    QuizQuestion(
      questionText: 'Under which Article of the Constitution does the President constitute the Finance Commission every 5 years?',
      optionA: 'Article 268',
      optionB: 'Article 280',
      optionC: 'Article 312',
      optionD: 'Article 324',
      correctOptionIndex: 1,
      explanation: 'Article 280 provides for the establishment of a Finance Commission by the President to recommend tax devolution between Center and States.',
      subject: 'Polity',
    ),
    QuizQuestion(
      questionText: 'Who decides whether a Bill introduced in Parliament is a "Money Bill" or not?',
      optionA: 'The President',
      optionB: 'The Prime Minister',
      optionC: 'The Speaker of Lok Sabha',
      optionD: 'The Finance Minister',
      correctOptionIndex: 2,
      explanation: 'Under Article 110(3), the decision of the Speaker of the Lok Sabha as to whether a bill is a Money Bill is final.',
      subject: 'Polity',
    ),
    QuizQuestion(
      questionText: 'Which Constitutional Amendment made Elementary Education a Fundamental Right under Article 21A?',
      optionA: '42nd Amendment',
      optionB: '44th Amendment',
      optionC: '73rd Amendment',
      optionD: '86th Amendment',
      correctOptionIndex: 3,
      explanation: 'The 86th Constitutional Amendment Act, 2002 inserted Article 21A, providing free and compulsory education to all children aged 6 to 14.',
      subject: 'Polity',
    ),
    QuizQuestion(
      questionText: 'In which year did the First Battle of Panipat take place, establishing the Mughal Empire in India?',
      optionA: '1526',
      optionB: '1556',
      optionC: '1761',
      optionD: '1539',
      correctOptionIndex: 0,
      explanation: 'Babur defeated Ibrahim Lodi in the First Battle of Panipat on 21 April 1526, laying the foundation of the Mughal Dynasty.',
      subject: 'History',
    ),
    QuizQuestion(
      questionText: 'Mahatma Gandhi launched his first Satyagraha in India in 1917 at which place?',
      optionA: 'Kheda',
      optionB: 'Ahmedabad',
      optionC: 'Champaran',
      optionD: 'Bardoli',
      correctOptionIndex: 2,
      explanation: 'Champaran Satyagraha in Bihar (1917) was Gandhi’s first civil disobedience movement against oppressive European indigo planters (Tinkathia system).',
      subject: 'History',
    ),
    QuizQuestion(
      questionText: 'Which is the longest river in Peninsular India, often called "Dakshin Ganga"?',
      optionA: 'Krishna',
      optionB: 'Godavari',
      optionC: 'Cauvery',
      optionD: 'Mahanadi',
      correctOptionIndex: 1,
      explanation: 'Godavari (1465 km) is the longest peninsular river and second longest in India, originating from Trimbakeshwar near Nashik.',
      subject: 'Geography',
    ),
    QuizQuestion(
      questionText: 'Through how many Indian states does the Tropic of Cancer (23.5° N) pass?',
      optionA: '6 states',
      optionB: '7 states',
      optionC: '8 states',
      optionD: '9 states',
      correctOptionIndex: 2,
      explanation: 'Tropic of Cancer passes through 8 states: Gujarat, Rajasthan, MP, Chhattisgarh, Jharkhand, West Bengal, Tripura, and Mizoram.',
      subject: 'Geography',
    ),
    QuizQuestion(
      questionText: 'Deficiency of Vitamin C leads to which of the following diseases?',
      optionA: 'Beriberi',
      optionB: 'Rickets',
      optionC: 'Night blindness',
      optionD: 'Scurvy',
      correctOptionIndex: 3,
      explanation: 'Vitamin C (Ascorbic acid) deficiency causes Scurvy, characterized by bleeding gums and delayed wound healing.',
      subject: 'Science',
    ),
    QuizQuestion(
      questionText: 'Which human blood group is known as the "Universal Donor"?',
      optionA: 'AB Positive (AB+)',
      optionB: 'O Negative (O-)',
      optionC: 'O Positive (O+)',
      optionD: 'A Negative (A-)',
      correctOptionIndex: 1,
      explanation: 'O negative red blood cells lack A, B, and Rh antigens, making O- safe to donate to recipients of any blood type.',
      subject: 'Science',
    ),
    QuizQuestion(
      questionText: 'What is the unit of power of a lens in optics?',
      optionA: 'Watt',
      optionB: 'Joule',
      optionC: 'Diopter',
      optionD: 'Candela',
      correctOptionIndex: 2,
      explanation: 'Power of a lens P = 1 / focal length (in meters), measured in Diopters (D).',
      subject: 'Science',
    ),
    QuizQuestion(
      questionText: 'If a train 150 meters long crosses a pole in 9 seconds, what is its speed in km/h?',
      optionA: '50 km/h',
      optionB: '60 km/h',
      optionC: '72 km/h',
      optionD: '54 km/h',
      correctOptionIndex: 1,
      explanation: 'Speed = Distance / Time = 150 / 9 m/s = (150/9) * (18/5) = 60 km/h.',
      subject: 'Math',
    ),
    QuizQuestion(
      questionText: 'What is the average of the first 20 natural numbers?',
      optionA: '10',
      optionB: '10.5',
      optionC: '11',
      optionD: '11.5',
      correctOptionIndex: 1,
      explanation: 'Average of first n natural numbers = (n + 1) / 2 = 21 / 2 = 10.5.',
      subject: 'Math',
    ),
    QuizQuestion(
      questionText: '\'सूर्योदय\' शब्द का सही संधि विच्छेद क्या होगा?',
      optionA: 'सूर्य + दय',
      optionB: 'सूर्य + उदय',
      optionC: 'सूर्यो + दय',
      optionD: 'सूर + उदय',
      correctOptionIndex: 1,
      explanation: 'सूर्य + उदय = सूर्योदय। इसमें अ/आ + उ = ओ (गुण स्वर संधि) का नियम लागू होता है।',
      subject: 'Hindi',
    ),
    QuizQuestion(
      questionText: '\'त्रिफला\' शब्द में कौन सा समास है?',
      optionA: 'तत्पुरुष समास',
      optionB: 'द्वंद्व समास',
      optionC: 'द्विगु समास',
      optionD: 'कर्मधारय समास',
      correctOptionIndex: 2,
      explanation: 'जिस समास का पहला पद संख्यावाचक विशेषण हो, वह द्विगु समास कहलाता है (त्रि = तीन फलों का समूह)।',
      subject: 'Hindi',
    ),
    QuizQuestion(
      questionText: '1 Gigabyte (GB) is equal to how many Megabytes (MB)?',
      optionA: '1000 MB',
      optionB: '1024 MB',
      optionC: '1048 MB',
      optionD: '512 MB',
      correctOptionIndex: 1,
      explanation: 'In binary computer storage, 1 GB = 1024 MB (2^10 MB).',
      subject: 'Computer',
    ),
    QuizQuestion(
      questionText: 'Which data structure works strictly on the FIFO (First In First Out) principle?',
      optionA: 'Stack',
      optionB: 'Queue',
      optionC: 'Tree',
      optionD: 'Graph',
      correctOptionIndex: 1,
      explanation: 'A Queue works on the First In First Out (FIFO) principle, where the first element inserted is the first one removed.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'What is the average time complexity of searching an element using Binary Search on a sorted array?',
      optionA: 'O(1)',
      optionB: 'O(n)',
      optionC: 'O(log n)',
      optionD: 'O(n log n)',
      correctOptionIndex: 2,
      explanation: 'Binary Search halves the search space in each step, giving an average and worst-case time complexity of O(log n).',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'In a Singly Linked List, what does each node store besides its data value?',
      optionA: 'Previous node address',
      optionB: 'Pointer/reference to the next node',
      optionC: 'Array index',
      optionD: 'Memory hash value',
      correctOptionIndex: 1,
      explanation: 'Each node in a singly linked list contains data and a pointer (or reference) to the next node in the sequence.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'Which tree traversal visits the nodes of a Binary Search Tree (BST) in strictly ascending sorted order?',
      optionA: 'Preorder (Root, Left, Right)',
      optionB: 'Inorder (Left, Root, Right)',
      optionC: 'Postorder (Left, Right, Root)',
      optionD: 'Level Order',
      correctOptionIndex: 1,
      explanation: 'Inorder traversal visits Left Subtree -> Root -> Right Subtree, which yields keys in ascending sorted order for any valid BST.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'Which data structure is primarily utilized by the system to implement function calls and recursion?',
      optionA: 'Call Stack',
      optionB: 'Circular Queue',
      optionC: 'Binary Heap',
      optionD: 'Hash Map',
      correctOptionIndex: 0,
      explanation: 'The system Call Stack stores activation records (return addresses, local variables, parameters) during recursive and nested function calls.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'What is the worst-case time complexity of the standard QuickSort algorithm (e.g. when the pivot is always the smallest or largest element)?',
      optionA: 'O(n)',
      optionB: 'O(n log n)',
      optionC: 'O(n^2)',
      optionD: 'O(log n)',
      correctOptionIndex: 2,
      explanation: 'QuickSort degrades to O(n^2) in the worst case when the chosen pivot consistently partitions the array into heavily unbalanced subarrays.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'What is the average and worst-case time complexity of MergeSort for an array of n elements?',
      optionA: 'O(n)',
      optionB: 'O(n log n)',
      optionC: 'O(n^2)',
      optionD: 'O(2^n)',
      correctOptionIndex: 1,
      explanation: 'MergeSort employs divide-and-conquer to guarantee O(n log n) time complexity in all cases (best, average, and worst).',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'Which data structure is fundamentally used to implement Breadth-First Search (BFS) on a graph or tree?',
      optionA: 'Stack',
      optionB: 'Queue',
      optionC: 'Priority Queue',
      optionD: 'Binary Search Tree',
      correctOptionIndex: 1,
      explanation: 'Breadth-First Search (BFS) processes nodes level-by-level using a FIFO Queue.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'What is the average time complexity for searching, insertion, and deletion in a well-designed Hash Table?',
      optionA: 'O(1)',
      optionB: 'O(log n)',
      optionC: 'O(n)',
      optionD: 'O(n log n)',
      correctOptionIndex: 0,
      explanation: 'Hash Tables offer average O(1) constant time complexity for lookup, insert, and delete using an effective hash function with minimal collisions.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'What is the primary difference between a Doubly Linked List and a Singly Linked List?',
      optionA: 'Doubly Linked List consumes less memory',
      optionB: 'Doubly Linked List allows bidirectional traversal via next and previous pointers',
      optionC: 'Doubly Linked List does not support dynamic sizing',
      optionD: 'Doubly Linked List cannot store integer values',
      correctOptionIndex: 1,
      explanation: 'Each node in a doubly linked list contains two pointers (next and previous), allowing traversal in both forward and backward directions.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'In a Min-Heap binary tree, what invariant holds true for every non-root node?',
      optionA: 'Parent node value is less than or equal to its children',
      optionB: 'Parent node value is greater than its children',
      optionC: 'Left child is always greater than right child',
      optionD: 'All leaf nodes must equal zero',
      correctOptionIndex: 0,
      explanation: 'In a Min-Heap, the root contains the smallest element, and the key of every parent node is less than or equal to the keys of its children.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'What is the time complexity to access an element by its index in a contiguous Array (e.g. arr[i])?',
      optionA: 'O(1)',
      optionB: 'O(n)',
      optionC: 'O(log n)',
      optionD: 'O(n^2)',
      correctOptionIndex: 0,
      explanation: 'Because array elements are stored in contiguous memory addresses, address calculation `base + i * size` executes in O(1) constant time.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'Which graph algorithm computes the shortest path from a single source vertex in a graph with non-negative edge weights?',
      optionA: 'Prim\'s Algorithm',
      optionB: 'Kruskal\'s Algorithm',
      optionC: 'Dijkstra\'s Algorithm',
      optionD: 'Floyd-Warshall Algorithm',
      correctOptionIndex: 2,
      explanation: 'Dijkstra\'s algorithm uses a greedy approach (often backed by a min-heap) to find the shortest path from a single source with non-negative weights.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'Which algorithmic paradigm solves complex problems by breaking them into overlapping subproblems and storing subproblem results (Memoization / Tabulation)?',
      optionA: 'Greedy Algorithm',
      optionB: 'Divide and Conquer',
      optionC: 'Dynamic Programming',
      optionD: 'Backtracking',
      correctOptionIndex: 2,
      explanation: 'Dynamic Programming solves problems with overlapping subproblems and optimal substructure by caching results to avoid redundant calculations.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'What is the maximum number of children a node can have in a Binary Tree?',
      optionA: '1',
      optionB: '2',
      optionC: '3',
      optionD: 'Any arbitrary number',
      correctOptionIndex: 1,
      explanation: 'By definition, each node in a Binary Tree can have at most two children, typically referred to as the left child and right child.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'Which data structure is optimal for evaluating postfix (Reverse Polish) mathematical expressions?',
      optionA: 'Stack',
      optionB: 'Queue',
      optionC: 'Graph',
      optionD: 'Hash Table',
      correctOptionIndex: 0,
      explanation: 'Postfix evaluation pushes operands onto a Stack and pops the top two operands whenever an operator is encountered.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'What is the worst-case time complexity of Linear Search in an unsorted array of size n?',
      optionA: 'O(1)',
      optionB: 'O(log n)',
      optionC: 'O(n)',
      optionD: 'O(n log n)',
      correctOptionIndex: 2,
      explanation: 'In the worst case (element at the very end or not present), Linear Search inspects all n elements, requiring O(n) time.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'Why is an AVL Tree or Red-Black Tree preferred over an ordinary Binary Search Tree (BST) for high-performance lookups?',
      optionA: 'They use less memory than standard BSTs',
      optionB: 'They self-balance to maintain O(log n) worst-case height and prevent degradation to a linear linked list',
      optionC: 'They only store positive integers',
      optionD: 'They do not require pointers',
      correctOptionIndex: 1,
      explanation: 'Self-balancing BSTs (AVL, Red-Black) perform tree rotations to keep tree height bounded to O(log n), preventing O(n) degenerate skew.',
      subject: 'Data Structures',
    ),
    QuizQuestion(
      questionText: 'What major problem of a simple linear array-based Queue does a Circular Queue solve?',
      optionA: 'False Overflow (memory waste when deleted slots in front cannot be reused)',
      optionB: 'Null pointer exceptions',
      optionC: 'Slow enqueue operations',
      optionD: 'Stack overflow errors',
      correctOptionIndex: 0,
      explanation: 'A Circular Queue wraps rear and front indices using modulo arithmetic, allowing newly freed slots at the beginning of the array to be reused.',
      subject: 'Data Structures',
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
    final isComputerOrDsa = lowerTopic.contains('computer') ||
        lowerTopic.contains('data structure') ||
        lowerTopic.contains('algorithm') ||
        lowerTopic.contains('dsa') ||
        lowerTopic.contains('stack') ||
        lowerTopic.contains('queue') ||
        lowerTopic.contains('tree') ||
        lowerTopic.contains('graph') ||
        lowerTopic.contains('array') ||
        lowerTopic.contains('linked list') ||
        lowerTopic.contains('sorting') ||
        lowerTopic.contains('programming') ||
        lowerTopic.contains('coding') ||
        lowerTopic.contains('software') ||
        lowerTopic.contains('it') ||
        lowerTopic.contains('python') ||
        lowerTopic.contains('java') ||
        lowerTopic.contains('c++') ||
        lowerTopic.contains('dbms') ||
        lowerTopic.contains('database') ||
        lowerCat.contains('computer') ||
        lowerCat.contains('data structure') ||
        lowerCat.contains('dsa') ||
        lowerCat.contains('it');

    if (isComputerOrDsa) {
      matched.addAll(_allCuratedQuestions.where((q) => q.subject == 'Computer' || q.subject == 'Data Structures'));
    }

    // Strict Subject Purity: If a subject was matched, ONLY cycle within that subject!
    // Under NO circumstance should questions from other categories (like Hindi, History) bleed in!
    if (matched.isNotEmpty) {
      matched.shuffle();
      final pool = List<QuizQuestion>.from(matched);
      while (matched.length < count) {
        matched.addAll(pool);
      }
    } else {
      // Only for generic queries where no category matched, and NEVER include language-specific Hindi grammar in an English query!
      final nonHindi = _allCuratedQuestions.where((q) => q.subject != 'Hindi').toList()..shuffle();
      matched.addAll(nonHindi);
      while (matched.length < count) {
        matched.addAll(nonHindi);
      }
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
