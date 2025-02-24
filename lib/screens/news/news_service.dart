import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  // final String apiKey;
  final String baseUrl = 'https://gnews.io/api/v4/top-headlines?category=health&lang=en&q=epileptic%20care&';

  // NewsService(this.apiKey);

  Future<List<Article>> getTopHeadlines() async {
    final response = await http.get(Uri.parse('${baseUrl}apikey=16a02f4b5cb6215a98289a45fe798650'));
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['totalArticles'] >= 0) {
        final List<dynamic> articles = data['articles'];
        return articles.map((article) => Article.fromJson(article)).toList();
      } else {
        throw Exception('Failed to load top headlines');
      }
    } else {
      throw Exception('Failed to load top headlines');
    }
  }
}

class Article {
  final String title;
  final String description;
  final String content;
  final String url;
  final String image;
  final String publishedAt;
  // final String source;

  Article({
    required this.title, 
    required this.description,
    required this.content,
    required this.url,
    required this.image,
    required this.publishedAt,
    // required this.source,
    });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'],
      description: json['description'],
      content: json['content'],
      url: json['url'],
      image: json['image'],
      publishedAt: json['description'],
      // source: json['source'],
    );
  }
}