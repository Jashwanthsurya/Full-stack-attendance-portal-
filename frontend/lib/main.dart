import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const AttendancePortalApp());
}

class AttendancePortalApp extends StatefulWidget {
  const AttendancePortalApp({super.key});

  @override
  State<AttendancePortalApp> createState() => _AttendancePortalAppState();
}

class _AttendancePortalAppState extends State<AttendancePortalApp> {
  final ApiClient _api = ApiClient();
  AuthSession? _session;

  void _onAuthenticated(AuthSession session) {
    setState(() {
      _session = session;
    });
  }

  void _logout() {
    setState(() {
      _session = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E7490),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Attendance Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        textTheme: GoogleFonts.spaceGroteskTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
        useMaterial3: true,
      ),
      home: _session == null
          ? LoginScreen(api: _api, onAuthenticated: _onAuthenticated)
          : _session!.role == 'admin'
              ? AdminScreen(api: _api, session: _session!, onLogout: _logout)
              : StudentScreen(api: _api, session: _session!, onLogout: _logout),
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.role,
    required this.displayName,
    this.rollNumber,
  });

  final String token;
  final String role;
  final String displayName;
  final String? rollNumber;
}

class ApiClient {
  static const String _defaultBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: '/api',
  );

  final String base = _defaultBase;

  Future<Map<String, dynamic>> login({
    required String loginInput,
    required String password,
  }) async {
    return _post(
      '/auth/login',
      body: {
        'login_input': loginInput,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> fetchStudentDashboard(String token) {
    return _get('/student/dashboard', token: token);
  }

  Future<Map<String, dynamic>> fetchClassSelection(String token) {
    return _get('/student/class-selection', token: token);
  }

  Future<Map<String, dynamic>> confirmAttendance({
    required String token,
    required String subject,
  }) {
    return _post('/student/confirm-attendance', token: token, body: {'subject': subject});
  }

  Future<Map<String, dynamic>> fetchAdminSummary(String token) {
    return _get('/admin/summary', token: token);
  }

  String exportUrl(String token) {
    final encoded = Uri.encodeQueryComponent(token);
    return '$base/admin/export?token=$encoded';
  }

  Future<Map<String, dynamic>> _get(String path, {String? token}) async {
    final response = await http.get(
      Uri.parse('$base$path'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('$base$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final raw = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    if (response.statusCode >= 400 || decoded['ok'] == false) {
      throw ApiException(decoded['error']?.toString() ?? 'Request failed');
    }
    return decoded;
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.api,
    required this.onAuthenticated,
  });

  final ApiClient api;
  final ValueChanged<AuthSession> onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await widget.api.login(
        loginInput: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final role = result['role'] as String;
      if (role == 'admin') {
        widget.onAuthenticated(
          AuthSession(
            token: result['token'] as String,
            role: role,
            displayName: result['admin_name'] as String? ?? 'Administrator',
          ),
        );
      } else {
        widget.onAuthenticated(
          AuthSession(
            token: result['token'] as String,
            role: role,
            displayName: result['student_name'] as String,
            rollNumber: result['roll_number'] as String,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(20),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Attendance Portal',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Students: shortname + password (e.g. alex / pass01)\nAdmin: admin / admin123',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StudentScreen extends StatefulWidget {
  const StudentScreen({
    super.key,
    required this.api,
    required this.session,
    required this.onLogout,
  });

  final ApiClient api;
  final AuthSession session;
  final VoidCallback onLogout;

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _classSelection;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        widget.api.fetchStudentDashboard(widget.session.token),
        widget.api.fetchClassSelection(widget.session.token),
      ]);
      setState(() {
        _dashboard = responses[0];
        _classSelection = responses[1];
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _confirmAndMark(String subject) async {
    final shouldMark = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Attendance'),
          content: Text('Mark attendance for $subject?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mark')),
          ],
        );
      },
    );

    if (shouldMark != true) {
      return;
    }

    try {
      final response = await widget.api.confirmAttendance(
        token: widget.session.token,
        subject: subject,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] as String? ?? 'Attendance marked.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    } else {
      body = IndexedStack(
        index: _tab,
        children: [
          StudentDashboardView(data: _dashboard ?? const <String, dynamic>{}),
          ClassSelectionView(
            data: _classSelection ?? const <String, dynamic>{},
            onMark: _confirmAndMark,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${widget.session.displayName}'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          TextButton(onPressed: widget.onLogout, child: const Text('Logout')),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          setState(() {
            _tab = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Mark Attendance'),
        ],
      ),
    );
  }
}

class StudentDashboardView extends StatelessWidget {
  const StudentDashboardView({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final todayAttendance =
        (data['today_attendance'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final classSchedule =
        (data['class_schedule'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Today: ${data['today'] ?? ''}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        Text('Attendance Status', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        ...todayAttendance.entries.map((entry) {
          final marked = entry.value == true;
          return Card(
            child: ListTile(
              title: Text(entry.key),
              subtitle: Text(marked ? 'Present' : 'Not marked'),
              trailing: Icon(
                marked ? Icons.check_circle : Icons.radio_button_unchecked,
                color: marked ? Colors.green : Colors.grey,
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        Text('Class Schedule', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        ...classSchedule.entries.map((entry) {
          final schedule = entry.value as Map<String, dynamic>;
          return Card(
            child: ListTile(
              title: Text(entry.key),
              subtitle: Text('${schedule['start']} - ${schedule['end']}'),
            ),
          );
        }),
      ],
    );
  }
}

class ClassSelectionView extends StatelessWidget {
  const ClassSelectionView({
    super.key,
    required this.data,
    required this.onMark,
  });

  final Map<String, dynamic> data;
  final ValueChanged<String> onMark;

  @override
  Widget build(BuildContext context) {
    final available =
        (data['available_classes'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Current Time: ${data['current_time'] ?? ''}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        ...available.entries.map((entry) {
          final info = entry.value as Map<String, dynamic>;
          final isAvailable = info['is_available'] == true;
          final hasMarked = info['has_marked'] == true;

          return Card(
            child: ListTile(
              title: Text(entry.key),
              subtitle: Text('${info['start_time']} - ${info['end_time']}'),
              trailing: hasMarked
                  ? const Chip(label: Text('Marked'))
                  : isAvailable
                      ? FilledButton(
                          onPressed: () => onMark(entry.key),
                          child: const Text('Mark'),
                        )
                      : const Chip(label: Text('Not Active')),
            ),
          );
        }),
      ],
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({
    super.key,
    required this.api,
    required this.session,
    required this.onLogout,
  });

  final ApiClient api;
  final AuthSession session;
  final VoidCallback onLogout;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await widget.api.fetchAdminSummary(widget.session.token);
      setState(() {
        _summary = response;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openExport() async {
    final uri = Uri.parse(widget.api.exportUrl(widget.session.token));
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open export URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Reports')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final summary = _summary ?? const <String, dynamic>{};
    final attendanceSummary =
        (summary['attendance_summary'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final sortedDates = (summary['sorted_dates'] as List<dynamic>?) ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Reports'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          TextButton(onPressed: widget.onLogout, child: const Text('Logout')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openExport,
        icon: const Icon(Icons.download),
        label: const Text('Export Excel'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatCard(label: 'Students', value: '${summary['total_students'] ?? 0}'),
              _StatCard(label: 'Subjects', value: '${summary['total_subjects'] ?? 0}'),
              _StatCard(label: 'Attendance', value: '${summary['total_attendance'] ?? 0}'),
              _StatCard(label: 'Days', value: '${sortedDates.length}'),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedDates.map((date) {
            final subjects =
                (attendanceSummary[date] as Map<String, dynamic>?) ?? const <String, dynamic>{};
            return Card(
              child: ExpansionTile(
                title: Text(date.toString()),
                children: subjects.entries.map((entry) {
                  final records = (entry.value as List<dynamic>?) ?? const [];
                  return ExpansionTile(
                    title: Text('${entry.key} (${records.length})'),
                    children: records.map((rawRecord) {
                      final record = rawRecord as Map<String, dynamic>;
                      return ListTile(
                        dense: true,
                        title: Text(record['student_name']?.toString() ?? '-'),
                        subtitle: Text('Roll ${record['roll_number']} • ${record['time']}'),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
