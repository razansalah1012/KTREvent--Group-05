import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/participation_service.dart';

class FeedbackScreen extends StatefulWidget {
  final String participationId;
  final String eventTitle;

  const FeedbackScreen({super.key, required this.participationId, required this.eventTitle});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();
  final ParticipationService _service = ParticipationService();
  
  double _rating = 5.0;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _service.submitFeedback(
        widget.participationId, 
        _feedbackController.text.trim(), 
        _rating
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback submitted!')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate: ${widget.eventTitle}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF241b3d),
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF110d27), Color(0xFF1e1533), Color(0xFF2a2147)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('How was your experience?', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 16),
                Slider(
                  value: _rating,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: const Color(0xFF8257E5),
                  label: _rating.toString(),
                  onChanged: (val) => setState(() => _rating = val),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _feedbackController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Leave a comment',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8257E5))),
                  ),
                  validator: (val) => val!.isEmpty ? 'Please enter some feedback' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8257E5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Submit Feedback', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}