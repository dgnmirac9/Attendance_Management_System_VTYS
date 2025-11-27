import 'package:flutter/material.dart';
import '../../../../shared/utils/snackbar_utils.dart';

class ClassDetailsScreen extends StatefulWidget {
  final String className;
  final String classCode;
  final String teacherName;

  const ClassDetailsScreen({
    super.key,
    required this.className,
    required this.classCode,
    required this.teacherName,
  });

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.className,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 3.0,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.class_,
                      size: 80,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    SnackbarUtils.showInfo(context, "Sınıf ayarları yakında eklenecek.");
                  },
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                  indicatorColor: theme.colorScheme.primary,
                  tabs: const [
                    Tab(icon: Icon(Icons.qr_code_scanner), text: "Yoklama"),
                    Tab(icon: Icon(Icons.people), text: "Öğrenciler"),
                    Tab(icon: Icon(Icons.history), text: "Geçmiş"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAttendanceTab(context),
            _buildStudentsTab(context),
            _buildHistoryTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2, size: 100, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(
            "Yoklama İşlemleri",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              SnackbarUtils.showInfo(context, "Yoklama başlatma özelliği eklenecek.");
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text("Yoklama Başlat"),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab(BuildContext context) {
    // Dummy data
    final students = List.generate(10, (index) => "Öğrenci ${index + 1}");

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: students.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(students[index][0]),
            ),
            title: Text(students[index]),
            subtitle: const Text("2023123456"),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    return Center(
      child: Text(
        "Geçmiş Yoklamalar Burada Listelenecek",
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
