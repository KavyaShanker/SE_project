// ignore_for_file: use_build_context_synchronously, unused_local_variable, must_be_immutable

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

String globalUsername = '';
//Backend shiz----------------------------------------------------------------

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future main() async {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    runApp(const SignUpApp());
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI
    sqfliteFfiInit();

    // Set the databaseFactory to use sqflite_common_ffi
    databaseFactory = databaseFactoryFfi;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'kav_database_SE.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstName TEXT,
        lastName TEXT,
        username TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE search_queries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT
      )
    ''');
  }

  // Implement functions for CRUD operations here
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<void> insertSearchItem(SearchItem searchItem) async {
    final db = await database;
    await db.insert('search_queries', searchItem.toMap());
  }

  Future<List<SearchItem>> getRecentSearches() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('search_queries');
    return List.generate(maps.length, (index) {
      return SearchItem.fromMap(maps[index]);
    });
  }
}

//------------------------------------------------------------------------------
void main() => runApp(const SignUpApp());

class SignUpApp extends StatelessWidget {
  const SignUpApp();

  Future<bool> isUserRegistered(String username) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      columns: ['username'], // Specify the columns you want to retrieve
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder<bool>(
              future: isUserRegistered(globalUsername),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // You can display a loading indicator while checking.
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return snapshot.data == true
                      ? WelcomeScreen()
                      : SignUpScreen(isUserRegistered: isUserRegistered);
                }
              },
            ),
        '/welcome': (context) => const WelcomeScreen(),
        '/playlist': (context) => PlaylistPage(),
        '/additionalInfoForm': (context) =>
            AdditionalInfoForm(), // Define the additional info form route
      },
    );
  }
}

class User {
  final String firstName;
  final String lastName;
  final String username;

  User({
    required this.firstName,
    required this.lastName,
    required this.username,
  });

  // Convert a User object to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
    };
  }

  // Create a User object from a map retrieved from the database
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      firstName: map['firstName'],
      lastName: map['lastName'],
      username: map['username'],
    );
  }
}

Future<User> getUserById(int id) async {
  final db = await DatabaseHelper.instance.database;
  final List<Map<String, dynamic>> maps = await db.query(
    'users',
    where: 'id = ?',
    whereArgs: [id],
  );

  if (maps.isNotEmpty) {
    return User.fromMap(maps.first);
  } else {
    throw Exception('User not found');
  }
}

class SearchItem {
  final String query;

  SearchItem({required this.query});

  // Convert a SearchItem object to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      'query': query,
    };
  }

  // Create a SearchItem object from a map retrieved from the database
  factory SearchItem.fromMap(Map<String, dynamic> map) {
    return SearchItem(
      query: map['query'],
    );
  }
}

class HomeScreen extends StatelessWidget {
  HomeScreen();

  final queryController = TextEditingController();
  // double _searchState = 0;
  //final Database db;

  Future<void> saveSearchQuery(String query) async {
    if (query.isNotEmpty) {
      final searchItem = SearchItem(query: query);
      await DatabaseHelper.instance.insertSearchItem(searchItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Music Platform'),
      ),
      body: Row(
        children: <Widget>[
          // Left side content
          Expanded(
            child: Column(
              children: <Widget>[
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: queryController,
                    decoration: const InputDecoration(
                      hintText: 'Search for music...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onEditingComplete: () {
                      saveSearchQuery(queryController.text);
                    },
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 20),
                      // Genres
                      GestureDetector(
                        onTap: () {
                          // do something
                        },
                        child: _genreBox("Classical"),
                      ),
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          // do something pt2
                        },
                        child: _genreBox("Rock"),
                      ),
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          // do something pt3
                        },
                        child: _genreBox("Bollywood"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right side content (Recent Searches)
          // Right side content (Recent Searches)
          Container(
            width: 500, // Adjust the width as needed
            color: Colors
                .grey[200], // Background color for the Recent Searches column
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<List<SearchItem>>(
              future: DatabaseHelper.instance.getRecentSearches(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // You can show a loading indicator here.
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final recentSearches = snapshot.data;
                  if (recentSearches != null && recentSearches.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Searches',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: recentSearches.map((search) {
                            return Text(search.query);
                          }).toList(),
                        ),
                      ],
                    );
                  } else {
                    return Text('No recent searches found.');
                  }
                }
              },
            ),
          )
        ],
      ),
    );
  }
  }

Widget _genreBox(String genreName) {
  return Container(
    width: 100, // Adjust the size as needed
    height: 100, // Adjust the size as needed
    decoration: BoxDecoration(
      color: Colors.blue, // Change the color as needed
      borderRadius: BorderRadius.circular(10),
    ),
    child: Center(
      child: Text(
        genreName,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}


class SettingsScreen extends StatelessWidget {
  const SettingsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          ListTile(
            title: Text('Profile Settings'),
            subtitle: Text('Update your profile information'),
            leading: Icon(Icons.person),
            onTap: () {
              // Navigate to the profile settings screen.
            },
          ),
          Divider(),
          ListTile(
            title: Text('Theme Settings'),
            subtitle: Text('Customize the app\'s appearance'),
            leading: Icon(Icons.color_lens),
            onTap: () {
              // Navigate to the theme settings screen.
            },
          ),
          Divider(),
          ListTile(
            title: Text('Notification Settings'),
            subtitle: Text('Manage notification preferences'),
            leading: Icon(Icons.notifications),
            onTap: () {
              // Navigate to the notification settings screen.
            },
          ),
          // Add more ListTile widgets for other settings.
        ],
      ),
    );
  }
}

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 80,
              backgroundImage: AssetImage(
                  'assets/images/placeholder_pfp.png'), // Load the image from the asset
            ),
            SizedBox(height: 50),
            Text(
              globalUsername,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 50),
            Text(
              globalUsername,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends StatelessWidget {
  final Future<bool> Function(String username)
      isUserRegistered; // Add this parameter
  const SignUpScreen({required this.isUserRegistered});

  void registerUser(User user, BuildContext context) async {
    final result = await DatabaseHelper.instance.insertUser(user);
    // if (result != null) {
    Navigator.of(context).pushNamed('/welcome');
    // } else {
    //   // Handle registration failure
    // }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            child: SignUpForm(isUserRegistered: isUserRegistered),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PlaylistPage(),
    );
  }
}

class PlaylistPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Playlist'),
      ),
      body: ListView(
        children: <Widget>[
          SongItem('Song 1'),
          SongItem('Song 2'),
          SongItem('Song 3'),
          // Add more SongItem widgets for additional songs
        ],
      ),
    );
  }
}

class SongItem extends StatelessWidget {
  final String songTitle;
  // final audioPlayer = AudioPlayer();

  SongItem(this.songTitle);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.music_note),
        title: Text(songTitle),
        onTap: () {
          // Implement what happens when a song is tapped
        },
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen();

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(), // Pass the database instance to HomeScreen
    UserProfileScreen(),
    PlaylistPage(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
      ),
      body: _screens.isNotEmpty
          ? _screens[_selectedIndex]
          : CircularProgressIndicator(), // Add loading indicator
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon:
                Icon(Icons.queue_music), // Add an appropriate icon for Playlist
            label: 'Playlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class SignUpForm extends StatefulWidget {
  final Future<bool> Function(String username)
      isUserRegistered; // Add the parameter

  const SignUpForm({required this.isUserRegistered});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _firstNameTextController = TextEditingController();
  final _lastNameTextController = TextEditingController();
  final _usernameTextController = TextEditingController();

  double _formProgress = 0;

  void _showWelcomeScreen(BuildContext context) async {
    final user = User(
      firstName: _firstNameTextController.text,
      lastName: _lastNameTextController.text,
      username: _usernameTextController.text,
    );

    globalUsername = user.username;
    // final result = await DatabaseHelper.instance.insertUser(user);
    final isRegistered = await widget.isUserRegistered(globalUsername);

    if (isRegistered) {
      Navigator.of(context).pushNamed('/welcome');
      // Navigator.of(context).push(
      //   MaterialPageRoute(builder: (context) => UserProfileScreen()),
      // );
    } else {
      Navigator.of(context).pushNamed('/additionalInfoForm');
    }
  }

  void _updateFormProgress() {
    var progress = 0.0;
    final controllers = [
      _firstNameTextController,
      _lastNameTextController,
      _usernameTextController
    ];

    for (final controller in controllers) {
      if (controller.value.text.isNotEmpty) {
        progress += 1 / controllers.length;
      }
    }

    setState(() {
      _formProgress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      onChanged: _updateFormProgress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _formProgress),
          Text('Sign up', style: Theme.of(context).textTheme.headlineMedium),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              controller: _firstNameTextController,
              decoration: const InputDecoration(hintText: 'First name'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              controller: _lastNameTextController,
              decoration: const InputDecoration(hintText: 'Last name'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              controller: _usernameTextController,
              decoration: const InputDecoration(hintText: 'Username'),
            ),
          ),
          TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.resolveWith(
                  (Set<MaterialState> states) {
                return states.contains(MaterialState.disabled)
                    ? null
                    : const Color.fromARGB(255, 25, 19, 19);
              }),
              backgroundColor: MaterialStateProperty.resolveWith(
                  (Set<MaterialState> states) {
                return states.contains(MaterialState.disabled)
                    ? null
                    : Colors.blue;
              }),
            ),
            onPressed:
                _formProgress == 1 ? () => _showWelcomeScreen(context) : null,
            child: const Text('Sign up'),
          ),
        ],
      ),
    );
  }
}

class AdditionalInfoForm extends StatefulWidget {
  @override
  _AdditionalInfoFormState createState() => _AdditionalInfoFormState();
}

class _AdditionalInfoFormState extends State<AdditionalInfoForm> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _usernameController = TextEditingController();
  final _paymentPlanController = TextEditingController();

  void _submitForm(BuildContext context) async {
    // Process the input data, save it, and navigate to the welcome screen
    final email = _emailController.text;
    final name = _nameController.text;
    final uname = _usernameController.text;
    final age = _ageController.text;
    final paymentPlan = _paymentPlanController.text;

    // Save the additional information to your database or wherever it's needed
    final user = User(
      firstName: name.substring(0, name.indexOf(" ")),
      lastName: name.substring(name.indexOf(" ") + 1, name.length),
      username: uname,
    );

    final result = await DatabaseHelper.instance.insertUser(user);

    // if (result != null) {
    //   // Navigate to the welcome screen
    Navigator.of(context).pushNamed('/welcome');
    // } else {
    //   //handle failure
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Additional Information Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(hintText: 'Email'),
            ),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(hintText: 'Name'),
            ),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(hintText: 'Username'),
            ),
            TextFormField(
              controller: _ageController,
              decoration: InputDecoration(hintText: 'Age'),
            ),
            TextFormField(
              controller: _paymentPlanController,
              decoration: InputDecoration(hintText: 'Payment Plan'),
            ),
            ElevatedButton(
              onPressed: () => _submitForm(context),
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
