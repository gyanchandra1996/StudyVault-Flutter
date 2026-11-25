class HandbookData {
  // 1. MATHEMATICS - ARITHMETIC & ALGEBRA FULL FORMULA BOOK
  static const List<Map<String, String>> mathFormulas = [
    {
      'title': 'Number System & Divisibility Rules',
      'desc': '• Divisibility by 2: Last digit even (0,2,4,6,8)\n'
          '• Divisibility by 3: Sum of digits divisible by 3\n'
          '• Divisibility by 4: Last 2 digits divisible by 4\n'
          '• Divisibility by 5: Last digit 0 or 5\n'
          '• Divisibility by 6: Divisible by both 2 and 3\n'
          '• Divisibility by 8: Last 3 digits divisible by 8\n'
          '• Divisibility by 9: Sum of digits divisible by 9\n'
          '• Divisibility by 11: (Sum of odd-place digits - Sum of even-place digits) is 0 or multiple of 11\n'
          '• Unit Digit Cyclicity: 2, 3, 7, 8 have cyclicity 4; 4, 9 have cyclicity 2; 0, 1, 5, 6 have cyclicity 1.\n'
          '• Dividend = (Divisor × Quotient) + Remainder',
    },
    {
      'title': 'Percentage & Fraction Conversion Table',
      'desc': '• 1/2 = 50% | 1/3 = 33.33% | 1/4 = 25%\n'
          '• 1/5 = 20% | 1/6 = 16.67% | 1/7 = 14.28%\n'
          '• 1/8 = 12.5% | 1/9 = 11.11% | 1/10 = 10%\n'
          '• 1/11 = 9.09% | 1/12 = 8.33% | 1/15 = 6.67% | 1/16 = 6.25%\n'
          '• % Change = [(Final - Initial) / Initial] × 100\n'
          '• Successive % Change: Net% = a + b + (a × b / 100)\n'
          '• If price increases by r%, consumption reduction needed = [r / (100 + r)] × 100%',
    },
    {
      'title': 'Profit, Loss, Discount & False Weight',
      'desc': '• Profit = SP - CP | Loss = CP - SP\n'
          '• Profit% = (Profit / CP) × 100 | Loss% = (Loss / CP) × 100\n'
          '• SP = CP × [(100 ± P/L%) / 100]\n'
          '• CP = [SP × 100] / (100 ± P/L%)\n'
          '• Discount = MP - SP | Discount% = (Discount / MP) × 100\n'
          '• Relation: MP / CP = (100 + Profit%) / (100 - Discount%)\n'
          '• Successive Discounts (d1, d2): Net% = d1 + d2 - (d1 × d2 / 100)\n'
          '• Dishonest Dealer (False Weight): Gain% = [Error / (True Value - Error)] × 100',
    },
    {
      'title': 'Simple & Compound Interest Master Formulas',
      'desc': '• Simple Interest: SI = (P × R × T) / 100\n'
          '• Amount: A = P + SI = P × [1 + (R × T / 100)]\n'
          '• Compound Interest: A = P × (1 + R/100)^T | CI = A - P\n'
          '• Half-yearly: Rate = R/2, Time = 2T | Quarterly: Rate = R/4, Time = 4T\n'
          '• 2-Year Difference (CI - SI): D₂ = P × (R / 100)²\n'
          '• 3-Year Difference (CI - SI): D₃ = P × (R / 100)² × [3 + (R / 100)]\n'
          '• Rule of 72: Doubling time in years ≈ 72 / R%',
    },
    {
      'title': 'Ratio, Proportion & Mixture / Alligation',
      'desc': '• If a : b = c : d, then a × d = b × c (Product of extremes = Product of means)\n'
          '• Mean Proportional of a and b = √(a × b)\n'
          '• Third Proportional to a and b = b² / a\n'
          '• Fourth Proportional to a, b, c = (b × c) / a\n'
          '• Alligation Rule: (Cheaper Qty / Dearer Qty) = (Dearer Price - Mean Price) / (Mean Price - Cheaper Price)\n'
          '• Repeated Dilution: If y litres taken from x litres pure liquid n times, remaining pure = x × (1 - y/x)ⁿ',
    },
    {
      'title': 'Time, Speed & Distance (Trains, Boats & Streams)',
      'desc': '• Speed = Distance / Time | Distance = Speed × Time\n'
          '• km/h to m/s: Multiply by 5/18 | m/s to km/h: Multiply by 18/5\n'
          '• Average Speed (Equal distance covered at S1 and S2) = (2 × S1 × S2) / (S1 + S2)\n'
          '• Relative Speed: Same direction = |S1 - S2| | Opposite direction = S1 + S2\n'
          '• Train crossing pole/man: Distance = Train Length\n'
          '• Train crossing bridge/platform: Distance = Train Length + Platform Length\n'
          '• Boats & Streams: Downstream speed (D) = u + v | Upstream speed (U) = u - v\n'
          '• Speed of boat in still water = (D + U) / 2 | Speed of stream = (D - U) / 2',
    },
    {
      'title': 'Time & Work, Pipes & Cisterns',
      'desc': '• Work = Efficiency × Time\n'
          '• If A takes x days and B takes y days: Together = (x × y) / (x + y) days\n'
          '• If A takes x days, B takes y days, C takes z days: Together = (xyz) / (xy + yz + zx)\n'
          '• MDH Formula: (M₁ × D₁ × H₁) / W₁ = (M₂ × D₂ × H₂) / W₂\n'
          '• Pipes: Inlet pipe (+), Outlet/Drain pipe (-)\n'
          '• Net rate = (1/A) + (1/B) - (1/Leak)',
    },
    {
      'title': 'Averages & Sequences',
      'desc': '• Average = Sum of observations / Number of observations\n'
          '• Weighted Average = (w₁x₁ + w₂x₂ + ...) / (w₁ + w₂ + ...)\n'
          '• Average of first n natural numbers = (n + 1) / 2\n'
          '• Sum of first n natural numbers = n(n + 1) / 2\n'
          '• Sum of squares of first n natural numbers = n(n + 1)(2n + 1) / 6\n'
          '• Sum of cubes of first n natural numbers = [n(n + 1) / 2]²\n'
          '• Average of consecutive numbers in AP = (First term + Last term) / 2',
    },
    {
      'title': 'Algebraic Identities (All Core Expansions)',
      'desc': '• (a + b)² = a² + 2ab + b²\n'
          '• (a - b)² = a² - 2ab + b²\n'
          '• a² - b² = (a + b)(a - b)\n'
          '• (a + b)² + (a - b)² = 2(a² + b²)\n'
          '• (a + b)² - (a - b)² = 4ab\n'
          '• (a + b + c)² = a² + b² + c² + 2(ab + bc + ca)\n'
          '• (a + b)³ = a³ + b³ + 3ab(a + b)\n'
          '• (a - b)³ = a³ - b³ - 3ab(a - b)\n'
          '• a³ + b³ = (a + b)(a² - ab + b²)\n'
          '• a³ - b³ = (a - b)(a² + ab + b²)\n'
          '• a³ + b³ + c³ - 3abc = (a + b + c)(a² + b² + c² - ab - bc - ca)\n'
          '• Conditional: If a + b + c = 0, then a³ + b³ + c³ = 3abc\n'
          '• a² + b² + c² - ab - bc - ca = ½[(a - b)² + (b - c)² + (c - a)²]',
    },
    {
      'title': 'Quadratic Equations & Roots',
      'desc': '• Standard form: ax² + bx + c = 0 (a ≠ 0)\n'
          '• Discriminant: D = b² - 4ac\n'
          '  - D > 0: Roots are Real and Distinct\n'
          '  - D = 0: Roots are Real and Equal (x = -b / 2a)\n'
          '  - D < 0: Roots are Imaginary / Complex\n'
          '• Roots formula: x = [-b ± √(b² - 4ac)] / (2a)\n'
          '• Sum of roots (α + β) = -b / a\n'
          '• Product of roots (α × β) = c / a\n'
          '• Equation from roots: x² - (α + β)x + (αβ) = 0',
    },
    {
      'title': 'Arithmetic (AP) & Geometric (GP) Progressions',
      'desc': '• AP: a, a+d, a+2d, ... (Common difference = d)\n'
          '  - n-th term: Tₙ = a + (n - 1)d\n'
          '  - Sum of n terms: Sₙ = (n / 2)[2a + (n - 1)d] = (n / 2)(a + l)\n'
          '  - Arithmetic Mean: AM = (a + b) / 2\n'
          '• GP: a, ar, ar², ... (Common ratio = r)\n'
          '  - n-th term: Tₙ = a × rⁿ⁻¹\n'
          '  - Sum of n terms: Sₙ = a(rⁿ - 1) / (r - 1) for r > 1\n'
          '  - Sum to Infinity (|r| < 1): S∞ = a / (1 - r)\n'
          '  - Geometric Mean: GM = √(ab)\n'
          '• Inequality: AM ≥ GM ≥ HM',
    },
    {
      'title': 'Indices, Surds & Logarithms Rules',
      'desc': '• aᵐ × aⁿ = aᵐ⁺ⁿ | aᵐ / aⁿ = aᵐ⁻ⁿ | (aᵐ)ⁿ = aᵐⁿ\n'
          '• a⁰ = 1 | a⁻ⁿ = 1 / aⁿ | (ab)ⁿ = aⁿ × bⁿ\n'
          '• Surd: ⁿ√a = a^(1/n)\n'
          '• log(xy) = log x + log y\n'
          '• log(x / y) = log x - log y\n'
          '• log(xᵏ) = k × log x\n'
          '• Base change: log_b(a) = log_c(a) / log_c(b)\n'
          '• log_a(a) = 1 | log_a(1) = 0',
    },
    {
      'title': 'Mensuration 2D & 3D Cheat Sheet',
      'desc': '• Triangle Area = ½ × Base × Height = √[s(s - a)(s - b)(s - c)] where s = (a+b+c)/2\n'
          '• Equilateral Triangle Area = (√3 / 4) × a² | Height = (√3 / 2) × a\n'
          '• Circle: Area = πr² | Circumference = 2πr | Sector = (θ / 360) × πr²\n'
          '• Trapezium Area = ½ × (Sum of parallel sides) × Distance between them\n'
          '• Rhombus Area = ½ × d₁ × d₂ | Side = ½√(d₁² + d₂²)\n'
          '• Cylinder: Volume = πr²h | CSA = 2πrh | TSA = 2πr(r + h)\n'
          '• Cone: Volume = ⅓πr²h | Slant height l = √(r² + h²) | CSA = πrl | TSA = πr(l + r)\n'
          '• Sphere: Volume = (4/3)πr³ | Surface Area = 4πr²\n'
          '• Hemisphere: Volume = (2/3)πr³ | CSA = 2πr² | TSA = 3πr²',
    },
  ];

  // 2. HINDI GRAMMAR (हिन्दी व्याकरण FULL SYLLABUS)
  static const List<Map<String, String>> hindiGrammar = [
    {
      'title': 'वर्ण विचार एवं उच्चारण स्थान (Phonology)',
      'desc': '• स्वर (11): अ, आ, इ, ई, उ, ऊ, ऋ, ए, ऐ, ओ, औ\n'
          '  - ह्रस्व स्वर (मूल स्वर - 4): अ, इ, उ, ऋ\n'
          '  - दीर्घ स्वर (7): आ, ई, ऊ, ए, ऐ, ओ, औ\n'
          '• अयोगवाह (2): अं (अनुस्वार), अः (विसर्ग)\n'
          '• व्यंजन (33): स्पर्श (25: क-वर्ग से प-वर्ग तक), अंतःस्थ (4: य, र, ल, व), ऊष्म (4: श, ष, स, ह)\n'
          '• संयुक्त व्यंजन (4): क्ष (क्+ष्), त्र (त्+र्), ज्ञ (ज्+ञ्), श्र (श्+र्)\n'
          '• उच्चारण स्थान:\n'
          '  - कंठ्य: अ, आ, क-वर्ग, ह, विसर्ग\n'
          '  - तालव्य: इ, ई, च-वर्ग, य, श\n'
          '  - मूर्धन्य: ऋ, ट-वर्ग, र, ष\n'
          '  - दंत्य: त-वर्ग, ल, स\n'
          '  - ओष्ठ्य: उ, ऊ, प-वर्ग\n'
          '• प्राणत्व के आधार पर:\n'
          '  - अल्पप्राण: प्रत्येक वर्ग का 1, 3, 5 वां वर्ण + अंतःस्थ (य, र, ल, व)\n'
          '  - महाप्राण: प्रत्येक वर्ग का 2, 4 वां वर्ण + ऊष्म (श, ष, स, ह)\n'
          '• घोषत्व के आधार पर:\n'
          '  - अघोष: प्रत्येक वर्ग का 1, 2 वां वर्ण + श, ष, स\n'
          '  - सघोष/घोष: प्रत्येक वर्ग का 3, 4, 5 वां वर्ण + सभी स्वर + य, र, ल, व, ह',
    },
    {
      'title': 'संधि एवं उसके नियम (स्वर, व्यंजन, विसर्ग)',
      'desc': '• संधि के 3 प्रकार: स्वर संधि, व्यंजन संधि, विसर्ग संधि\n'
          '1. स्वर संधि (5 भेद):\n'
          '  - दीर्घ संधि: अ/आ + अ/आ = आ (विद्या + आलय = विद्यालय, हिम + अंशु = हिमांशु)\n'
          '  - गुण संधि: अ/आ + इ/ई = ए, अ/आ + उ/ऊ = ओ, अ/आ + ऋ = अर् (नर + इंद्र = नरेंद्र, सूर्य + उदय = सूर्योदय, महा + ऋषि = महर्षि)\n'
          '  - वृद्धि संधि: अ/आ + ए/ऐ = ऐ, अ/आ + ओ/औ = औ (एक + एक = एकैक, महा + ओज = महौज)\n'
          '  - यण संधि: इ/ई + असमान स्वर = य्, उ/ऊ + असमान = व्, ऋ + असमान = र् (यदि + अपि = यद्यपि, अनु + अय = अन्वय, पितृ + आज्ञा = पित्राज्ञा)\n'
          '  - अयादि संधि: ए + स्वर = अय्, ऐ + स्वर = आय्, ओ + स्वर = अव्, औ + स्वर = आव् (ने + अन = नयन, नै + अक = नायक, पो + अन = पवन, पौ + अक = पावक)\n'
          '2. व्यंजन संधि:\n'
          '  - वर्ग के प्रथम वर्ण का तीसरे में परिवर्तन: दिक् + गज = दिग्गज, वाक् + ईश = वागीश, अच् + अंत = अजंत\n'
          '  - प्रथम वर्ण का पंचम वर्ण में: वाक् + मय = वाङ्मय, उत् + नति = उन्नति\n'
          '  - त् संबंधी नियम: सत् + जन = सज्जन, उत् + चारण = उच्चारण, उत् + लास = उल्लास\n'
          '3. विसर्ग संधि:\n'
          '  - विसर्ग का \'ओ\' होना: मनः + हर = मनोहर, सरः + वर = सरोवर\n'
          '  - विसर्ग का \'र्\' होना: निः + धन = निर्धन, दुः + बल = दुर्बल\n'
          '  - विसर्ग का \'श्, ष्, स्\' होना: नमः + ते = नमस्ते, निः + छल = निश्छल, धनुः + टंकार = धनुष्टंकार',
    },
    {
      'title': 'समास एवं उसके 6 भेद (Compound Words)',
      'desc': '• समास का अर्थ: संक्षेपीकरण (दो या अधिक शब्दों का मेल)\n'
          '1. अव्ययीभाव समास: प्रथम पद प्रधान एवं अव्यय/उपसर्ग होता है।\n'
          '   उदाहरण: यथाशक्ति (शक्ति के अनुसार), प्रतिदिन (दिन-दिन), आजन्म, भरपेट, रातों-रात\n'
          '2. तत्पुरुष समास: उत्तरपद प्रधान, दोनों पदों के बीच कारक चिन्ह का लोप।\n'
          '   - कर्म तत्पुरुष: गगनचुंबी (गगन को चूमने वाला)\n'
          '   - करण तत्पुरुष: रेखांकित (रेखा से अंकित), जन्मांध\n'
          '   - संप्रदान तत्पुरुष: रसोईघर (रसोई के लिए घर), देशभक्ति\n'
          '   - अपादान तत्पुरुष: ऋणमुक्त (ऋण से मुक्त), पथभ्रष्ट\n'
          '   - संबंध तत्पुरुष: राजपुत्र (राजा का पुत्र), गंगाजल\n'
          '   - अधिकरण तत्पुरुष: आपबीती (आप पर बीती), पुरुषोत्तम\n'
          '3. कर्मधारय समास: विशेषण-विशेष्य या उपमान-उपमेय का संबंध।\n'
          '   उदाहरण: नीलकमल (नीला है जो कमल), चंद्रमुख (चंद्रमा के समान मुख), चरणकमल, पीतांबर\n'
          '4. द्विगु समास: पहला पद संख्यावाचक विशेषण, समूह का बोध।\n'
          '   उदाहरण: त्रिफला (तीन फलों का समाहार), चौराहा (चार राहों का समूह), पंचवटी, नवरत्न\n'
          '5. द्वंद्व समास: दोनों पद प्रधान, बीच में \'और, या, अथवा, एवं\' का लोप।\n'
          '   उदाहरण: माता-पिता, दिन-रात, सुख-दुख, राधा-कृष्ण, दाल-रोटी\n'
          '6. बहुव्रीहि समास: दोनों पद मिलकर किसी तीसरे विशेष अर्थ को प्रकट करते हैं।\n'
          '   उदाहरण: दशानन (दस हैं आनन जिसके अर्थात् रावण), लंबोदर (गणेश), नीलकंठ (शिव), चक्रपाणि (विष्णु)',
    },
    {
      'title': 'संज्ञा, सर्वनाम, विशेषण एवं क्रिया (Parts of Speech)',
      'desc': '• संज्ञा (5 भेद):\n'
          '  1. व्यक्तिवाचक: राम, हिमालय, गंगा, भारत\n'
          '  2. जातिवाचक: नदी, पर्वत, मनुष्य, लड़का\n'
          '  3. भाववाचक: मिठास, बचपन, सुंदरता, ईमानदारी\n'
          '  4. समूहवाचक: कक्षा, सेना, भीड़, सभा\n'
          '  5. द्रव्यवाचक: सोना, पानी, दूध, तेल, लोहा\n'
          '• सर्वनाम (6 भेद): सर्वनाम के 11 मूल शब्द (मैं, तू, आप, यह, वह, जो, सो, कोई, कुछ, कौन, क्या)\n'
          '  1. पुरुषवाचक (उत्तम- मैं/हम; मध्यम- तू/तुम/आप; अन्य- वह/वे)\n'
          '  2. निजवाचक (स्वयं, आप, खुद)\n'
          '  3. निश्चयवाचक (यह, वह)\n'
          '  4. अनिश्चयवाचक (कोई, कुछ)\n'
          '  5. संबंधवाचक (जो, सो, जैसा, वैसा)\n'
          '  6. प्रश्नवाचक (कौन, क्या)\n'
          '• विशेषण (4 भेद):\n'
          '  1. गुणवाचक: अच्छा, बुरा, लाल, चौड़ा, ईमानदार\n'
          '  2. संख्यावाचक: निश्चित (दस, पहला, दोनों) व अनिश्चित (कुछ, कई)\n'
          '  3. परिमाणवाचक: माप-तौल (दो किलो दूध, थोड़ा पानी)\n'
          '  4. सार्वनामिक विशेषण: संज्ञा से पूर्व सर्वनाम (वह लड़का चतुर है)\n'
          '  - प्रविशेषण: विशेषण की भी विशेषता बताने वाले शब्द (वह बहुत चतुर है)\n'
          '• क्रिया:\n'
          '  - अकर्मक: कर्म रहित (राम हंसता है, पक्षी उड़ते हैं)\n'
          '  - सकर्मक: कर्म सहित (राम पत्र लिखता है, मोहन आम खाता है)\n'
          '  - प्रेरणार्थक क्रिया: कर्ता स्वयं कार्य न करके दूसरे से करवाता है (लिखवाना, पढ़वाना)',
    },
    {
      'title': 'कारक एवं उनकी 8 विभक्तियाँ (Case Markers)',
      'desc': '1. कर्ता कारक - ने (शून्य विभक्ति भी) | कार्य करने वाला\n'
          '2. कर्म कारक - को | जिस पर क्रिया का फल पड़े (राम ने रावण को मारा)\n'
          '3. करण कारक - से, के द्वारा | साधन/माध्यम (कलम से लिखा)\n'
          '4. संप्रदान कारक - को, के लिए | जिसके लिए कुछ दिया जाए (गरीबों को कंबल दो)\n'
          '5. अपादान कारक - से (अलग होने का भाव, तुलना, भय, लज्जा) | (पेड़ से पत्ता गिरा, मोहन सांप से डरता है)\n'
          '6. संबंध कारक - का, की, के, रा, री, रे | अन्य पदों से संबंध (राजा का महल)\n'
          '7. अधिकरण कारक - में, पर, पे | क्रिया का आधार/स्थान (मेज पर पुस्तक है, कमरे में छात्र हैं)\n'
          '8. संबोधन कारक - हे, अरे, ओ, अजी | पुकारने या सावधान करने हेतु',
    },
    {
      'title': 'उपसर्ग एवं प्रत्यय (Affixes)',
      'desc': '• उपसर्ग: शब्दांश जो शब्द के आदि (प्रारंभ) में जुड़कर अर्थ बदल देते हैं।\n'
          '  - संस्कृत उपसर्ग (22): प्र (प्रख्यात), परा (पराजय), अप (अपमान), सम् (सम्मान), अनु (अनुशासन), वि (विकास), अति (अत्यधिक), सु (सुगम), उत् (उन्नति)\n'
          '  - हिन्दी उपसर्ग: अन (अनपढ़), अध (अधपका), कु (कुपात्र), भर (भरपेट)\n'
          '  - उर्दू/फारसी उपसर्ग: बद (बदनाम), बे (बेईमान), ला (लापरवाह), खुश (खुशबू)\n'
          '• प्रत्यय: शब्दांश जो शब्द के अंत में जुड़कर नए शब्द बनाते हैं।\n'
          '  1. कृत् प्रत्यय: धातुओं (क्रिया के मूल रूप) के अंत में लगते हैं। इनसे बने शब्द \'कृदंत\' कहलाते हैं। (जैसे: लिख् + आवट = लिखावट, तैर् + आक = तैराक)\n'
          '  2. तद्धित प्रत्यय: संज्ञा, सर्वनाम या विशेषण के अंत में लगते हैं। (जैसे: मानव + ता = मानवता, मीठा + आस = मिठास, पंडित + आइन = पंडिताइन)',
    },
    {
      'title': 'काल, वाच्य, लिंग एवं वचन',
      'desc': '• काल (3 भेद):\n'
          '  1. भूतकाल (6 उपभेद): सामान्य (राम गया), आसन्न (राम आया है), पूर्ण (राम आया था), अपूर्ण (राम आ रहा था), संदिग्ध (राम आया होगा), हेतुहेतुमद्भूत (यदि वर्षा होती तो फसल अच्छी होती)\n'
          '  2. वर्तमानकाल (5 उपभेद): सामान्य, तत्कालिक/अपूर्ण, पूर्ण, संदिग्ध, संभाव्य\n'
          '  3. भविष्यतकाल (3 उपभेद): सामान्य, संभाव्य, हेतुहेतुमद्भविष्य\n'
          '• वाच्य (3 भेद):\n'
          '  1. कर्तृवाच्य: कर्ता की प्रधानता (रमेश पुस्तक पढ़ता है)\n'
          '  2. कर्मवाच्य: कर्म की प्रधानता (रमेश द्वारा पुस्तक पढ़ी जाती है)\n'
          '  3. भाववाच्य: भाव/क्रिया की प्रधानता, प्रायः असमर्थता (मुझसे अब चला नहीं जाता)\n'
          '• लिंग: पुल्लिंग एवं स्त्रीलिंग\n'
          '• वचन: एकवचन एवं बहुवचन (सदा बहुवचन रहने वाले शब्द: प्राण, दर्शन, आंसू, हस्ताक्षर, होश, बाल; सदा एकवचन: पानी, दूध, सोना, जनता, वर्षा, सत्य)',
    },
    {
      'title': 'रस, छंद एवं अलंकार (Poetic Devices)',
      'desc': '• रस (9 मुख्य रस एवं उनके स्थायी भाव):\n'
          '  1. शृंगार रस: रति (प्रेम) | 2. हास्य रस: हास\n'
          '  3. करुण रस: शोक | 4. रौद्र रस: क्रोध\n'
          '  5. वीर रस: उत्साह | 6. भयानक रस: भय\n'
          '  7. बीभत्स रस: जुगुप्सा (घृणा) | 8. अद्भुत रस: विस्मय (आश्चर्य)\n'
          '  9. शांत रस: निर्वेद (शम) | 10. वात्सल्य (स्नेह) | 11. भक्ति रस (ईश्वर अनुराग)\n'
          '• अलंकार:\n'
          '  - शब्दालंकार:\n'
          '    * अनुप्रास: वर्णों की बार-बार आवृत्ति (चारु चंद्र की चंचल किरणें)\n'
          '    * यमक: एक ही शब्द दो या अधिक बार आए और हर बार अर्थ भिन्न हो (कनक कनक ते सौ गुनी - एक कनक = धतूरा, दूसरा = सोना)\n'
          '    * श्लेष: शब्द एक बार आए लेकिन अर्थ अनेक हों (रहिमन पानी राखिए, बिन पानी सब सून)\n'
          '  - अर्थालंकार:\n'
          '    * उपमा: सा, सी, सम, सरिस द्वारा समानता (पीपर पात सरिस मन डोला)\n'
          '    * रूपक: उपमेय पर उपमान का अभेद आरोप (चरन कमल बंदौ हरि राई)\n'
          '    * उत्प्रेक्षा: मानो, जानो, मनहु, जनहु द्वारा संभावना (सोहत ओढ़े पीत पट... मानहु नीलमणि शैल पर...)\n'
          '    * अतिशयोक्ति: अत्यधिक बढ़ा-चढ़ाकर वर्णन (हनुमान की पूंछ में लगन न पाई आग, लंका सिगरी जल गई गए निशाचर भाग)',
    },
    {
      'title': 'महत्वपूर्ण मुहावरे, लोकोक्तियाँ व शब्द संपदा',
      'desc': '• मुहावरे:\n'
          '  - अंगूठा दिखाना: साफ मना करना\n'
          '  - आंखें खुलना: वास्तविकता का बोध होना\n'
          '  - ईंट का जवाब पत्थर से देना: करारा उत्तर देना\n'
          '  - कलेजे पर सांप लोटना: अत्यधिक ईर्ष्या होना\n'
          '  - गागर में सागर भरना: थोड़े शब्दों में बहुत कुछ कह देना\n'
          '  - नौ दो ग्यारह होना: रफूचक्कर हो जाना (भाग जाना)\n'
          '• तत्सम - तद्भव:\n'
          '  - अग्नि : आग | अक्षि : आंख | दुग्ध : दूध | घृत : घी\n'
          '  - मयूर : मोर | कर्ण : कान | दंत : दांत | कूप : कुआं\n'
          '  - चंद्र : चांद | सूर्य : सूरज | रात्रि : रात | अंधकार : अंधेरा\n'
          '• अनेक शब्दों के लिए एक शब्द:\n'
          '  - जो सब कुछ जानता हो: सर्वज्ञ | जो कम जानता हो: अल्पज्ञ\n'
          '  - जिसे जीता न जा सके: अजेय | जिसका कोई शत्रु न जन्मा हो: अजातशत्रु\n'
          '  - जो कभी बूढ़ा न हो: अजर | जो कभी न मरे: अमर',
    },
  ];

  // 3. ENGLISH GRAMMAR FULL SYLLABUS
  static const List<Map<String, String>> englishGrammar = [
    {
      'title': 'Parts of Speech Master Sheet',
      'desc': '• Noun: Name of person, place, thing, or abstract idea.\n'
          '  - Proper (Delhi), Common (city), Collective (flock, jury, herd), Abstract (honesty, courage), Material (gold, iron).\n'
          '• Pronoun: Replaces a noun.\n'
          '  - Subject: I, you, he, she, it, we, they.\n'
          '  - Object: me, you, him, her, it, us, them.\n'
          '  - Relative: who (subject person), whom (object person), whose (possession), which (things), that (both).\n'
          '• Adjective: Modifies noun/pronoun. Order: Opinion -> Size -> Age -> Shape -> Color -> Origin -> Material -> Purpose.\n'
          '• Verb: Action or state. Transitive (requires object) vs Intransitive (no object).\n'
          '• Adverb: Modifies verb, adjective, or another adverb (Manner, Place, Time, Frequency, Degree).\n'
          '• Preposition: Relates noun/pronoun to another word in sentence.\n'
          '• Conjunction: Connects words/clauses (Coordinating: FANBOYS; Subordinating: because, although, since).\n'
          '• Interjection: Expresses strong emotion (Wow!, Alas!, Bravo!).',
    },
    {
      'title': '12 Tenses Blueprint & Signal Words',
      'desc': '• Present Simple: S + V1 (s/es) | Daily habits, universal facts. (always, usually, daily)\n'
          '• Present Continuous: S + is/am/are + V-ing | Ongoing actions. (now, right now, at present)\n'
          '• Present Perfect: S + has/have + V3 | Completed with current relevance. (already, yet, recently, just)\n'
          '• Present Perfect Cont.: S + has/have + been + V-ing | Started past, continuing now. (since 2020, for 3 hours)\n'
          '• Past Simple: S + V2 | Finished event in past. (yesterday, ago, in 1947, last night)\n'
          '• Past Continuous: S + was/were + V-ing | Action in progress at past point. (while, when)\n'
          '• Past Perfect: S + had + V3 | Past of the past (earlier of two past events). (before, after)\n'
          '  - E.g.: "The patient had died before the doctor arrived."\n'
          '• Past Perfect Cont.: S + had + been + V-ing | Duration in past before another action.\n'
          '• Future Simple: S + will/shall + V1 | Prediction, spontaneous decision. (tomorrow, next year)\n'
          '• Future Continuous: S + will be + V-ing | Action in progress at future point.\n'
          '• Future Perfect: S + will have + V3 | Action completed by future deadline. (by 5 PM, by next year)\n'
          '• Future Perfect Cont.: S + will have been + V-ing | Duration leading up to future point.',
    },
    {
      'title': 'Top 15 Golden Rules of Subject-Verb Agreement',
      'desc': '1. Two singular subjects joined by "and" take a plural verb. (Gold and silver are precious metals.)\n'
          '2. If joined by "as well as", "along with", "together with", "with", "in addition to", the verb agrees with the FIRST subject. (The teacher, along with his students, is present.)\n'
          '3. If joined by "Either...or", "Neither...nor", "Not only...but also", the verb agrees with the NEAREST subject. (Neither Rahul nor his friends are coming.)\n'
          '4. "Each", "Every", "Everyone", "Someone", "Anybody", "Neither of", "Either of" take a SINGULAR verb. (Each of the boys was punished.)\n'
          '5. "A number of" takes a PLURAL verb; "The number of" takes a SINGULAR verb. (A number of students were absent; The number of students is fifty.)\n'
          '6. Plural in form but singular in meaning (Mathematics, Physics, News, Politics) take a SINGULAR verb.\n'
          '7. Quantities of distance, time, money considered as a single unit take a SINGULAR verb. (Fifty miles is a long distance; Ten thousand rupees is enough.)\n'
          '8. "More than one" takes a singular noun and singular verb. (More than one person was injured.)\n'
          '9. If "One of the + plural noun" is followed by a relative pronoun (who/that), the verb is PLURAL. (He is one of the men who have worked hard.)',
    },
    {
      'title': 'Active and Passive Voice Rules',
      'desc': '• Rule: Object becomes Subject + Suitable form of "be" + V3 (Past Participle) + by + Subject.\n'
          '• Tense Transformations:\n'
          '  - Present Simple: is/am/are + V3 (Writes -> is written)\n'
          '  - Past Simple: was/were + V3 (Wrote -> was written)\n'
          '  - Present/Past Cont.: is/was + being + V3 (Is writing -> is being written)\n'
          '  - Perfect Tenses: has/have/had + been + V3 (Has written -> has been written)\n'
          '  - Modals: modal + be + V3 (Can solve -> can be solved; Must do -> must be done)\n'
          '• Note: Present Perfect Continuous, Past Perfect Continuous, Future Continuous, and Future Perfect Continuous generally have NO passive form.\n'
          '• Imperatives:\n'
          '  - Orders: "Let + Object + be + V3" (Shut the door -> Let the door be shut.)\n'
          '  - Advice/Requests: "You are requested/advised to + V1" (Please help -> You are requested to help.)\n'
          '  - Moral Duty: "Object + should be + V3" (Help the poor -> The poor should be helped.)',
    },
    {
      'title': 'Direct & Indirect Speech (Narration Rules)',
      'desc': '• Reporting verb in Past tense causes Tense Shifts:\n'
          '  - Present Simple -> Past Simple (speaks -> spoke)\n'
          '  - Present Continuous -> Past Continuous (is singing -> was singing)\n'
          '  - Present Perfect -> Past Perfect (has done -> had done)\n'
          '  - Past Simple -> Past Perfect (did -> had done)\n'
          '  - Will -> Would | Can -> Could | May -> Might | Shall -> Should\n'
          '• Exception: Universal truths & habitual facts DO NOT change tense. ("The Earth moves around the Sun.")\n'
          '• Changes in Time & Place Adverbs:\n'
          '  - now -> then | today -> that day | yesterday -> the previous day | tomorrow -> the next day | this -> that | here -> there | ago -> before\n'
          '• Interrogative Sentences:\n'
          '  - Yes/No questions: Use "if" or "whether", statement order (He asked me if I was ready.)\n'
          '  - Wh-questions: Keep the question word, no "that" (He asked where I lived.)',
    },
    {
      'title': 'Articles & Determiners (Rules & Exceptions)',
      'desc': '• Indefinite Articles (A / An):\n'
          '  - Based on SOUND, not letter spelling!\n'
          '  - Use "An" before vowel sounds (a, e, i, o, u sounds): an hour, an honest man, an heir, an MBA, an FIR, an umbrella.\n'
          '  - Use "A" before consonant sounds: a European (yu sound), a university, a unique book, a one-eyed man (wa sound).\n'
          '• Definite Article (The):\n'
          '  - Used before unique objects: The Sun, The Moon, The Equator.\n'
          '  - Before rivers, oceans, mountain ranges: The Ganga, The Pacific, The Himalayas (but NOT single peaks: Mt. Everest).\n'
          '  - Before holy books: The Gita, The Quran, The Bible.\n'
          '  - Before Superlatives & Ordinal numbers: The highest, The best, The first.\n'
          '  - Before musical instruments: The violin, The flute.\n'
          '• Omission of Articles (Zero Article):\n'
          '  - Before names of languages (English, Hindi), sports (cricket, chess), meals (breakfast, lunch), proper nouns (Delhi, India), abstract qualities (honesty, love).',
    },
    {
      'title': 'Prepositions & Common Confusing Pairs',
      'desc': '• In vs At: In for large areas/countries/cities (in India, in Mumbai); At for exact points/small towns (at the bus stop, at sector 15).\n'
          '• Between vs Among: Between for TWO persons/things; Among for MORE than two.\n'
          '• Beside vs Besides: Beside means "next to / by the side of"; Besides means "in addition to".\n'
          '• Since vs For: Since for exact Point of Time (since 1995, since Monday, since morning); For for Period/Duration of Time (for 5 hours, for 3 years).\n'
          '• Across vs Through: Across is 2D surface (across the road/river); Through is 3D enclosure (through the tunnel/forest).\n'
          '• Fixed Prepositions:\n'
          '  - Abide by | Abstain from | Accused of | Afraid of | Congratulate on | Depend on | Insist on | Prevent from | Prefer to | Superior to',
    },
    {
      'title': 'High-Frequency Idioms, Phrases & Phrasal Verbs',
      'desc': '• Idioms:\n'
          '  - "A blessing in disguise": Something good that seemed bad at first.\n'
          '  - "Bite the bullet": Face a difficult situation with courage.\n'
          '  - "Burn the midnight oil": Work late into the night.\n'
          '  - "Once in a blue moon": Very rarely.\n'
          '  - "Spill the beans": Reveal a secret unintentionally.\n'
          '  - "Through thick and thin": Under all circumstances.\n'
          '• Phrasal Verbs:\n'
          '  - Call off: Cancel\n'
          '  - Carry out: Execute or perform a task\n'
          '  - Give up: Quit or stop trying\n'
          '  - Look into: Investigate\n'
          '  - Put off: Postpone\n'
          '  - Run out of: Exhaust the supply of\n'
          '• One Word Substitutions:\n'
          '  - Omniscient: One who knows everything\n'
          '  - Omnipotent: One who is all-powerful\n'
          '  - Altruist: One who loves and helps mankind\n'
          '  - Incorrigible: Incapable of being corrected or reformed',
    },
  ];

  // 4. GENERAL SCIENCE (PHYSICS, CHEMISTRY, BIOLOGY FULL SYLLABUS)
  static const List<Map<String, String>> generalScience = [
    {
      'title': 'Physics: SI Units, Dimensions & Scientific Instruments',
      'desc': '• Fundamental SI Units:\n'
          '  - Length: Metre (m) | Mass: Kilogram (kg) | Time: Second (s)\n'
          '  - Electric Current: Ampere (A) | Temperature: Kelvin (K)\n'
          '  - Luminous Intensity: Candela (cd) | Amount of Substance: Mole (mol)\n'
          '• Key Derived Units:\n'
          '  - Force: Newton (N = kg·m/s²) | Work & Energy: Joule (J = N·m)\n'
          '  - Power: Watt (W = J/s), 1 HP = 746 Watts | Pressure: Pascal (Pa = N/m²)\n'
          '  - Frequency: Hertz (Hz = 1/s) | Electric Charge: Coulomb (C = A·s)\n'
          '  - Potential Difference: Volt (V) | Resistance: Ohm (Ω)\n'
          '• Scientific Instruments:\n'
          '  - Barometer: Atmospheric Pressure | Ammeter: Electric Current\n'
          '  - Voltmeter: Voltage | Galvanometer: Detects small currents\n'
          '  - Lactometer: Purity of milk | Hygrometer: Relative Humidity\n'
          '  - Sphygmomanometer: Blood Pressure | Seismograph: Earthquake waves',
    },
    {
      'title': 'Physics: Motion, Newton\'s Laws & Gravitation',
      'desc': '• Newton\'s Laws of Motion:\n'
          '  - 1st Law (Law of Inertia): Body remains at rest or uniform motion unless acted upon by external net force.\n'
          '  - 2nd Law: Force = Mass × Acceleration (F = m × a). Defines momentum (p = m × v).\n'
          '  - 3rd Law: To every action, there is an equal and opposite reaction.\n'
          '• Equations of Uniform Motion:\n'
          '  1. v = u + at | 2. s = ut + ½at² | 3. v² = u² + 2as\n'
          '• Gravitation:\n'
          '  - Universal Law: F = G × (m₁ × m₂) / r² (G = 6.674 × 10⁻¹¹ N·m²/kg²)\n'
          '  - Acceleration due to gravity (Earth): g = 9.8 m/s²\n'
          '  - Value of g: Maximum at Poles, Minimum at Equator, Zero at Earth\'s center.\n'
          '  - Escape Velocity: Earth = 11.2 km/s | Moon = 2.38 km/s (hence moon has no atmosphere).',
    },
    {
      'title': 'Physics: Work, Energy, Optics & Light',
      'desc': '• Work = Force × Displacement × cos(θ) | Unit: Joule\n'
          '• Kinetic Energy = ½mv² | Potential Energy = mgh\n'
          '• Optics & Reflection:\n'
          '  - Angle of incidence = Angle of reflection (i = r)\n'
          '  - Concave mirror: Converging (used in car headlights, dentist mirrors)\n'
          '  - Convex mirror: Diverging, always virtual & erect, wide field of view (rear-view vehicle mirror)\n'
          '• Refraction & Lenses:\n'
          '  - Snell\'s Law: sin(i) / sin(r) = constant (Refractive index μ)\n'
          '  - Total Internal Reflection (TIR): Occurs when light travels from denser to rarer medium and angle of incidence > Critical angle. (Optical fiber, Sparkling of diamond, Mirage)\n'
          '• Human Eye Defects & Corrective Lenses:\n'
          '  - Myopia (Short-sightedness): Distant objects blurred -> Concave Lens\n'
          '  - Hypermetropia (Far-sightedness): Near objects blurred -> Convex Lens\n'
          '  - Presbyopia: Aging eye defect -> Bifocal Lens\n'
          '  - Astigmatism: Cylindrical Lens',
    },
    {
      'title': 'Physics: Electricity, Magnetism & Waves',
      'desc': '• Ohm\'s Law: V = I × R (Voltage = Current × Resistance)\n'
          '• Resistance in Series: R = R₁ + R₂ + R₃ (Current remains constant)\n'
          '• Resistance in Parallel: 1/R = 1/R₁ + 1/R₂ + 1/R₃ (Voltage remains constant)\n'
          '• Electric Power: P = V × I = I²R = V² / R\n'
          '• Heating Effect of Current (Joule\'s Law): H = I²Rt\n'
          '• Waves & Sound:\n'
          '  - Sound is a longitudinal mechanical wave; cannot travel in vacuum!\n'
          '  - Speed of sound: Solids > Liquids > Gases (Fastest in steel, ~343 m/s in air at 20°C).\n'
          '  - Audible frequency range for humans: 20 Hz to 20,000 Hz (20 kHz)\n'
          '  - Infrasonic (< 20 Hz): Elephants, whales, earthquakes\n'
          '  - Ultrasonic (> 20,000 Hz): Bats, dolphins, SONAR, Ultrasound imaging',
    },
    {
      'title': 'Chemistry: Periodic Table Trends & Chemical Bonding',
      'desc': '• Modern Periodic Table created by Henry Moseley (1913), organized by Atomic Number (Z).\n'
          '• 18 Vertical Groups & 7 Horizontal Periods.\n'
          '  - Group 1: Alkali metals (Li, Na, K, Rb, Cs, Fr) - highly reactive\n'
          '  - Group 2: Alkaline earth metals (Be, Mg, Ca, Sr, Ba, Ra)\n'
          '  - Group 17: Halogens (F, Cl, Br, I, At) - Fluorine is the most electronegative element!\n'
          '  - Group 18: Noble / Inert gases (He, Ne, Ar, Kr, Xe, Rn)\n'
          '• Periodic Trends:\n'
          '  - Atomic Radius: Decreases across a period (left to right), Increases down a group.\n'
          '  - Electronegativity & Ionization Energy: Increases across a period, Decreases down a group.\n'
          '  - Metallic Character: Decreases across a period, Increases down a group.',
    },
    {
      'title': 'Chemistry: Acids, Bases, Salts & Everyday Chemicals',
      'desc': '• pH Scale (0 to 14): pH < 7 Acidic | pH = 7 Neutral (Pure water) | pH > 7 Basic\n'
          '  - Human Blood pH: 7.35 - 7.45 (Slightly alkaline)\n'
          '  - Lemon Juice: ~2.2 | Stomach Acid (HCl): ~1.5 - 2.0\n'
          '• Litmus Test: Acid turns blue litmus red; Base turns red litmus blue.\n'
          '• Common Chemical Formulas for Exams:\n'
          '  - Baking Soda: Sodium Hydrogen Carbonate (NaHCO₃)\n'
          '  - Washing Soda: Sodium Carbonate Decahydrate (Na₂CO₃·10H₂O)\n'
          '  - Bleaching Powder: Calcium Oxychloride (CaOCl₂)\n'
          '  - Plaster of Paris (POP): Calcium Sulphate Hemihydrate (CaSO₄·½H₂O)\n'
          '  - Gypsum: Calcium Sulphate Dihydrate (CaSO₄·2H₂O)\n'
          '  - Quick Lime: Calcium Oxide (CaO) | Slaked Lime: Calcium Hydroxide [Ca(OH)₂]\n'
          '  - Laughing Gas: Nitrous Oxide (N₂O)\n'
          '  - Heavy Water: Deuterium Oxide (D₂O) - used as moderator in nuclear reactors\n'
          '  - Dry Ice: Solid Carbon Dioxide (Solid CO₂)',
    },
    {
      'title': 'Chemistry: Metals, Non-Metals & Important Alloys',
      'desc': '• Reactivity Series (Most to Least):\n'
          '  K > Na > Ca > Mg > Al > Zn > Fe > Pb > [H] > Cu > Hg > Ag > Au > Pt\n'
          '• Sodium (Na) and Potassium (K) are kept in kerosene because they react vigorously with water and air.\n'
          '• Mercury (Hg): Only metal that is liquid at room temperature.\n'
          '• Bromine (Br): Only non-metal that is liquid at room temperature.\n'
          '• Diamond: Hardest naturally occurring substance; allotrope of Carbon.\n'
          '• Key Alloys:\n'
          '  - Brass: Copper (Cu) + Zinc (Zn)\n'
          '  - Bronze: Copper (Cu) + Tin (Sn)\n'
          '  - Stainless Steel: Iron (Fe) + Chromium (Cr) + Nickel (Ni) + Carbon (C)\n'
          '  - Solder: Lead (Pb) + Tin (Sn)\n'
          '  - German Silver: Copper (Cu) + Zinc (Zn) + Nickel (Ni) [Contains 0% Silver!]\n'
          '  - Amalgam: Any alloy containing Mercury (Hg)',
    },
    {
      'title': 'Biology: Cell Biology, Organelles & Genetics',
      'desc': '• Cell discovered by Robert Hooke (1665); Living cell by Anton van Leeuwenhoek.\n'
          '• Nucleus discovered by Robert Brown.\n'
          '• Cell Organelles & Nicknames:\n'
          '  - Mitochondria: "Powerhouse of the cell" (Generates ATP through cellular respiration)\n'
          '  - Ribosomes: "Protein factories of the cell"\n'
          '  - Lysosomes: "Suicidal bags of the cell" (Contains digestive enzymes)\n'
          '  - Chloroplast: "Kitchen of the plant cell" (Contains chlorophyll for photosynthesis)\n'
          '  - Golgi Apparatus: Packaging and dispatch center\n'
          '• Plant Cell vs Animal Cell: Plant cells have a rigid cellulose Cell Wall and Chloroplasts; animal cells lack them.\n'
          '• Genetics:\n'
          '  - Gregor Johann Mendel: Father of Genetics (studied garden pea Pisum sativum)\n'
          '  - DNA Structure: Double helix discovered by Watson & Crick (1953)\n'
          '  - Chromosomes in Humans: 46 (23 pairs); 22 pairs autosomes, 1 pair sex chromosomes (XX in female, XY in male).',
    },
    {
      'title': 'Biology: Human Physiology & Organ Systems',
      'desc': '• Circulatory System:\n'
          '  - Heart: 4 chambers (2 Atria, 2 Ventricles); circulation discovered by William Harvey.\n'
          '  - Blood Cells: RBCs (Erythrocytes, lifespan ~120 days, hemoglobin transports O₂);\n'
          '    WBCs (Leukocytes, immunity & defense); Platelets (Thrombocytes, blood clotting).\n'
          '  - Blood Groups (Karl Landsteiner): Universal Donor = O Negative; Universal Recipient = AB Positive.\n'
          '• Digestive System:\n'
          '  - Saliva contains salivary amylase (ptyalin) which digests starch into maltose.\n'
          '  - Stomach secretes Hydrochloric acid (HCl) and Pepsin (digests proteins).\n'
          '  - Liver: Largest internal organ; secretes Bile (stored in Gall Bladder; emulsifies fats).\n'
          '  - Small Intestine: Primary site of complete digestion and nutrient absorption.\n'
          '• Excretory System: Functional unit of Kidney = Nephron.\n'
          '• Nervous System: Functional unit = Neuron; Brain protected by Cranium.',
    },
    {
      'title': 'Biology: Vitamins, Deficiency Diseases & Plant Life',
      'desc': '• Fat Soluble Vitamins: A, D, E, K | Water Soluble Vitamins: B-complex, C\n'
          '  - Vitamin A (Retinol): Deficiency causes Night Blindness (Nyctalopia), Xerophthalmia\n'
          '  - Vitamin B1 (Thiamine): Deficiency causes Beriberi\n'
          '  - Vitamin B3 (Niacin): Deficiency causes Pellagra\n'
          '  - Vitamin B12 (Cyanocobalamin): Contains Cobalt; deficiency causes Pernicious Anaemia\n'
          '  - Vitamin C (Ascorbic Acid): Heat-sensitive; deficiency causes Scurvy (bleeding gums)\n'
          '  - Vitamin D (Calciferol): Sun-synthesized; deficiency causes Rickets (children) & Osteomalacia (adults)\n'
          '  - Vitamin E (Tocopherol): "Beauty vitamin"; antioxidant; fertility\n'
          '  - Vitamin K (Phylloquinone): Essential for blood clotting (prothrombin synthesis)\n'
          '• Plant Physiology:\n'
          '  - Photosynthesis: 6CO₂ + 6H₂O -> C₆H₁₂O₆ + 6O₂ (Light energy to chemical energy)\n'
          '  - Vascular Tissues: Xylem (Transports water & minerals upwards); Phloem (Transports food/sucrose in both directions)\n'
          '  - Plant Hormones: Auxin (Cell elongation, phototropism); Gibberellins (Stem growth); Cytokinin (Cell division); Ethylene (Gas, fruit ripening); Abscisic Acid (Stress hormone, closes stomata).',
    },
  ];

  // 5. POLITY ARTICLES & CONSTITUTIONAL FRAMEWORK
  static const List<Map<String, String>> polityArticles = [
    {'title': 'Article 14', 'desc': 'Equality before law and equal protection of laws.'},
    {'title': 'Article 17', 'desc': 'Abolition of Untouchability and prohibition of its practice.'},
    {'title': 'Article 19', 'desc': 'Protection of 6 fundamental freedoms (Speech, Assembly, Association, Movement, Residence, Profession).'},
    {'title': 'Article 21', 'desc': 'Protection of Life and Personal Liberty (Right to Privacy included under Puttaswamy judgment).'},
    {'title': 'Article 21A', 'desc': 'Right to Free & Compulsory Education for children (6-14 yrs) via 86th Constitutional Amendment Act 2002.'},
    {'title': 'Article 32', 'desc': 'Right to Constitutional Remedies (Writs: Habeas Corpus, Mandamus, Prohibition, Quo-Warranto, Certiorari). Dr. Ambedkar termed it the "Heart and Soul of Constitution".'},
    {'title': 'Article 40', 'desc': 'Organization of Village Panchayats (Directive Principle - Gandhian).'},
    {'title': 'Article 44', 'desc': 'Uniform Civil Code (UCC) for all citizens throughout India.'},
    {'title': 'Article 51A', 'desc': 'Fundamental Duties (11 duties; borrowed from USSR, added by 42nd CAA 1976 on Swaran Singh Committee recommendation).'},
    {'title': 'Article 61', 'desc': 'Procedure for Impeachment of the President of India for violation of the Constitution.'},
    {'title': 'Article 72', 'desc': 'Pardoning power of the President of India (Pardon, Reprieve, Respite, Remission, Commutation).'},
    {'title': 'Article 110', 'desc': 'Definition of Money Bills (Lok Sabha Speaker has the final authority to certify a Money Bill).'},
    {'title': 'Article 112', 'desc': 'Annual Financial Statement (Union Budget of India).'},
    {'title': 'Article 280', 'desc': 'Finance Commission constituted by the President every 5 years for tax devolution.'},
    {'title': 'Article 324', 'desc': 'Superintendence, direction, and control of elections vested in the Election Commission of India.'},
    {'title': 'Article 352', 'desc': 'National Emergency (Grounds: War, External Aggression, Armed Rebellion).'},
    {'title': 'Article 356', 'desc': 'President\'s Rule (Failure of constitutional machinery in states).'},
    {'title': 'Article 360', 'desc': 'Financial Emergency (Never declared so far in India).'},
    {'title': 'Article 368', 'desc': 'Power of Parliament to amend the Constitution and procedure therefor.'},
  ];

  // 6. MODERN INDIAN HISTORY TIMELINE (1857-1947)
  static const List<Map<String, String>> historyTimeline = [
    {'title': '1857', 'desc': 'Sepoy Mutiny / First War of Independence begins at Meerut (Mangal Pandey at Barrackpore). Bahadur Shah Zafar declared Emperor.'},
    {'title': '1885', 'desc': 'Formation of Indian National Congress (INC) by A.O. Hume. First session at Gokuldas Tejpal College, Bombay (W.C. Bonnerjee President).'},
    {'title': '1905', 'desc': 'Partition of Bengal announced by Lord Curzon. Swadeshi & Boycott Movement begins; "Vande Mataram" becomes freedom anthem.'},
    {'title': '1906', 'desc': 'All India Muslim League founded at Dhaka by Nawab Salimullah, Aga Khan, and Mohsin-ul-Mulk.'},
    {'title': '1909', 'desc': 'Morley-Minto Reforms (Indian Councils Act 1909) introduces separate electorates for Muslims.'},
    {'title': '1911', 'desc': 'Annulment of Partition of Bengal; Capital of British India shifted from Calcutta to Delhi.'},
    {'title': '1915', 'desc': 'Mahatma Gandhi returns to India from South Africa (9 January - celebrated as Pravasi Bharatiya Divas).'},
    {'title': '1916', 'desc': 'Lucknow Pact between INC and Muslim League. Home Rule Movement launched by Bal Gangadhar Tilak and Annie Besant.'},
    {'title': '1917', 'desc': 'Champaran Satyagraha in Bihar: Gandhi\'s first Civil Disobedience against Tinkathia indigo system.'},
    {'title': '1919', 'desc': 'Jallianwala Bagh Massacre (13 April) under General Dyer; Rowlatt Act ("No Dalil, No Vakil, No Appeal"); Montagu-Chelmsford Reforms (Dyarchy in provinces).'},
    {'title': '1920', 'desc': 'Non-Cooperation Movement launched by Mahatma Gandhi along with the Khilafat Movement.'},
    {'title': '1922', 'desc': 'Chauri Chaura incident (Gorakhpur, UP); violent mob burns police station. Gandhi suspends Non-Cooperation Movement.'},
    {'title': '1928', 'desc': 'Simon Commission arrives ("Simon Go Back"); Lala Lajpat Rai martyred due to lathi charge. Nehru Report published.'},
    {'title': '1929', 'desc': 'Lahore Congress Session presided by Jawaharlal Nehru passes "Purna Swaraj" (Complete Independence) resolution.'},
    {'title': '1930', 'desc': 'Dandi March (12 March - 6 April) from Sabarmati to Dandi (240 miles). Civil Disobedience Movement launched by breaking Salt Law.'},
    {'title': '1931', 'desc': 'Gandhi-Irwin Pact signed; Bhagat Singh, Sukhdev & Rajguru martyred (23 March). Second Round Table Conference attended by Gandhi.'},
    {'title': '1932', 'desc': 'Poona Pact signed between Dr. B.R. Ambedkar and Mahatma Gandhi in Yerwada Jail, ensuring reserved seats for Depressed Classes.'},
    {'title': '1935', 'desc': 'Government of India Act 1935 passed (Provincial Autonomy, Federal Court, Reserve Bank of India established).'},
    {'title': '1942', 'desc': 'Cripps Mission fails. Quit India Movement launched (8 August) at Gowalia Tank, Bombay with the slogan "Do or Die" (Karo ya Maro).'},
    {'title': '1946', 'desc': 'Cabinet Mission arrives in India; Constituent Assembly formed (Dr. Sachchidananda Sinha interim, Dr. Rajendra Prasad permanent President).'},
    {'title': '1947', 'desc': 'Mountbatten Plan (3 June Plan); Indian Independence Act passed by British Parliament; India gains freedom on 15 August 1947.'},
  ];
}
