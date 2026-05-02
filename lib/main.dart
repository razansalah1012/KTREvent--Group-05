MaterialApp(
  initialRoute: '/login',
  routes: {
    '/login': (context) => const LoginPage(),
    '/home': (context) => const HomePage(),
    '/admin': (context) => const AdminPage(),
  },
);
