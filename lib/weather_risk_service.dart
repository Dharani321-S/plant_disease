import 'package:flutter/material.dart';

class WeatherRiskService {
  // Logic to determine risk message based on humidity and disease
  static String getRiskMessage(double humidity, String diseaseKey, String lang) {
    bool isTa = lang == "ta";
    
    if (diseaseKey.toLowerCase().contains("healthy")) {
      return isTa ? "செடி பாதுகாப்பாக உள்ளது." : "Plant is safe.";
    }

    if (humidity > 80) {
      return isTa 
          ? "அதிக அபாயம்: அதிக ஈரப்பதம் நோய் பரவலைத் தூண்டும்!" 
          : "High Risk: High humidity triggers faster spread!";
    } else if (humidity > 50) {
      return isTa 
          ? "மிதமான அபாயம்: ஈரப்பதம் ஓரளவிற்கு உள்ளது." 
          : "Moderate Risk: Humidity is at average levels.";
    } else {
      return isTa 
          ? "குறைவான அபாயம்: வறண்ட வானிலை நோய் பரவலைத் தடுக்கும்." 
          : "Low Risk: Dry weather prevents disease spread.";
    }
  }

  // Logic to return color based on risk level
  static Color getRiskColor(double humidity) {
    if (humidity > 80) return Colors.redAccent;
    if (humidity > 50) return Colors.orangeAccent;
    return Colors.lightGreenAccent;
  }
}