import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/screens/doctor/doctor_home_screen.dart';
import 'package:yoltec_mobile/screens/student/student_home_screen.dart';
import 'package:yoltec_mobile/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return const SizedBox.shrink();

    if (user.esDoctor) {
      return const DoctorHomeScreen();
    }
    return const StudentHomeScreen();
  }
}
