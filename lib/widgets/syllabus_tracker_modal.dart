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

  // Default hardcoded syllabi
  final Map<String, Map<String, dynamic>> _defaultExamSyllabi = {
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

  // Live dynamic working syllabi (merged default + user custom)
  Map<String, Map<String, dynamic>> _examSyllabi = {};
  // Custom added categories/subjects tracker
  Map<String, Map<String, List<String>>> _customSubjects = {};
  // Custom added exams tracker (examId -> title)
  Map<String, String> _customExams = {};

  @override
  void initState() {
    super.initState();
    _loadAllSyllabusData();
  }

  Future<void> _loadAllSyllabusData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedChecked = prefs.getStringList('syllabus_checked_topics') ?? [];
    final savedExam = prefs.getString('syllabus_selected_exam') ?? 'upsc';

    // Clone defaults deeply
    final Map<String, Map<String, dynamic>> merged = {};
    _defaultExamSyllabi.forEach((k, v) {
      final subMap = <String, List<String>>{};
      (v['subjects'] as Map<String, dynamic>).forEach((subK, subV) {
        subMap[subK] = List<String>.from(subV as List);
      });
      merged[k] = {
        'title': v['title'] as String,
        'subjects': subMap,
      };
    });

    // Load custom exams
    final customExamsJson = prefs.getString('syllabus_custom_exams_v2');
    if (customExamsJson != null) {
      try {
        final decoded = jsonDecode(customExamsJson) as Map<String, dynamic>;
        _customExams = decoded.map((k, v) => MapEntry(k, v.toString()));
        _customExams.forEach((id, title) {
          merged.putIfAbsent(id, () => {
            'title': title,
            'subjects': <String, List<String>>{},
          });
        });
      } catch (_) {}
    }

    // Load custom subjects & topics
    final customSubjectsJson = prefs.getString('syllabus_custom_subjects_v2');
    if (customSubjectsJson != null) {
      try {
        final decoded = jsonDecode(customSubjectsJson) as Map<String, dynamic>;
        decoded.forEach((examId, subObj) {
          final examSubs = merged.putIfAbsent(examId, () => {
            'title': _customExams[examId] ?? examId.toUpperCase(),
            'subjects': <String, List<String>>{},
          })['subjects'] as Map<String, List<String>>;

          final subMap = subObj as Map<String, dynamic>;
          subMap.forEach((subName, topicsList) {
            final list = (topicsList as List<dynamic>).map((e) => e.toString()).toList();
            examSubs[subName] = list;

            _customSubjects.putIfAbsent(examId, () => {})[subName] = list;
          });
        });
      } catch (_) {}
    }

    setState(() {
      _examSyllabi = merged;
      _checkedTopics.addAll(savedChecked);
      _selectedExam = merged.containsKey(savedExam) ? savedExam : 'upsc';
      _isLoading = false;
    });
  }

  Future<void> _saveCustomData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('syllabus_custom_exams_v2', jsonEncode(_customExams));
    await prefs.setString('syllabus_custom_subjects_v2', jsonEncode(_customSubjects));
    await prefs.setStringList('syllabus_checked_topics', _checkedTopics.toList());
    await prefs.setString('syllabus_selected_exam', _selectedExam);
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

  /// Adds a New Subject / Category under current exam
  void _showAddSubjectCategoryDialog() {
    final nameController = TextEditingController();
    final firstTopicController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.create_new_folder_outlined, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text('Add Subject / Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a new subject to ${_examSyllabi[_selectedExam]?['title'] ?? 'this exam'}:',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category / Subject Name *',
                hintText: 'e.g. General Science, Indian Economy, Ethics',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: firstTopicController,
              decoration: const InputDecoration(
                labelText: 'First Topic Title (Optional)',
                hintText: 'e.g. Fundamental Concepts & Principles',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final subName = nameController.text.trim();
              final topic = firstTopicController.text.trim();
              if (subName.isNotEmpty) {
                final currentExam = _examSyllabi[_selectedExam]!;
                final subjects = currentExam['subjects'] as Map<String, List<String>>;

                setState(() {
                  final list = subjects.putIfAbsent(subName, () => []);
                  if (topic.isNotEmpty && !list.contains(topic)) {
                    list.add(topic);
                  }
                  // Persist in customSubjects
                  final customList = _customSubjects.putIfAbsent(_selectedExam, () => {}).putIfAbsent(subName, () => []);
                  if (topic.isNotEmpty && !customList.contains(topic)) {
                    customList.add(topic);
                  }
                });

                _saveCustomData();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Subject "$subName" added to Syllabus! ✅'),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              }
            },
            child: const Text('Save Category'),
          ),
        ],
      ),
    );
  }

  /// Adds a New Custom Exam / Syllabus Category (e.g. State PSC, Railway, etc.)
  void _showAddCustomExamDialog() {
    final examTitleController = TextEditingController();
    final firstSubjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.school_outlined, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text('Add Target Exam / Syllabus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a completely new exam track with its own syllabus subjects & topics:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: examTitleController,
              decoration: const InputDecoration(
                labelText: 'Exam Name *',
                hintText: 'e.g. State PSC, Railway RRB, CTET',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: firstSubjectController,
              decoration: const InputDecoration(
                labelText: 'First Subject (Optional)',
                hintText: 'e.g. General Studies & Aptitude',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final title = examTitleController.text.trim();
              final firstSub = firstSubjectController.text.trim();
              if (title.isNotEmpty) {
                final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
                final subMap = <String, List<String>>{};
                if (firstSub.isNotEmpty) {
                  subMap[firstSub] = [];
                  _customSubjects.putIfAbsent(id, () => {})[firstSub] = [];
                }

                setState(() {
                  _customExams[id] = title;
                  _examSyllabi[id] = {
                    'title': title,
                    'subjects': subMap,
                  };
                  _selectedExam = id;
                });

                _saveCustomData();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('New Syllabus "$title" created! ✅'),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              }
            },
            child: const Text('Create Exam'),
          ),
        ],
      ),
    );
  }

  /// Adds a Topic inside a specific subject
  void _showAddTopicDialog(String subjectName) {
    final topicController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Topic to $subjectName', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: topicController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Topic Title *',
            hintText: 'e.g. Monetary Policy & RBI Functions',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final top = topicController.text.trim();
              if (top.isNotEmpty) {
                final currentExam = _examSyllabi[_selectedExam]!;
                final subjects = currentExam['subjects'] as Map<String, List<String>>;

                setState(() {
                  subjects.putIfAbsent(subjectName, () => []).add(top);
                  _customSubjects.putIfAbsent(_selectedExam, () => {}).putIfAbsent(subjectName, () => []).add(top);
                });

                _saveCustomData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Topic'),
          ),
        ],
      ),
    );
  }

  void _deleteCustomTopic(String subjectName, String topic) {
    setState(() {
      final currentExam = _examSyllabi[_selectedExam]!;
      final subjects = currentExam['subjects'] as Map<String, List<String>>;
      subjects[subjectName]?.remove(topic);
      _customSubjects[_selectedExam]?[subjectName]?.remove(topic);
      _checkedTopics.remove('$_selectedExam::$subjectName::$topic');
    });
    _saveCustomData();
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
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
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

            // Exam Selector Chips + "+ Exam" Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Theme.of(context).cardColor,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildExamChip('upsc', 'UPSC CSE'),
                    const SizedBox(width: 6),
                    _buildExamChip('ssc_cgl', 'SSC CGL'),
                    const SizedBox(width: 6),
                    _buildExamChip('banking', 'Banking (IBPS)'),
                    ..._customExams.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _buildExamChip(e.key, e.value),
                    )),
                    const SizedBox(width: 6),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 14, color: Color(0xFF059669)),
                      label: const Text('+ New Exam', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                      backgroundColor: const Color(0xFF059669).withOpacity(0.08),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      visualDensity: VisualDensity.compact,
                      onPressed: _showAddCustomExamDialog,
                    ),
                  ],
                ),
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
              child: subjects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'No subjects added to ${examData['title']} yet.\nTap "+ Add Subject / Category" below to start!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(14),
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
                                topicList.isEmpty
                                    ? 'No topics yet'
                                    : '$subCompleted of ${topicList.length} completed',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: (topicList.isNotEmpty && subCompleted == topicList.length)
                                      ? Colors.green
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              children: [
                                ...topicList.map((topic) {
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
                                    secondary: _customSubjects[_selectedExam]?[subName]?.contains(topic) == true
                                        ? IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                            tooltip: 'Remove Topic',
                                            onPressed: () => _deleteCustomTopic(subName, topic),
                                          )
                                        : null,
                                    value: isChecked,
                                    onChanged: (_) => _toggleTopic(key),
                                  );
                                }).toList(),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      icon: const Icon(Icons.add, size: 14),
                                      label: Text('Add topic to $subName', style: const TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF059669),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () => _showAddTopicDialog(subName),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
            ),

            // Footer Action: "+ Add Category / Subject"
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Add Subject / Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _showAddSubjectCategoryDialog,
                    ),
                  ),
                ],
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
