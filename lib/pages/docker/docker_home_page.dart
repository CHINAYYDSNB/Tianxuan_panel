import 'package:flutter/material.dart';
import 'container_list_page.dart';
import 'image_list_page.dart';
import 'compose_list_page.dart';
import 'app_store_page.dart';
import 'installed_list_page.dart';

class DockerHomePage extends StatefulWidget {
  const DockerHomePage({super.key});

  @override
  State<DockerHomePage> createState() => _DockerHomePageState();
}

class _DockerHomePageState extends State<DockerHomePage>
    with SingleTickerProviderStateMixin {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('容器管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            tooltip: '应用商店',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const AppStorePage(),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: '已安装',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const InstalledListPage(),
            )),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.view_in_ar), text: '容器'),
            Tab(icon: Icon(Icons.image), text: '镜像'),
            Tab(icon: Icon(Icons.dns), text: 'Compose'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ContainerListPage(),
          ImageListPage(),
          ComposeListPage(),
        ],
      ),
    );
  }
}

