import '../services/role_service.dart';

final role = RoleService.getRole(emailText);

if (role == "admin") {
  Navigator.pushReplacementNamed(context, '/admin');
} else {
  Navigator.pushReplacementNamed(context, '/home');
}
