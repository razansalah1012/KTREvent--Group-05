class RoleService {
  static String getRole(String email) {
    if (email.contains("admin")) {
      return "admin";
    } else {
      return "student";
    }
  }
}
