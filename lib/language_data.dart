class LanguageData {
  static String currentLang = "ta"; // Default: Tamil

  static const Map<String, Map<String, String>> localizedStrings = {
    "en": {
      "scan_title": "Scan Plant Leaf",
      "camera": "Camera",
      "gallery": "Gallery",
      "history": "History",
      "result": "Detection Result:",
      "treatment": "Recommended Treatment:",
      "speak": "Hear Treatment",
      "retake": "Scan Again",
      "no_history": "No history found.",
      "app_title": "Plant AI Detector",
      "crop_schedule": "Crop Calendar", // 👈 Inga sethutten
      "day": "Day",
      "fertilizer": "Fertilizer / Task",
    },
    "ta": {
      "scan_title": "பயிர் இலையை ஸ்கேன் செய்யவும்",
      "camera": "கேமரா",
      "gallery": "கேலரி",
      "history": "வரலாறு",
      "result": "கண்டறியப்பட்ட நிலை:",
      "treatment": "பரிந்துரைக்கப்படும் சிகிச்சை:",
      "speak": "தீர்வை குரலில் கேட்க",
      "retake": "மீண்டும் ஸ்கேன் செய்ய",
      "no_history": "வரலாறு ஏதும் இல்லை.",
      "app_title": "பயிர் நோய் கண்டறிதல்",
      "crop_schedule": "பயிர் காலண்டர்", // 👈 Inga sethutten
      "day": "நாள்",
      "fertilizer": "உரம் / வேலை",
    }
  };

  static String getText(String key) {
    return localizedStrings[currentLang]?[key] ?? key;
  }
}