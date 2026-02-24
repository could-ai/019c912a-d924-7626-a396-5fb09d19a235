import 'package:flutter/material.dart';
import '../models/dog.dart';
import '../data/mock_data.dart';
import '../widgets/dog_card.dart';
import 'matches_screen.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Dog> _dogs = [];
  final List<Dog> _matches = [];
  int _currentIndex = 0;
  
  // Swipe animation variables
  Offset _position = Offset.zero;
  bool _isDragging = false;
  double _angle = 0;
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _dogs = List.from(mockDogs);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
      // Calculate rotation angle based on x position
      _angle = (_position.dx / _screenSize.width) * 0.3;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    final status = _getStatus();
    
    if (status == SwipeStatus.like) {
      _swipeRight();
    } else if (status == SwipeStatus.dislike) {
      _swipeLeft();
    } else {
      _resetPosition();
    }
  }

  SwipeStatus? _getStatus() {
    final x = _position.dx;
    if (x >= 100) return SwipeStatus.like;
    if (x <= -100) return SwipeStatus.dislike;
    return null;
  }

  void _resetPosition() {
    setState(() {
      _position = Offset.zero;
      _angle = 0;
    });
  }

  void _swipeLeft() {
    // Pass
    setState(() {
      _position = Offset(-_screenSize.width * 1.5, 0);
      _angle = -0.5;
    });
    _nextCard();
  }

  void _swipeRight() {
    // Match
    setState(() {
      _position = Offset(_screenSize.width * 1.5, 0);
      _angle = 0.5;
    });
    
    // Add to matches
    if (_currentIndex < _dogs.length) {
      _matches.add(_dogs[_currentIndex]);
      _showMatchDialog(_dogs[_currentIndex]);
    }
    
    _nextCard();
  }

  Future<void> _nextCard() async {
    if (_currentIndex >= _dogs.length) return;

    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _currentIndex++;
      _resetPosition();
    });
  }

  void _showMatchDialog(Dog dog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('It\'s a Match!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(dog.imageUrl),
            ),
            const SizedBox(height: 16),
            Text('You and ${dog.name} want to walk!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Swiping'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchesScreen(matches: _matches),
                ),
              );
            },
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.pets, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text(
              'PawPals',
              style: TextStyle(
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_rounded, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchesScreen(matches: _matches),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentIndex < _dogs.length
                ? Stack(
                    children: [
                      // Next Card (Background)
                      if (_currentIndex + 1 < _dogs.length)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Transform.scale(
                            scale: 0.95,
                            child: DogCard(dog: _dogs[_currentIndex + 1]),
                          ),
                        ),
                      
                      // Current Card (Foreground)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final center = constraints.biggest.center(Offset.zero);
                              final angle = _angle * (pi / 180.0) * 20; // Convert to radians
                              
                              return Transform.translate(
                                offset: _position,
                                child: Transform.rotate(
                                  angle: angle,
                                  alignment: Alignment.bottomCenter,
                                  child: DogCard(
                                    dog: _dogs[_currentIndex],
                                    isFront: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Overlay indicators (Like/Nope)
                      if (_isDragging)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: (_position.dx.abs() / 150).clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: _position.dx > 0 
                                      ? Colors.green.withOpacity(0.2) 
                                      : Colors.red.withOpacity(0.2),
                                ),
                                margin: const EdgeInsets.all(16),
                                child: Center(
                                  child: Transform.rotate(
                                    angle: _position.dx > 0 ? -0.2 : 0.2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _position.dx > 0 ? Colors.green : Colors.red,
                                          width: 4,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _position.dx > 0 ? 'WALK' : 'NOPE',
                                        style: TextStyle(
                                          color: _position.dx > 0 ? Colors.green : Colors.red,
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No more dogs nearby!',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentIndex = 0;
                              _matches.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text('Start Over'),
                        ),
                      ],
                    ),
                  ),
          ),
          
          // Bottom Controls
          if (_currentIndex < _dogs.length)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlBtn(
                    icon: Icons.close,
                    color: Colors.red,
                    onPressed: _swipeLeft,
                  ),
                  _buildControlBtn(
                    icon: Icons.star,
                    color: Colors.blue,
                    isSmall: true,
                    onPressed: () {},
                  ),
                  _buildControlBtn(
                    icon: Icons.favorite,
                    color: Colors.green,
                    onPressed: _swipeRight,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isSmall = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: color,
        iconSize: isSmall ? 24 : 32,
        padding: EdgeInsets.all(isSmall ? 12 : 16),
      ),
    );
  }
}

enum SwipeStatus { like, dislike }
