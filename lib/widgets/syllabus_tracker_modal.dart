import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyllabusTrackerModal extends StatefulWidget {
  const SyllabusTrackerModal({Key? key}) : super(key: key);

  @override
  State<SyllabusTrackerModal> createState() => _SyllabusTrackerModalState();
}

class _SyllabusTrackerModalState extends State<SyllabusTrackerModal> {
  String _selectedExam = 'upsc';
  final Set<String> _checkedTopics = {};
  bool _isLoading = true;

  final Map<String, Map<String, dynamic>> _examSyllabi = {
    'upsc': {
      'title': 'UPSC Prelims (GS-1)',
      'subjects': {
        'Indian Polity & Governance': [
          'Preamble, Fundamental Rights & Duties',
          'Directive Principles of State Policy (DPSP)',
          'Parliament, Lok Sabha & Rajya Sabha',
          'Supreme Court & High Courts',
          'Panchayati Raj & 73rd/74th Amendments',
          'Constitutional Bodies (Election Comm, UPSC, CAG)',
        ],
        'Modern Indian History': [
          'Revolt of 1857 & Early Resistance',
          'Socio-Religious Reform Movements',
          'Indian National Congress & Moderate Phase',
          'Gandhian Era (Non-Cooperation, Civil Disobedience)',
          'Quit India Movement & INA',
          'Partition & Independence 1947',
        ],
        'Geography of India & World': [
          'Physiography of India (Himalayas, Peninsular)',
          'Drainage System & River Basins',
          'Monsoon Mechanism & Indian Climate',
          'Soils & Natural Vegetation of India',
          'World Geography: Climatology & Oceanography',
        ],
        'Indian Economy': [
          'National Income & GDP Accounting',
          'Inflation & Monetary Policy (RBI, Repo Rate)',
          'Fiscal Policy & Union Budget',
          'Banking Sector Reforms & NPAs',
          'External Sector & Balance of Payments (BoP)',
        ],
      },
    },
    'ssc_cgl': {
      'title': 'SSC CGL Tier 1',
      'subjects': {
        'General Awareness': [
          'Indian Constitution & Articles',
          'Modern History & Freedom Struggle',
          'Static GK: Dances, Festivals & Awards',
          'General Science: Physics, Chemistry & Biology',
          'Economics & Financial Awareness',
        ],
        'Quantitative Aptitude': [
          'Percentages & Profit and Loss',
          'Ratio, Proportion & Mixture',
          'Time, Speed, Distance & Trains',
          'Algebra & Linear Equations',
          'Geometry & Mensuration 2D/3D',
          'Trigonometry & Heights and Distances',
        ],
        'General Intelligence & Reasoning': [
          'Analogy & Classification',
          'Blood Relations & Direction Sense',
          'Coding-Decoding & Syllogism',
          'Series Completion (Number & Letter)',
          'Non-Verbal Reasoning (Paper Folding, Mirror)',
        ],
      },
    },
    'banking': {
      'title': 'Banking (IBPS / SBI)',
      'subjects': {
        'Quantitative Aptitude': [
          'Simplification & Approximation',
          'Data Interpretation (Bar, Pie, Table)',
          'Number Series & Quadratic Equations',
          'Arithmetic: Simple & Compound Interest',
          'Probability & Permutation-Combination',
        ],
        'Reasoning Ability': [
          'Seating Arrangement (Circular & Linear)',
          'Puzzles (Floor, Box & Date-Based)',
          'Inequality & Syllogism',
          'Input-Output & Coding-Decoding',
        ],
        'Banking & Financial Awareness': [
          'RBI Functions & Monetary Policy',
          'Banking Ombudsman & Priority Sector Lending',
          'Financial Instruments (Call Money, T-Bills)',
          'Current Affairs (Last 6 Months)',
        ],
      },
    },
  };

  @override
  void initState() {
    super.initState();
    _loadCheckedTopics();
  }

  Future<void> _loadCheckedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('syllabus_checked_topics') ?? [];
    final savedExam = prefs.getString('syllabus_selected_exam') ?? 'upsc';

    setState(() {
      _checkedTopics.addAll(saved);
      _selectedExam = savedExam;
      _isLoading = false;
    });
  }

  Future<void> _toggleTopic(String topicKey) async {
    setState(() {
      if (_checkedTopics.contains(topicKey)) {
        _checkedTopics.remove(topicKey);
      } else {
        _checkedTopics.add(topicKey);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('syllabus_checked_topics', _checkedTopics.toList());
  }

  Future<void> _setExam(String examId) async {
    setState(() => _selectedExam = examId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('syllabus_selected_exam', examId);
  }

  void _showAddCustomTopicDialog() {
    final subjectController = TextEditingController();
    final topicController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Custom Syllabus Topic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g. Environmental Science',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: topicController,
              decoration: const InputDecoration(
                labelText: 'Topic Title',
                hintText: 'e.g. National Parks & Biodiversity Act',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final sub = subjectController.text.trim();
              final top = topicController.text.trim();
              if (sub.isNotEmpty && top.isNotEmpty) {
                final currentExam = _examSyllabi[_selectedExam]!;
                final subjects = currentExam['subjects'] as Map<String, List<String>>;
                setState(() {
                  subjects.putIfAbsent(sub, () => []).add(top);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Topic'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }

    final examData = _examSyllabi[_selectedExam] ?? _examSyllabi['upsc']!;
    final subjects = examData['subjects'] as Map<String, List<String>>;

    int totalTopics = 0;
    int completedTopics = 0;

    subjects.forEach((sub, topics) {
      totalTopics += topics.length;
      for (final t in topics) {
        final key = '$_selectedExam::$sub::$t';
        if (_checkedTopics.contains(key)) completedTopics++;
      }
    });

    final pct = totalTopics > 0 ? ((completedTopics / totalTopics) * 100).round() : 0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.checklist_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Interactive Syllabus Tracker',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Track topic completion, chapter checklists & exam progress',
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

            // Exam Selector Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  _buildExamChip('upsc', 'UPSC CSE'),
                  const SizedBox(width: 6),
                  _buildExamChip('ssc_cgl', 'SSC CGL'),
                  const SizedBox(width: 6),
                  _buildExamChip('banking', 'Banking (IBPS)'),
                ],
              ),
            ),

            // Progress Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF10B981).withOpacity(0.08),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${examData['title']} Progress:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '$pct% Completed ($completedTopics/$totalTopics Topics)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Subjects & Topics Checklist
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...subjects.entries.map((entry) {
                    final subName = entry.key;
                    final topicList = entry.value;

                    final subCompleted = topicList.where((t) {
                      final key = '$_selectedExam::$subName::$t';
                      return _checkedTopics.contains(key);
                    }).length;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Text(
                          subName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '$subCompleted of ${topicList.length} completed',
                          style: TextStyle(
                            fontSize: 11,
                            color: subCompleted == topicList.length ? Colors.green : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: topicList.map((topic) {
                          final key = '$_selectedExam::$subName::$topic';
                          final isChecked = _checkedTopics.contains(key);

                          return CheckboxListTile(
                            dense: true,
                            activeColor: const Color(0xFF10B981),
                            title: Text(
                              topic,
                              style: TextStyle(
                                fontSize: 13,
                                decoration: isChecked ? TextDecoration.lineThrough : null,
                                color: isChecked ? Colors.grey : null,
                              ),
                            ),
                            value: isChecked,
                            onChanged: (_) => _toggleTopic(key),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Footer action
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Custom Topic to Syllabus', style: TextStyle(fontSize: 12)),
                onPressed: _showAddCustomTopicDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamChip(String id, String label) {
    final isSel = _selectedExam == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: const Color(0xFF10B981),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSel ? Colors.white : null,
      ),
      onSelected: (val) {
        if (val) _setExam(id);
      },
    );
  }
}
