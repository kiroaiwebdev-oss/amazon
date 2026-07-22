library;

import 'models.dart';

/// Bundled catalog: 120 original coloring-page records across the eight
/// approved categories (15 each). Exactly 20 are free (the first 2-3 of
/// each category as marked below) and exactly 100 are premium - these
/// invariants are enforced by automated tests (catalog_invariants_test.dart).
///
/// Titles marked free per category: Going Places 3, Nature 4 (approved
/// Category Results copy says "15 pictures - 4 free"), Circus 2,
/// Tiny Treasures 2, Home 3, Beach 2, City 2, Adorable Friends 2 = 20 free.
class _Cat {
  const _Cat(this.name, this.freeCount, this.titles);
  final String name;
  final int freeCount;
  final List<String> titles;
}

const List<_Cat> _seed = [
  _Cat('Going Places', 3, [
    'Balloon Bus', 'Moonlit Train', 'Little Red Ferry', 'Propeller Pal',
    'Rocket Wagon', 'Sleepy Submarine', 'Tandem Ride', 'Cloud Glider',
    'Snowy Cable Car', 'Happy Helicopter', 'Desert Jeep', 'Sailing Whale',
    'Star Tram', 'Puddle Jumper', 'Caravan Holiday',
  ]),
  _Cat('Circus', 2, [
    'Friendly Juggler', 'Big Top Morning', 'Tightrope Turtle',
    'Cannonball Bunny', 'Ring of Ribbons', 'Drumming Seal',
    'Trapeze Twins', 'Clown Car Parade', 'Strongman Mouse',
    'Popcorn Cart', 'Dancing Ponies', 'Magic Hat Rabbit',
    'Balancing Bear', 'Confetti Cannon', 'Ticket Booth Fox',
  ]),
  _Cat('Tiny Treasures', 2, [
    'Button Box', 'Marble Jar', 'Acorn Family', 'Pocket Watch',
    'Seashell Chest', 'Ribbon Spool', 'Tiny Key Ring', 'Stamp Album',
    'Thimble Garden', 'Bead Necklace', 'Lucky Pebbles', 'Paper Boats',
    'Snowglobe Village', 'Feather Collection', 'Music Box Waltz',
  ]),
  _Cat('Home', 3, [
    'Cozy Kitchen', 'Reading Nook', 'Bubble Bath', 'Pancake Morning',
    'Sock Drawer Cat', 'Window Garden', 'Blanket Fort', 'Teatime Table',
    'Laundry Day', 'Attic Treasures', 'Garden Shed', 'Fireplace Stories',
    'Sunday Soup', 'Toy Shelf', 'Goodnight Lamp',
  ]),
  _Cat('Beach', 2, [
    'Sandcastle Parade', 'Crab Concert', 'Lighthouse Keeper',
    'Surfing Seagull', 'Tide Pool Friends', 'Ice Cream Cove',
    'Message Bottle', 'Umbrella Row', 'Starfish Circle',
    'Driftwood Raft', 'Pelican Pier', 'Shell Seeker',
    'Kite Over Dunes', 'Beach Picnic', 'Sunset Swim',
  ]),
  _Cat('City', 2, [
    'City Cats', 'Tram Stop Tunes', 'Rooftop Garden', 'Bakery Window',
    'Fountain Plaza', 'Bookshop Corner', 'Umbrella Crossing',
    'Balcony Concert', 'Night Market', 'Postman Rounds',
    'Park Carousel', 'Skyline Painters', 'Bridge Builders',
    'Flower Cart', 'Museum Steps',
  ]),
  _Cat('Nature', 4, [
    'Garden Hedgehog', 'Rainy Fox', 'Sleepy Snail', 'Treehouse Birds',
    'Mushroom Picnic', 'Pond Pals', 'Sunny Meadow', 'Forest Parade',
    'Firefly Evening', 'Autumn Squirrel', 'River Otters', 'Mountain Hare',
    'Butterfly Garden', 'Owl Family', 'Springtime Burrow',
  ]),
  _Cat('Adorable Friends', 2, [
    'Puppy Pile', 'Kitten Yarn', 'Penguin Huddle', 'Baby Elephant',
    'Bunny Tea Party', 'Duckling March', 'Koala Nap', 'Panda Snack',
    'Lamb Meadow', 'Hamster Wheel', 'Fawn Forest', 'Otter Hold Hands',
    'Chick Parade', 'Puppy Umbrella', 'Sleepy Sloth',
  ]),
];

/// Deterministically builds the 120 bundled catalog records.
List<CatalogItem> buildCatalogSeed() {
  final items = <CatalogItem>[];
  var globalIndex = 0;
  for (var c = 0; c < _seed.length; c++) {
    final cat = _seed[c];
    assert(cat.titles.length == 15, 'Each category bundles 15 pictures');
    for (var i = 0; i < cat.titles.length; i++) {
      final difficulty = switch (i % 3) {
        0 => Difficulty.beginner,
        1 => Difficulty.explorer,
        _ => Difficulty.creator,
      };
      items.add(CatalogItem(
        id: 'tc_${(c + 1).toString().padLeft(2, '0')}_${(i + 1).toString().padLeft(2, '0')}',
        title: cat.titles[i],
        category: cat.name,
        difficulty: difficulty,
        premium: i >= cat.freeCount,
        assetSeed: globalIndex + 1,
        keywords: _keywordsFor(cat.titles[i], cat.name, difficulty),
        contentVersion: 1,
      ));
      globalIndex++;
    }
  }
  return items;
}

String _keywordsFor(String title, String category, Difficulty difficulty) {
  final words = title.toLowerCase().split(' ');
  return <String>{
    ...words,
    category.toLowerCase(),
    difficulty.label.toLowerCase(),
  }.join(' ');
}
