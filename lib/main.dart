import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:media_kit/media_kit.dart';
// تم تعديل الاستدعاءات هنا لتطابق اسم الباقة الجديد
import 'package:iptv_flutter/models/models.dart';
import 'package:iptv_flutter/services/api_service.dart';
import 'package:iptv_flutter/screens/player_screen.dart';

// Initialize the media player and run the app
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const ProviderScope(child: SmartersProApp()));
}

// ... (باقي الكود كما هو تماماً، فقط تأكد من تعديل الـ imports في البداية)
// سأضع لك الكود كاملاً للتأكد
class SmartersProApp extends StatelessWidget {
  const SmartersProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTV Smarters Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: const Color(0xFF0F0518),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0x33000000),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF7158E2),
          secondary: const Color(0xFF0097E6),
          background: const Color(0xFF0F0518),
        ),
        useMaterial3: true,
      ),
      home: const LoginGate(),
    );
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<Credentials?>>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<Credentials?>> {
  final ApiService _apiService;
  AuthNotifier(this._apiService) : super(const AsyncValue.loading()) {
    _loadInitialCredentials();
  }

  Future<void> _loadInitialCredentials() async {
    state = await AsyncValue.guard(() async {
      return await _apiService.loadCredentials();
    });
  }

  Future<void> signIn(String host, String username, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _apiService.login(host, username, password);
      return _apiService._credentials;
    });
  }

  void signOut() {
    _apiService.logout();
    state = const AsyncValue.data(null);
  }
}

class LoginGate extends ConsumerWidget {
  const LoginGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF7158E2))),
      ),
      error: (e, s) => LoginScreen(error: e.toString()),
      data: (credentials) {
        if (credentials != null) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends ConsumerWidget {
  final String? error;
  const LoginScreen({super.key, this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final hostController = TextEditingController();
    final userController = TextEditingController();
    final passController = TextEditingController();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color.fromARGB(255, 34, 18, 59), Color(0xFF0F0518)],
            stops: [0.0, 1.0],
            center: Alignment.topCenter,
            radius: 1.0,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
                ),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(FontAwesomeIcons.tv, color: Color(0xFF7158E2), size: 80),
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 24.0),
                      child: Text(
                        'IPTV SMARTERS PRO',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    _buildInput(hostController, 'http://domain.com:port', FontAwesomeIcons.server, isRTL: false),
                    const SizedBox(height: 16),
                    _buildInput(userController, 'اسم المستخدم', FontAwesomeIcons.user, isRTL: true),
                    const SizedBox(height: 16),
                    _buildInput(passController, 'كلمة المرور', FontAwesomeIcons.lock, isRTL: true, isPassword: true),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : () {
                        ref.read(authProvider.notifier).signIn(
                          hostController.text.trim(),
                          userController.text.trim(),
                          passController.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF7158E2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'خطأ: ${error!}',
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, {required bool isRTL, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        textAlign: isRTL ? TextAlign.right : TextAlign.left,
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: const Color(0xFF7158E2),
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 12.0),
            child: FaIcon(icon, color: Colors.white.withOpacity(0.4), size: 18),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('الرئيسية', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            icon: const FaIcon(FontAwesomeIcons.powerOff, color: Colors.red),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1a0b2e), Color(0xFF0f0518)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainCards(context),
              const SizedBox(height: 20),
              _buildShortcutCards(context),
              const SizedBox(height: 20),
              _buildHorizontalSection('جديد الأفلام المضافة'),
              _buildHorizontalSection('أحدث المسلسلات'),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMainCards(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.8,
      children: [
        _buildCategoryCard(context, 'البث المباشر', FontAwesomeIcons.tv, const Color(0xFF00CEC9), () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => ContentScreen(contentType: 'live')));
        }),
        _buildCategoryCard(context, 'الأفلام', FontAwesomeIcons.film, const Color(0xFFFD9644), () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => ContentScreen(contentType: 'vod')));
        }),
        _buildCategoryCard(context, 'المسلسلات', FontAwesomeIcons.video, const Color(0xFF6C5CE7), () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => ContentScreen(contentType: 'series')));
        }),
      ],
    );
  }
  
  Widget _buildShortcutCards(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: [
        _buildShortcut(context, 'المفضلة', FontAwesomeIcons.heart, Colors.red, () {}),
        _buildShortcut(context, 'السجل', FontAwesomeIcons.history, Colors.yellow, () {}),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildShortcut(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border(right: BorderSide(color: color, width: 4)),
        ),
        child: Row(
          children: [
            FaIcon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFF7158E2), width: 4)),
            ),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: NetworkImage('https://placehold.co/200x300/1e272e/white?text=Poster'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final categoriesProvider = FutureProvider.family<List<Category>, String>((ref, type) {
  return ref.watch(apiServiceProvider).fetchCategories(type);
});

final selectedCategoryProvider = StateProvider<Category?>((ref) => null);

final streamsProvider = FutureProvider.family<List<StreamItem>, String>((ref, contentType) async {
  final category = ref.watch(selectedCategoryProvider);
  if (category == null) {
    final categories = await ref.watch(categoriesProvider(contentType).future);
    if (categories.isNotEmpty) {
      Future.microtask(() => ref.read(selectedCategoryProvider.notifier).state = categories.first);
      return [];
    }
    return [];
  }
  return ref.watch(apiServiceProvider).fetchStreams(contentType, categoryId: category.categoryId);
});


class ContentScreen extends ConsumerWidget {
  final String contentType;
  const ContentScreen({super.key, required this.contentType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider(contentType));
    final streamsAsync = ref.watch(streamsProvider(contentType));
    final credentials = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          contentType == 'live' ? 'البث المباشر' : (contentType == 'vod' ? 'الأفلام' : 'المسلسلات'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Container(
              width: 120,
              color: Colors.black.withOpacity(0.4),
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7158E2))),
                error: (e, s) => Center(child: Text('خطأ', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))),
                data: (categories) => ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      title: Text(
                        category.categoryName,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                      onTap: () {
                        ref.read(selectedCategoryProvider.notifier).state = category;
                      },
                      selected: ref.watch(selectedCategoryProvider)?.categoryId == category.categoryId,
                      selectedColor: Colors.white,
                      selectedTileColor: const Color(0xFF0097E6).withOpacity(0.5),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: streamsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7158E2))),
                  error: (e, s) => Center(child: Text('خطأ في تحميل المحتوى', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))),
                  data: (streams) => GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.6,
                    ),
                    itemCount: streams.length,
                    itemBuilder: (context, index) {
                      final stream = streams[index];
                      return GestureDetector(
                        onTap: () {
                          if (credentials != null) {
                            final url = stream.getStreamUrl(credentials.host, credentials.username, credentials.password);
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => PlayerScreen(url: url, title: stream.name),
                            ));
                          }
                        },
                        child: StreamPosterCard(stream: stream),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StreamPosterCard extends StatelessWidget {
  final StreamItem stream;
  const StreamPosterCard({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              stream.streamIcon ?? stream.cover ?? 'https://placehold.co/200x300/1e272e/white?text=Poster',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1E272E),
                child: const Center(child: FaIcon(FontAwesomeIcons.image, color: Colors.white54, size: 30)),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8.0)),
              ),
              child: Text(
                stream.name,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
