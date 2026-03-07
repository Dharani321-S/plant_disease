import 'package:flutter/material.dart';
import 'language_data.dart';

class CropSchedulePage extends StatelessWidget {
  const CropSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isTamil = LanguageData.currentLang == "ta";

    // Tomato Schedule Data
    final tomatoSchedule = [
      {"day": "1-15", "task": isTamil ? "அடி உரம் (DAP/Potash) மற்றும் நடவு" : "Base Fertilizer (DAP/Potash) & Planting"},
      {"day": "25-30", "task": isTamil ? "முதல் மேலுரம் (Urea) மற்றும் களை எடுத்தல்" : "First Top Dressing (Urea) & Weeding"},
      {"day": "45-50", "task": isTamil ? "பூக்கும் பருவம் (Micronutrients) தெளித்தல்" : "Flowering Stage (Micronutrients Spray)"},
      {"day": "60-70", "task": isTamil ? "காய் பிடிக்கும் பருவம் (Potash) இடவும்" : "Fruiting Stage (Potash Application)"},
    ];

    // Potato Schedule Data
    final potatoSchedule = [
      {"day": "1-10", "task": isTamil ? "அடி உரம் மற்றும் கிழங்கு நடுதல்" : "Base Fertilizer & Tuber Planting"},
      {"day": "30-35", "task": isTamil ? "மண் அணைத்தல் (Earthing up) மற்றும் Urea" : "Earthing up & Urea Application"},
      {"day": "50-60", "task": isTamil ? "கிழங்கு பெருக்கும் பருவம் (SOP/MOP)" : "Tuber Bulking Stage (SOP/MOP)"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text(
          LanguageData.getText('crop_schedule'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildScheduleCard(
              context, 
              isTamil ? "தக்காளி (Tomato)" : "Tomato", 
              Icons.agriculture, 
              tomatoSchedule
            ),
            const SizedBox(height: 20),
            _buildScheduleCard(
              context, 
              isTamil ? "உருளைக்கிழங்கு (Potato)" : "Potato", 
              Icons.layers, 
              potatoSchedule
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, String title, IconData icon, List<Map<String, String>> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // ignore: deprecated_member_use
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Color(0xFF388E3C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Table(
              columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2.5)},
              border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1)),
              children: [
                TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), child: Text(LanguageData.getText('day'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), child: Text(LanguageData.getText('fertilizer'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  ],
                ),
                ...data.map((item) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(12), child: Text(item['day']!, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: const EdgeInsets.all(12), child: Text(item['task']!)),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}