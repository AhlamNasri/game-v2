import 'package:fashion_room_girls/presentation/room_design/models/room_definition.dart';
import 'package:fashion_room_girls/presentation/room_design/widgets/inventory_drawer.dart';
import 'package:fashion_room_girls/presentation/room_design/widgets/top_menu_drawer.dart';
import 'package:fashion_room_girls/presentation/shop/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
<<<<<<< HEAD
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(initialRoute: ''));
=======
  testWidgets('top menu drawer renders controls without overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: TopMenuDrawer(
              visible: true,
              coins: 0,
              rooms: [
                RoomDefinition(
                  id: 'room_1',
                  name: 'Guest Room',
                  background: 'room_assets/room_bg.jpeg',
                  placedItems: const [],
                ),
              ],
              activeRoomIndex: 0,
              playerName: 'Tester',
              playerLevel: 5,
              saving: false,
              inventoryVisible: false,
              onToggleMenu: () {},
              onBack: () {},
              onGoToCloset: () {},
              onCompetitionMode: () {},
              onSettings: () {},
              onRoomSelected: (_) {},
              onUnlockSecondRoom: () {},
              onToggleInventory: () {},
            ),
          ),
        ),
      ),
    );
>>>>>>> upstream/develop

    expect(find.byTooltip('Hide menu'), findsOneWidget);
    expect(find.byTooltip('Show inventory'), findsOneWidget);
    expect(find.byTooltip('Go to Closet'), findsOneWidget);
    expect(find.byTooltip('Competition Mode'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inventory drawer renders as an overlay panel', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Colors.white)),
              SafeArea(
                child: InventoryDrawer(
                  visible: true,
                  inventory: const [],
                  onShopPressed: () {},
                  onClose: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byTooltip('Go Shop'), findsOneWidget);
    expect(find.byTooltip('Hide inventory'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile badge hides while inventory drawer is open', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: TopMenuDrawer(
              visible: false,
              coins: 0,
              rooms: [
                RoomDefinition(
                  id: 'room_1',
                  name: 'Guest Room',
                  background: 'room_assets/room_bg.jpeg',
                  placedItems: const [],
                ),
              ],
              activeRoomIndex: 0,
              playerName: 'Tester',
              playerLevel: 5,
              saving: false,
              inventoryVisible: true,
              onToggleMenu: () {},
              onBack: () {},
              onGoToCloset: () {},
              onCompetitionMode: () {},
              onSettings: () {},
              onRoomSelected: (_) {},
              onUnlockSecondRoom: () {},
              onToggleInventory: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ProfileBadge), findsNothing);
    expect(find.byTooltip('Open menu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shop route target stays intentionally empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));

    expect(find.byType(Scaffold), findsOneWidget);
  });
}
