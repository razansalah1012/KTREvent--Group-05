class ProfileTranslations {
  static const Map<String, Map<String, String>> strings = {
    'en': {
      'my_profile': 'My Profile',
      'manage_account': 'Manage your account and preferences',
      'edit_profile': 'Edit Profile',
      'update_personal_info': 'Update your personal information',
      'my_certificates': 'My Certificates',
      'view_download_cert': 'View and download certificates',
      'change_password': 'Change Password',
      'update_password': 'Update your account password',
      'notification_preferences': 'Notification Preferences',
      'manage_notifications': 'Manage how you receive notifications',
      'privacy_security': 'Privacy & Security',
      'manage_privacy': 'Manage your privacy settings',
      'help_support': 'Help & Support',
      'get_help': 'Get help and contact support',
      'language': 'Language',
      'change_language': 'Change app language preference',
      'logout': 'Logout',
      'sign_out': 'Sign out from your account',
      'points': 'Points',
      'bookings': 'Bookings',
      'equipment': 'Equipment',
      'alerts': 'Alerts',
      'account_overview': 'Account Overview',
      'view_details': 'View Details',
    },
    'ms': {
      'my_profile': 'Profil Saya',
      'manage_account': 'Urus akaun dan tetapan anda',
      'edit_profile': 'Sunting Profil',
      'update_personal_info': 'Kemas kini maklumat peribadi anda',
      'my_certificates': 'Sijil Saya',
      'view_download_cert': 'Lihat dan muat turun sijil',
      'change_password': 'Tukar Kata Laluan',
      'update_password': 'Kemas kini kata laluan akaun anda',
      'notification_preferences': 'Tetapan Pemberitahuan',
      'manage_notifications': 'Urus bagaimana anda menerima pemberitahuan',
      'privacy_security': 'Privasi & Keselamatan',
      'manage_privacy': 'Urus tetapan privasi anda',
      'help_support': 'Bantuan & Sokongan',
      'get_help': 'Dapatkan bantuan dan hubungi sokongan',
      'language': 'Bahasa',
      'change_language': 'Tukar tetapan bahasa aplikasi',
      'logout': 'Log Keluar',
      'sign_out': 'Log keluar dari akaun anda',
      'points': 'Mata',
      'bookings': 'Tempahan',
      'equipment': 'Peralatan',
      'alerts': 'Makluman',
      'account_overview': 'Gambaran Keseluruhan Akaun',
      'view_details': 'Lihat Butiran',
    },
  };

  static String get(String langCode, String key) {
    if (strings.containsKey(langCode) && strings[langCode]!.containsKey(key)) {
      return strings[langCode]![key]!;
    }
    return strings['en']![key] ?? key;
  }
}
