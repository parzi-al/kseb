import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Firebase and Local Auth instances
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  String _workerName = 'Loading...';
  int _daysPresent = 0;
  final int _totalDays = 240; // Can be fetched from a config document if needed
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchWorkerData();
  }

  /// Fetches worker's name and attendance count from Firestore.
  Future<void> _fetchWorkerData() async {
    setState(() {
      _isLoading = true;
    });

    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      _userId = user.uid;
      try {
        // Fetch worker profile document
        DocumentSnapshot workerDoc = await _firestore
            .collection('workers')
            .doc(_userId)
            .get();

        if (workerDoc.exists) {
          final data = workerDoc.data() as Map<String, dynamic>?;
          _workerName = data?['name'] ?? user.email ?? 'No name found';
        } else {
          _workerName = user.email ?? 'No name found';
        }

        // Fetch attendance records
        QuerySnapshot attendanceSnapshot = await _firestore
            .collection('workers')
            .doc(_userId)
            .collection('attendance')
            .get();

        _daysPresent = attendanceSnapshot.docs.length;
      } catch (e) {
        _workerName = "Error loading data";
        _daysPresent = 0;
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
        }
      }
    } else {
      _workerName = "Not Logged In";
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Authenticates with biometrics and then records attendance.
  Future<void> _authenticateAndMarkAttendance() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to mark attendance',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // Use only biometrics (fingerprint, face ID)
        ),
      );
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
      return;
    }

    if (!mounted) return;

    if (authenticated) {
      await _recordAttendance();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fingerprint authentication failed.')),
      );
    }
  }

  /// Records an attendance entry in Firestore for the current day.
  Future<void> _recordAttendance() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final attendanceCollection = _firestore
        .collection('workers')
        .doc(_userId)
        .collection('attendance');

    // Check if attendance was already marked today to prevent duplicates
    final querySnapshot = await attendanceCollection
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where(
          'timestamp',
          isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))),
        )
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance already marked for today.')),
      );
    } else {
      // Add a new attendance record with a server timestamp
      await attendanceCollection.add({
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance Marked Successfully!')),
      );
      // Refresh the data on screen after marking attendance
      await _fetchWorkerData();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double attendancePercentage = _totalDays > 0
        ? (_daysPresent / _totalDays)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Attendance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _workerName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: CircularPercentIndicator(
                      radius: 100.0,
                      lineWidth: 12.0,
                      percent: attendancePercentage,
                      center: Text(
                        "${(attendancePercentage * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24.0,
                        ),
                      ),
                      footer: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          "$_daysPresent / $_totalDays Days present",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: Colors.teal,
                      backgroundColor: Colors.teal.shade100,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Punch in with Fingerprint'),
                    onPressed: _authenticateAndMarkAttendance,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
