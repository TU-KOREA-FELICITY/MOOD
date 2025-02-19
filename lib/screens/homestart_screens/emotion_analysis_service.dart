import 'dart:convert';
import 'package:http/http.dart' as http;

class EmotionAnalysisService {
  static final EmotionAnalysisService _instance =
      EmotionAnalysisService._internal();

  factory EmotionAnalysisService() {
    return _instance;
  }

  EmotionAnalysisService._internal();

  late int _userId;

  void setUserInfo(int userId) {
    _userId = userId;
  }

  final Map<String, String> _emotionTranslations = {
    'ANGRY': '분노',
    'HAPPY': '행복',
    'SURPRISED': '놀람',
    'DISGUSTED': '혐오',
    'CALM': '평온',
    'SAD': '슬픔',
    'CONFUSED': '혼란',
    'FEAR': '공포'
  };

  Future<Map<String, dynamic>> runEmotionAnalysis() async {
    final url = Uri.parse('http://10.0.2.2:3000/analyze_emotion');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final emotionResult = result['result'] ?? '';
        await saveEmotions(emotionResult);
        return {
          'success': true,
          'result': result['result'] ?? '',
          'status': '감정 분석 완료',
        };
      } else {
        return {
          'success': false,
          'status': '감정 분석 실패',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'status': '서버 연결 오류: $e',
      };
    }
  }

  Function(Map<String, dynamic>)? onTagsResultReceived;

  Future<void> saveEmotions(String emotionResult) async {
    List<String> emotions = getTopEmotions(emotionResult);
    final url = Uri.parse('http://10.0.2.2:3000/save_emotions');
    try {
      final translatedEmotions = emotions
          .map((emotion) => _emotionTranslations[emotion] ?? emotion)
          .join(',');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _userId,
          'emotions': translatedEmotions,
        }),
      );
      if (response.statusCode == 200) {
        print('감정 저장 성공');

        final tagsResult = await getEmotionTags(translatedEmotions);
        print(tagsResult);

        if (onTagsResultReceived != null) {
          onTagsResultReceived!(tagsResult);
        }
      } else {
        print('감정 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('감정 저장 중 오류 발생: $e');
    }
  }

  List<String> getTopEmotions(String emotionResult) {
    List<Map<String, dynamic>> emotionList = emotionResult
        .split('\n')
        .where((line) => line.contains(':'))
        .map((line) {
          final parts = line.split(': ');
          if (parts.length < 2) return null;
          return {
            'emotion': parts[0].trim(),
            'confidence': double.tryParse(parts[1].trim()) ?? 0.0,
          };
        })
        .where((item) => item != null)
        .cast<Map<String, dynamic>>()
        .toList();

    if (emotionList.isEmpty) {
      return [];
    }

    emotionList.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    return emotionList.take(3).map((e) => e['emotion'] as String).toList();
  }

  Future<Map<String, dynamic>> getEmotionTags(String detectedEmotions) async {
    final url = Uri.parse('http://10.0.2.2:3000/get_emotion_tags');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'detected_emotions': detectedEmotions}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return {'success': true, 'tags': data['tags']};
        } else {
          return {'success': false, 'message': data['message']};
        }
      } else {
        return {
          'success': false,
          'message': '서버 오류 발생 (${response.statusCode})'
        };
      }
    } catch (e) {
      print('API 요청 중 오류 발생: $e');
      return {'success': false, 'message': '네트워크 오류 발생'};
    }
  }
}
