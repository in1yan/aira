import 'package:flutter/material.dart';

/// All hardcoded mock data for the prototype.

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------
class CategoryData {
  final int? id;
  final String name;
  final IconData icon;
  final Color color;
  final bool available;
  final List<String> subcategories;

  const CategoryData({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.available = true,
    this.subcategories = const [],
  });
}

const List<CategoryData> mockCategories = [
  CategoryData(
    name: 'Animals',
    icon: Icons.pets,
    color: Color(0xFFE8F5E9),
    available: true,
    subcategories: [
      'Domestic animals',
      'Wild animals',
      'Farm animals',
      'Reptiles'
    ],
  ),
  CategoryData(
    name: 'Birds',
    icon: Icons.flutter_dash,
    color: Color(0xFFE3F2FD),
    available: true,
    subcategories: ['Common birds', 'Birds of prey', 'Water birds'],
  ),
  CategoryData(
    name: 'Sea & Water Animals',
    icon: Icons.water,
    color: Color(0xFFE0F7FA),
    available: true,
    subcategories: [
      'Fish',
      'Dolphin / Whale',
      'Crab',
      'Turtle',
      'Other aquatic animals'
    ],
  ),
  CategoryData(
    name: 'Insects & Creatures',
    icon: Icons.bug_report,
    color: Color(0xFFFFF8E1),
    available: true,
    subcategories: [
      'Butterfly',
      'Bee',
      'Fly',
      'Cockroach',
      'Ant',
      'Scorpion',
      'Spider'
    ],
  ),
  CategoryData(
    name: 'Fruits',
    icon: Icons.apple,
    color: Color(0xFFFFEBEE),
    available: true,
    subcategories: [
      'Apple',
      'Banana',
      'Mango',
      'Orange',
      'Grapes',
      'Papaya',
      'Pomegranate',
      'Strawberry'
    ],
  ),
  CategoryData(
    name: 'Vegetables',
    icon: Icons.eco,
    color: Color(0xFFF1F8E9),
    available: true,
    subcategories: [
      'Potato',
      'Tomato',
      'Carrot',
      'Cabbage',
      'Onion',
      'Green beans',
      'Peas',
      'Cucumber',
      'Spinach'
    ],
  ),
  CategoryData(
    name: 'Plants & Flowers',
    icon: Icons.local_florist,
    color: Color(0xFFE8F5E9),
    available: true,
    subcategories: ['Trees', 'Leaves', 'Flowers', 'Garden plants'],
  ),
  CategoryData(
    name: 'Clothes & Accessories',
    icon: Icons.checkroom,
    color: Color(0xFFF3E5F5),
    available: true,
    subcategories: [
      'Shirts',
      'Pants',
      'Dresses',
      'Shoes',
      'Sarees',
      'Caps',
      'Belts'
    ],
  ),
  CategoryData(
    name: 'Home & Kitchen',
    icon: Icons.kitchen,
    color: Color(0xFFFFF3E0),
    available: true,
    subcategories: [
      'Cups',
      'Plates',
      'Spoons',
      'Pots',
      'Pans',
      'Furniture',
      'Household items'
    ],
  ),
  CategoryData(
    name: 'School & Learning',
    icon: Icons.school,
    color: Color(0xFFE8EAF6),
    available: true,
    subcategories: [
      'Books',
      'Pencil',
      'Pen',
      'Blackboard',
      'School bag',
      'Educational materials'
    ],
  ),
  CategoryData(
    name: 'Vehicles & Transport',
    icon: Icons.directions_car,
    color: Color(0xFFE1F5FE),
    available: true,
    subcategories: [
      'Car',
      'Bus',
      'Train',
      'Bicycle',
      'Motorcycle',
      'Aircraft',
      'Ship',
      'Boat',
      'Ambulance',
      'Tractor'
    ],
  ),
  CategoryData(
    name: 'Numbers',
    icon: Icons.pin,
    color: Color(0xFFFFF3E0),
    available: true,
    subcategories: ['0–9 Numbers', 'Counting Cards', 'Mathematical Signs'],
  ),
  CategoryData(
    name: 'Shapes',
    icon: Icons.category,
    color: Color(0xFFF3E5F5),
    available: true,
    subcategories: [
      'Circle',
      'Square',
      'Triangle',
      'Rectangle',
      'Star',
      'Heart',
      '3D shapes'
    ],
  ),
  CategoryData(
    name: 'Colours',
    icon: Icons.palette,
    color: Color(0xFFFCE4EC),
    available: true,
    subcategories: [
      'Red',
      'Blue',
      'Green',
      'Yellow',
      'Black',
      'White',
      'Purple',
      'Orange',
      'Brown',
      'Grey'
    ],
  ),
  CategoryData(
    name: 'Time & Calendar',
    icon: Icons.access_time,
    color: Color(0xFFE0F2F1),
    available: true,
    subcategories: [
      'Days of the week',
      'Months',
      'Morning / Night',
      'Time-related concepts'
    ],
  ),
  CategoryData(
    name: 'Body Parts',
    icon: Icons.accessibility_new,
    color: Color(0xFFFFEBEE),
    available: true,
    subcategories: ['Eyes', 'Nose', 'Ear', 'Mouth', 'Hand', 'Leg', 'Foot'],
  ),
  CategoryData(
    name: 'People & Professions',
    icon: Icons.work,
    color: Color(0xFFEFEBE9),
    available: true,
    subcategories: [
      'Doctor',
      'Teacher',
      'Police',
      'Lawyer',
      'Farmer',
      'Engineer'
    ],
  ),
  CategoryData(
    name: 'Places & Buildings',
    icon: Icons.location_city,
    color: Color(0xFFE0F7FA),
    available: true,
    subcategories: [
      'Houses',
      'Schools',
      'Hospitals',
      'Temples',
      'Monuments',
      'Famous landmarks'
    ],
  ),
  CategoryData(
    name: 'Nature & Environment',
    icon: Icons.wb_sunny,
    color: Color(0xFFFFF8E1),
    available: true,
    subcategories: [
      'Sun',
      'Sky',
      'Trees',
      'Landscape',
      'Water',
      'Desert',
      'Weather'
    ],
  ),
  CategoryData(
    name: 'Emotions & Concepts',
    icon: Icons.sentiment_satisfied_alt,
    color: Color(0xFFF3E5F5),
    available: true,
    subcategories: ['Happiness', 'Fear', 'Honesty', 'Knowledge', 'Friendship'],
  ),
];

// ---------------------------------------------------------------------------
// Animal Cards
// ---------------------------------------------------------------------------
class AnimalCard {
  final String name;
  final Color color;
  final IconData icon;

  const AnimalCard({
    required this.name,
    required this.color,
    required this.icon,
  });
}

const List<AnimalCard> mockAnimalCards = [
  AnimalCard(name: 'Dog', color: Color(0xFFFFCC80), icon: Icons.pets),
  AnimalCard(name: 'Cat', color: Color(0xFFCE93D8), icon: Icons.pets),
  AnimalCard(name: 'Elephant', color: Color(0xFF90CAF9), icon: Icons.pets),
  AnimalCard(name: 'Horse', color: Color(0xFFA5D6A7), icon: Icons.pets),
  AnimalCard(name: 'Bird', color: Color(0xFFF48FB1), icon: Icons.flutter_dash),
  AnimalCard(name: 'Rabbit', color: Color(0xFFFFAB91), icon: Icons.pets),
];

// ---------------------------------------------------------------------------
// Card Detail — Concept rows
// ---------------------------------------------------------------------------
class ConceptRow {
  final String concept;
  final String value;
  final IconData icon;

  const ConceptRow({
    required this.concept,
    required this.value,
    required this.icon,
  });
}

const List<ConceptRow> dogConcepts = [
  ConceptRow(concept: 'Group', value: 'Mammals', icon: Icons.category),
  ConceptRow(concept: 'Use', value: 'Pet / Companion', icon: Icons.favorite),
  ConceptRow(
      concept: 'Action',
      value: 'Barks, Runs, Plays',
      icon: Icons.directions_run),
  ConceptRow(
      concept: 'Properties', value: 'Furry, Four Legs', icon: Icons.texture),
  ConceptRow(concept: 'Location', value: 'House / Yard', icon: Icons.home),
  ConceptRow(
      concept: 'Association', value: 'Loyal, Friendly', icon: Icons.handshake),
];

// ---------------------------------------------------------------------------
// Interactive learning explanations
// ---------------------------------------------------------------------------
const Map<String, String> conceptExplanations = {
  'Group':
      'Dog is a mammal. It is warm-blooded and has fur. Mammals feed their babies with milk and take care of their young ones.',
  'Use':
      'Dogs are commonly kept as pets and companions. They provide emotional support, security, and help in activities like herding, guiding, and therapy.',
  'Action':
      'Dogs bark to communicate, run with great speed, and love to play fetch, tug-of-war, and other games with their owners.',
  'Properties':
      'Dogs have fur that keeps them warm. They walk on four legs and have a strong sense of smell and hearing.',
  'Location':
      'Dogs usually live in houses with their families. They love spending time in the yard, parks, and open spaces.',
  'Association':
      'Dogs are known for being loyal and friendly. They form strong bonds with humans and are often called "man\'s best friend."',
};
