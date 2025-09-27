import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorksheetScreen extends StatefulWidget {
  const WorksheetScreen({super.key});

  @override
  State<WorksheetScreen> createState() => _WorksheetScreenState();
}

class _WorksheetScreenState extends State<WorksheetScreen> {
  // --- State & Controllers ---
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  bool _isLoading = false;

  // Form controllers to manage text field data
  final _workTypeController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _permitBookController = TextEditingController();
  final _locationController = TextEditingController();
  final _moreInfoController = TextEditingController();

  // Variables for dropdowns
  String? _selectedOffice;
  String? _selectedProject;

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed.
    _workTypeController.dispose();
    _projectNameController.dispose();
    _permitBookController.dispose();
    _locationController.dispose();
    _moreInfoController.dispose();
    super.dispose();
  }

  // --- Functions ---
  Future<void> _submitWorksheet() async {
    // Validate the form before proceeding
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      // Prepare the data to be saved
      final worksheetData = {
        'submittedByUid': user.uid,
        'submittedByEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
        'office': _selectedOffice,
        'workType': _workTypeController.text,
        'projectSelection': _selectedProject,
        'projectName': _projectNameController.text,
        'permitBook': _permitBookController.text,
        'location': _locationController.text,
        'moreInfo': _moreInfoController.text,
        'photoUrl': null, // TODO: Add logic to upload photo and get URL
      };

      // Add a new document with a generated ID to the 'worksheets' collection
      await FirebaseFirestore.instance
          .collection('worksheets')
          .add(worksheetData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worksheet Submitted Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back to the previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit worksheet: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Worksheet'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProjectDetailsCard(),
                    const SizedBox(height: 24),
                    _buildDocumentationCard(),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submitWorksheet,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('SUBMIT WORKSHEET'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper widget for a section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Card for the first group of inputs
  Widget _buildProjectDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildSectionHeader('Project Details', Icons.business_center),
            DropdownButtonFormField<String>(
              value: _selectedOffice,
              validator: (value) =>
                  value == null ? 'Please select an office.' : null,
              decoration: const InputDecoration(
                labelText: 'Office Selection',
                prefixIcon: Icon(Icons.location_city),
              ),
              items: ['Office A', 'Office B', 'Office C']
                  .map(
                    (label) =>
                        DropdownMenuItem(value: label, child: Text(label)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedOffice = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _workTypeController,
              decoration: const InputDecoration(
                labelText: 'Work Type',
                prefixIcon: Icon(Icons.construction),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedProject,
              validator: (value) =>
                  value == null ? 'Please select a project.' : null,
              decoration: const InputDecoration(
                labelText: 'Project Selection',
                prefixIcon: Icon(Icons.assignment),
              ),
              items: ['Project X', 'Project Y', 'Project Z']
                  .map(
                    (label) =>
                        DropdownMenuItem(value: label, child: Text(label)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProject = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _projectNameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                prefixIcon: Icon(Icons.label_important_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card for the second group of inputs
  Widget _buildDocumentationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildSectionHeader('Documentation & Location', Icons.folder_copy),
            TextFormField(
              controller: _permitBookController,
              decoration: const InputDecoration(
                labelText: 'Permit Book',
                prefixIcon: Icon(Icons.book_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined, size: 28),
              label: const Text('Upload Photo', style: TextStyle(fontSize: 16)),
              onPressed: () {
                // TODO: Implement image picking and uploading functionality
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                alignment: Alignment.center,
                foregroundColor: Colors.teal,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _moreInfoController,
              decoration: const InputDecoration(
                labelText: 'Additional Information',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
