import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rick and Morty',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), useMaterial3: true),
      home: const CharactersGridPage(),
    );
  }
}

class Origin {
  final String name;
  final String url;

  Origin({required this.name, required this.url});

  factory Origin.fromJson(Map<String, dynamic> json) {
    return Origin(name: json['name'] ?? 'unknown', url: json['url'] ?? '');
  }
}

class Location {
  final String name;
  final String url;

  Location({required this.name, required this.url});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(name: json['name'] ?? 'unknown', url: json['url'] ?? '');
  }
}

class Character {
  final int id;
  final String name;
  final String status;
  final String species;
  final String type;
  final String gender;
  final Origin origin;
  final Location location;
  final String image;
  final List<String> episode;
  final String url;
  final String created;

  Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.type,
    required this.gender,
    required this.origin,
    required this.location,
    required this.image,
    required this.episode,
    required this.url,
    required this.created,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      status: json['status'] ?? 'unknown',
      species: json['species'] ?? 'unknown',
      type: json['type'] ?? '',
      gender: json['gender'] ?? 'unknown',
      origin: Origin.fromJson(json['origin'] ?? {}),
      location: Location.fromJson(json['location'] ?? {}),
      image: json['image'] ?? '',
      episode: List<String>.from(json['episode'] ?? []),
      url: json['url'] ?? '',
      created: json['created'] ?? '',
    );
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'alive':
        return Colors.green;
      case 'dead':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class CharactersResponse {
  final Info info;
  final List<Character> results;

  CharactersResponse({required this.info, required this.results});

  factory CharactersResponse.fromJson(Map<String, dynamic> json) {
    return CharactersResponse(
      info: Info.fromJson(json['info'] ?? {}),
      results: (json['results'] as List<dynamic>?)?.map((item) => Character.fromJson(item)).toList() ?? [],
    );
  }
}

class Info {
  final int count;
  final int pages;
  final String? next;
  final String? prev;

  Info({required this.count, required this.pages, this.next, this.prev});

  factory Info.fromJson(Map<String, dynamic> json) {
    return Info(count: json['count'] ?? 0, pages: json['pages'] ?? 0, next: json['next'], prev: json['prev']);
  }
}

class CharactersGridPage extends StatefulWidget {
  const CharactersGridPage({super.key});

  @override
  State<CharactersGridPage> createState() => _CharactersGridPageState();
}

class _CharactersGridPageState extends State<CharactersGridPage> {
  final Dio _dio = Dio();
  List<Character> _characters = [];
  bool _cargando = true;
  String? _error;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarPersonajes();
  }

  Future<void> _cargarPersonajes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final response = await _dio.get('https://rickandmortyapi.com/api/character');

      if (response.statusCode == 200) {
        final data = CharactersResponse.fromJson(response.data);

        setState(() {
          _characters = data.results;
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar personajes: $e';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Rick and Morty Characters'),
      ),
      body: _cargando && _characters.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _characters.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _cargarPersonajes, child: const Text('Reintentar')),
                ],
              ),
            )
          : _characters.isEmpty
          ? const Center(child: Text('No se encontraron personajes'))
          : Column(
              children: [
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Buscar personaje'),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final filteredCharacters = _characters
                          .where((character) => character.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                          .toList();
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: filteredCharacters.length,
                        itemBuilder: (context, index) {
                          final character = filteredCharacters[index];

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                        child: Image.network(
                                          character.image,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.error, size: 50),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: character.statusColor.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            character.status,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
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
                                        character.name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        character.species,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
