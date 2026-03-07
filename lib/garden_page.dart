import 'dart:io';
import 'package:flutter/material.dart';
import 'databasehelper.dart';
import 'language_data.dart';
// ...existing code...

class GardenPage extends StatefulWidget {
  const GardenPage({super.key});

  @override
  State<GardenPage> createState() => _GardenPageState();
}

class _GardenPageState extends State<GardenPage> {
  List<Map<String, dynamic>> gardenPlants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGarden();
  }

  Future<void> _loadGarden() async {
    final data = await DatabaseHelper.instance.fetchGarden();
    setState(() {
      gardenPlants = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9), // Light Green Background
      appBar: AppBar(
        title: Text(
          LanguageData.currentLang == "ta" ? "எனது தோட்டம்" : "My Garden",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : gardenPlants.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: gardenPlants.length,
                  itemBuilder: (context, index) {
                    final plant = gardenPlants[index];
                    return _buildPlantCard(plant);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ignore: deprecated_member_use
          Icon(Icons.yard_outlined, size: 80, color: Colors.green.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            LanguageData.currentLang == "ta" ? "தோட்டம் காலியாக உள்ளது" : "Your garden is empty",
            style: TextStyle(color: Colors.green[800], fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(Map<String, dynamic> plant) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.file(
                    File(plant['imagePath']),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () async {
                      await DatabaseHelper.instance.deleteFromGarden(plant['id']);
                      _loadGarden();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant['plantNickname'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  plant['lastDisease'],
                  style: TextStyle(color: Colors.orange[900], fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}