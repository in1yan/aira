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
  final String domain;
  final int cardCount;
  final String description;

  const CategoryData({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.available = true,
    this.subcategories = const [],
    this.domain = 'semantic',
    this.cardCount = 0,
    this.description = '',
  });
}

const List<CategoryData> mockCategories = [
  CategoryData(
    id: 1,
    name: 'Animals',
    icon: Icons.pets,
    color: Color(0xFFE8F5E9),
    available: true,
    domain: 'semantic',
    subcategories: [
      'Domestic animals',
      'Wild animals',
      'Farm animals',
      'Reptiles'
    ],
  ),
  CategoryData(
    id: 2,
    name: 'Birds',
    icon: Icons.flutter_dash,
    color: Color(0xFFE3F2FD),
    available: true,
    domain: 'semantic',
    subcategories: ['Common birds', 'Birds of prey', 'Water birds'],
  ),
  // Phonology Categories
  CategoryData(
    id: 101,
    name: 'Consonants & Vowels',
    icon: Icons.record_voice_over_rounded,
    color: Color(0xFFE0F2FE),
    available: true,
    domain: 'phonology',
    subcategories: ['Bilabials (/p/, /b/, /m/)', 'Alveolars (/t/, /d/, /n/)', 'Velars (/k/, /g/)'],
  ),
  CategoryData(
    id: 102,
    name: 'Initial Sounds',
    icon: Icons.hearing_rounded,
    color: Color(0xFFE0F2FE),
    available: true,
    domain: 'phonology',
    subcategories: ['Initial consonants', 'Initial blend sounds'],
  ),
  CategoryData(
    id: 103,
    name: 'Medial Sounds',
    icon: Icons.graphic_eq_rounded,
    color: Color(0xFFE0F2FE),
    available: true,
    domain: 'phonology',
    subcategories: ['Medial vowels', 'Medial clusters'],
  ),
  CategoryData(
    id: 104,
    name: 'Final Sounds',
    icon: Icons.volume_up_rounded,
    color: Color(0xFFE0F2FE),
    available: true,
    domain: 'phonology',
    subcategories: ['Final plosives', 'Final nasals', 'Final fricatives'],
  ),
  // Morphology Categories
  CategoryData(
    id: 203,
    name: 'Animals',
    icon: Icons.pets,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 204,
    name: 'Birds',
    icon: Icons.flutter_dash,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 205,
    name: 'Fruits',
    icon: Icons.eco,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 206,
    name: 'Vegetables',
    icon: Icons.restaurant,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 207,
    name: 'Food Items',
    icon: Icons.fastfood,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 208,
    name: 'Vehicles',
    icon: Icons.directions_car,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 209,
    name: 'Household Items',
    icon: Icons.weekend,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 210,
    name: 'Clothes',
    icon: Icons.checkroom,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 211,
    name: 'Occupations',
    icon: Icons.work,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 212,
    name: 'Places',
    icon: Icons.place,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 213,
    name: 'Reptiles',
    icon: Icons.pets,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 214,
    name: 'Marine Animals',
    icon: Icons.water,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 215,
    name: 'Insects',
    icon: Icons.bug_report,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 216,
    name: 'Utensils',
    icon: Icons.soup_kitchen,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 217,
    name: 'Colours',
    icon: Icons.palette,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 218,
    name: 'Shapes',
    icon: Icons.category,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 219,
    name: 'Seasons',
    icon: Icons.wb_sunny,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 220,
    name: 'Festivals',
    icon: Icons.celebration,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 221,
    name: 'Indian Leaders',
    icon: Icons.people,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 222,
    name: 'Sports Players',
    icon: Icons.sports_soccer,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 223,
    name: 'Lord/God',
    icon: Icons.auto_awesome,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 224,
    name: 'Actors',
    icon: Icons.movie,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 225,
    name: 'Cartoons',
    icon: Icons.toys,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  CategoryData(
    id: 226,
    name: 'States',
    icon: Icons.public,
    color: Color(0xFFDCFCE7),
    available: true,
    domain: 'morphology',
  ),
  // Syntax Categories
  CategoryData(
    id: 301,
    name: 'Sentence Sequencing',
    icon: Icons.menu_book_rounded,
    color: Color(0xFFF3E8FF),
    available: true,
    domain: 'syntax',
    subcategories: ['Subject-Verb-Object (SVO)', 'Subject-Verb-Adjective', '3-step sequence stories'],
  ),
  CategoryData(
    id: 302,
    name: 'WH Question Stories',
    icon: Icons.quiz_rounded,
    color: Color(0xFFF3E8FF),
    available: true,
    domain: 'syntax',
    subcategories: ['Who & Where questions', 'What & Why scenarios', 'When temporal stories'],
  ),
  CategoryData(
    id: 303,
    name: 'Conjunctions & Compound Sentences',
    icon: Icons.alt_route_rounded,
    color: Color(0xFFF3E8FF),
    available: true,
    domain: 'syntax',
    subcategories: ['Using "And" / "Because"', 'Contrastive "But" / "Or"'],
  ),
  CategoryData(
    id: 304,
    name: 'Prepositional Phrases',
    icon: Icons.place_rounded,
    color: Color(0xFFF3E8FF),
    available: true,
    domain: 'syntax',
    subcategories: ['In / On / Under', 'Behind / In front of / Next to'],
  ),
  // Pragmatic Categories
  CategoryData(
    id: 401,
    name: 'Turn-Taking Games',
    icon: Icons.sports_esports_rounded,
    color: Color(0xFFFFEDD5),
    available: true,
    domain: 'pragmatic',
    subcategories: ['My turn, your turn games', 'Waiting and signaling intent'],
  ),
  CategoryData(
    id: 402,
    name: 'Conversational Prompts',
    icon: Icons.forum_rounded,
    color: Color(0xFFFFEDD5),
    available: true,
    domain: 'pragmatic',
    subcategories: ['Greetings & Farewells', 'Initiating conversation', 'Topic maintenance'],
  ),
  CategoryData(
    id: 403,
    name: 'Social Requests & Needs',
    icon: Icons.handshake_rounded,
    color: Color(0xFFFFEDD5),
    available: true,
    domain: 'pragmatic',
    subcategories: ['Asking for help politely', 'Requesting items', 'Refusal and boundary phrases'],
  ),
  CategoryData(
    id: 404,
    name: 'Emotion & Empathy Sharing',
    icon: Icons.sentiment_satisfied_alt_rounded,
    color: Color(0xFFFFEDD5),
    available: true,
    domain: 'pragmatic',
    subcategories: ['Expressing feelings', 'Recognizing partner emotions', 'Comforting responses'],
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
