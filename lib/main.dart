import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

// Main App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recipes from API',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 73, 67, 53)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Recipes from API'),
    );
  }
}

// Recipes Model
class Recipes {
  final int id;
  final String name;

  Recipes({required this.id, required this.name});

  factory Recipes.fromJson(Map<String, dynamic> json) {
    return Recipes(
      id: json['id'],
      name: json['name'],
    );
  }
}


class RecipesService {
  static const String apiUrl = 'https://dummyjson.com/recipes'; //  ดึงข้อมูลจาก API
  static List<Recipes>? _cachedRecipes;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static Future<List<Recipes>> fetchRecipes() async {
    if (_cachedRecipes != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedRecipes!;
    }

    try {
      final response = await http
          .get(Uri.parse(apiUrl), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> recipesJson = data['recipes'];

        _cachedRecipes = recipesJson.map((json) => Recipes.fromJson(json)).toList();
        _cacheTime = DateTime.now();
        return _cachedRecipes!;
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
    _cachedRecipes = null;
    _cacheTime = null;
  }
}

// Home Page
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Recipes>> _futureRecipes;

  @override
  void initState() {
    super.initState();
    _futureRecipes = RecipesService.fetchRecipes();
  }

  Future<void> _refresh() async {
    RecipesService.clearCache();
    setState(() {
      _futureRecipes = RecipesService.fetchRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Recipes>>(
          future: _futureRecipes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 10),
                    Text(
                      'เกิดข้อผิดพลาด: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('ไม่พบสูตรอาหาร'));
            }

            final recipes = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(recipe.id.toString()),
                    ),
                    title: Text(recipe.name),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
