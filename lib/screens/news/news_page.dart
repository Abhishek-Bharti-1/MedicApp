import 'package:flutter/material.dart';
import 'package:medicapp/screens/news/news_service.dart';
import 'package:url_launcher/url_launcher.dart';



class NewsScreen extends StatefulWidget {
  // final String apiKey;
  // const NewsScreen({required this.apiKey});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService newsService = NewsService();
// 6G1T-6MVX-DGX0-T4E4
  late Future<List<Article>> futureArticles;

  final List<Color> pastelColors = [
  Color(0xFFFFD1DC), // Pastel Pink
  Color(0xFFFFE7C9), // Pastel Peach
  Color(0xFFFFF5BA), // Pastel Yellow
  Color(0xFFB5EAD7), // Pastel Mint Green
  Color(0xFFB2E1FF), // Pastel Sky Blue
  Color(0xFFE2C2FF), // Pastel Lavender
  Color(0xFFFFC8DD), // Pastel Rose
  Color(0xFFFFDEB4), // Pastel Apricot
];

 _launchURL(url_1) async {
   final Uri url = Uri.parse('$url_1');
   if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
    }
}

  @override
  void initState() {
    super.initState();
    futureArticles = newsService.getTopHeadlines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("News Articles"),),
      body: 
    Center(
      child: FutureBuilder<List<Article>>(
          future: futureArticles,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.all(10),
                     decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),color: pastelColors[index%pastelColors.length],),
                     
                    child: InkWell(
                      
                      onTap: (){
                        _launchURL(snapshot.data![index].url);
                      },
                      child: Container(
                       
                        padding: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                                width: double.infinity,
                                child: Image.network(snapshot.data![index].image,fit: BoxFit.fill,)),
                            ),
                            SizedBox(height: 5,),
                            Text(snapshot.data![index].title,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
                            ListTile(
                            
                              subtitle: Text(snapshot.data![index].description),
                            ),
                            Text('Click to read more')
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
    ));
  }
}