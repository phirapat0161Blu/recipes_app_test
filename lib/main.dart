import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recipes from API',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class Recipes {
  final int id;
  final String name;

  Recipes({required this.id, required this.name});

  factory Recipes.fromJson(Map<String, dynamic> json) {
    return Recipes(id: json['id'], name: json['name']);
  }
}

class RecipesService {
  static const String apiUrl = 'https://dummyjson.com/recipes';
  static List<Recipes>? _cachedRepices;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static Future<List<Recipes>> fetchRecipes() async {
    if (_cachedRepices != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedRepices!;
    }

    try {
      final response = await http
          .get(Uri.parse(apiUrl), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> recipesJson = data['recipes'];

        _cachedRepices = recipesJson
            .map((json) => Recipes.fromJson(json))
            .toList();
        _cacheTime = DateTime.now();
        return _cachedRepices!;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timeout');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static void clearCache() {
    _cachedRepices = null;
    _cacheTime = null;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Recipes>>(
        future: RecipesService.fetchRecipes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(child: CircularProgressIndicator()),
                SizedBox(height: 16),
                Text(
                  'กำลังโหลดข้อมูล...',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ); // Loading state
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No products found'), // Empty state
            ); // Empty state
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final recipes = snapshot.data![index];
              return Text(
                '${recipes.id} - ${recipes.name}',
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ); //ProductCard(key: ValueKey(product.id), product: product);
            },
          ); //ListView.builder(); // Success state
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
