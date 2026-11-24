import 'package:flutter/material.dart';

class QuickRevisionHandbookModal extends StatefulWidget {
  const QuickRevisionHandbookModal({Key? key}) : super(key: key);

  @override
  State<QuickRevisionHandbookModal> createState() => _QuickRevisionHandbookModalState();
}

class _QuickRevisionHandbookModalState extends State<QuickRevisionHandbookModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _polityArticles = [
    {'title': 'Article 14', 'desc': 'Equality before law and equal protection of laws.'},
    {'title': 'Article 17', 'desc': 'Abolition of Untouchability and prohibition of its practice.'},
    {'title': 'Article 19', 'desc': 'Protection of 6 fundamental freedoms (Speech, Assembly, Association, etc.).'},
    {'title': 'Article 21', 'desc': 'Protection of Life and Personal Liberty (Right to Privacy included).'},
    {'title': 'Article 21A', 'desc': 'Right to Free & Compulsory Education for children (6-14 yrs) via 86th CAA.'},
    {'title': 'Article 32', 'desc': 'Right to Constitutional Remedies (Writs: Habeas Corpus, Mandamus, Quo-Warranto). "Heart and Soul".'},
    {'title': 'Article 40', 'desc': 'Organization of Village Panchayats (Gandhian Principle).'},
    {'title': 'Article 44', 'desc': 'Uniform Civil Code (UCC) for the citizens throughout India.'},
    {'title': 'Article 51A', 'desc': 'Fundamental Duties (11 duties, borrowed from USSR, added by 42nd CAA 1976).'},
    {'title': 'Article 61', 'desc': 'Procedure for Impeachment of the President of India.'},
    {'title': 'Article 72', 'desc': 'Pardoning power of the President of India.'},
    {'title': 'Article 110', 'desc': 'Definition of Money Bills (Speaker has final decision authority).'},
    {'title': 'Article 112', 'desc': 'Annual Financial Statement (Union Budget of India).'},
    {'title': 'Article 280', 'desc': 'Finance Commission constituted by the President every 5 years.'},
    {'title': 'Article 324', 'desc': 'Superintendence, direction, and control of elections in Election Commission.'},
    {'title': 'Article 352', 'desc': 'National Emergency (War, External Aggression, Armed Rebellion).'},
    {'title': 'Article 356', 'desc': 'President\'s Rule (Failure of constitutional machinery in states).'},
    {'title': 'Article 360', 'desc': 'Financial Emergency (Never declared so far in India).'},
    {'title': 'Article 368', 'desc': 'Power of Parliament to amend the Constitution and procedure therefor.'},
  ];

  final List<Map<String, String>> _historyTimeline = [
    {'title': '1857', 'desc': 'Sepoy Mutiny / First War of Independence begins at Meerut (Mangal Pandey).'},
    {'title': '1885', 'desc': 'Formation of Indian National Congress (INC) by A.O. Hume. First session at Bombay (W.C. Bonnerjee).'},
    {'title': '1905', 'desc': 'Partition of Bengal announced by Lord Curzon. Swadeshi & Boycott Movement begins.'},
    {'title': '1906', 'desc': 'All India Muslim League founded at Dhaka by Nawab Salimullah & Aga Khan.'},
    {'title': '1916', 'desc': 'Lucknow Pact between INC and Muslim League. Home Rule Movement by Tilak & Annie Besant.'},
    {'title': '1919', 'desc': 'Jallianwala Bagh Massacre (13 April) under General Dyer; Rowlatt Act; Montagu-Chelmsford Reforms.'},
    {'title': '1920', 'desc': 'Non-Cooperation Movement launched by Mahatma Gandhi along with Khilafat Movement.'},
    {'title': '1922', 'desc': 'Chauri Chaura incident (UP); Gandhi withdraws Non-Cooperation Movement.'},
    {'title': '1930', 'desc': 'Dandi March (12 March - 6 April) and Civil Disobedience Movement launched by Gandhi.'},
    {'title': '1931', 'desc': 'Gandhi-Irwin Pact signed; Bhagat Singh, Sukhdev & Rajguru martyred (23 March).'},
    {'title': '1942', 'desc': 'Quit India Movement launched (8 August) with the slogan "Do or Die" (Karo ya Maro).'},
    {'title': '1946', 'desc': 'Cabinet Mission arrives in India; Constituent Assembly formed (Dr. Rajendra Prasad President).'},
    {'title': '1947', 'desc': 'Indian Independence Act passed; India gains freedom on 15 August 1947.'},
  ];

  final List<Map<String, String>> _mathFormulas = [
    {'title': 'Percentage Change', 'desc': 'Change% = [(Final - Initial) / Initial] × 100'},
    {'title': 'Profit & Loss', 'desc': 'Profit% = (Profit / CP) × 100\nLoss% = (Loss / CP) × 100\nSP = CP × (100 ± Profit/Loss)%'},
    {'title': 'Simple & Compound Interest', 'desc': 'SI = (P × R × T) / 100\nCI = P × [ (1 + R/100)^T - 1 ]\nDiff for 2 yrs: CI - SI = P × (R/100)^2'},
    {'title': 'Speed, Distance & Time', 'desc': 'Speed = Distance / Time\nkm/h to m/s: Multiply by 5/18\nm/s to km/h: Multiply by 18/5\nAverage Speed = (2 × S1 × S2) / (S1 + S2)'},
    {'title': 'Time & Work', 'desc': 'If A does work in x days & B in y days, together = (xy) / (x + y) days\nWork = Efficiency × Time'},
    {'title': 'Mensuration 2D', 'desc': 'Circle Area = πr² | Perimeter = 2πr\nTriangle Area = ½ × Base × Height or √[s(s-a)(s-b)(s-c)]\nEquilateral Triangle = (√3 / 4) × a²'},
    {'title': 'Mensuration 3D', 'desc': 'Cylinder: Volume = πr²h | CSA = 2πrh | TSA = 2πr(h+r)\nSphere: Volume = (4/3)πr³ | Surface Area = 4πr²\nCone: Volume = (1/3)πr²h | Slant height l = √(r² + h²)'},
  ];

  final List<Map<String, String>> _scienceFacts = [
    {'title': 'Vitamins & Chemical Names', 'desc': 'Vit A: Retinol (Night blindness)\nVit B1: Thiamine (Beriberi)\nVit C: Ascorbic acid (Scurvy)\nVit D: Calciferol (Rickets)\nVit K: Phylloquinone (Blood clotting)'},
    {'title': 'Human Body Facts', 'desc': 'Total Bones: 206 (Infants: 300)\nLargest Bone: Femur (Thigh)\nSmallest Bone: Stapes (Ear)\nBlood pH: 7.35 - 7.45 (Slightly alkaline)\nUniversal Donor: O negative | Universal Recipient: AB positive'},
    {'title': 'Common Chemical Formulas', 'desc': 'Baking Soda: NaHCO₃\nWashing Soda: Na₂CO₃·10H₂O\nBleaching Powder: CaOCl₂\nPlaster of Paris: CaSO₄·½H₂O\nGypsum: CaSO₄·2H₂O\nLaughing Gas: N₂O'},
    {'title': 'SI Units & Instruments', 'desc': 'Electric Current: Ampere (A)\nFrequency: Hertz (Hz)\nAtmospheric Pressure: Barometer\nEarthquake Intensity: Richter Scale / Seismograph\nRelative Humidity: Hygrometer'},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              decoration: BoxDecoration(
                color: Colors.amber.shade900,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Revision Handbook',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'High-yield Constitution Articles, History timeline & Formulas',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.amber.shade900,
              indicatorColor: Colors.amber.shade900,
              tabs: const [
                Tab(text: 'Polity Articles'),
                Tab(text: 'History Timeline'),
                Tab(text: 'Math Formulas'),
                Tab(text: 'General Science'),
              ],
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search formula, article, or fact...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setState(() => _searchController.clear()))
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_polityArticles),
                  _buildList(_historyTimeline),
                  _buildList(_mathFormulas),
                  _buildList(_scienceFacts),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, String>> items) {
    final filtered = items.where((it) {
      if (_searchQuery.isEmpty) return true;
      return it['title']!.toLowerCase().contains(_searchQuery) ||
          it['desc']!.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No matching items found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (ctx, idx) {
        final it = filtered[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it['title']!,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900),
                ),
                const SizedBox(height: 4),
                Text(
                  it['desc']!,
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
