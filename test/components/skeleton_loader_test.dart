import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/components/common/skeleton_loader.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('Shimmer', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(wrap(
        const Shimmer(child: SizedBox(width: 100, height: 20)),
      ));

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('skips animation when disableAnimations is true',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: wrap(
            const Shimmer(child: SizedBox(width: 100, height: 20)),
          ),
        ),
      );

      // Should NOT have ShaderMask when animations disabled
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('animation repeats', (tester) async {
      await tester.pumpWidget(wrap(
        const Shimmer(child: SizedBox(width: 100, height: 20)),
      ));

      // Advance time — animation should keep running
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(ShaderMask), findsOneWidget);
    });
  });

  group('SkeletonBox', () {
    testWidgets('renders with given dimensions', (tester) async {
      await tester.pumpWidget(wrap(
        const SkeletonBox(width: 120, height: 24, borderRadius: 8),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, 120);
      expect(container.constraints?.maxHeight, 24);
    });

    testWidgets('renders without explicit width (fills parent)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SkeletonBox(height: 16),
      ));
      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });

  group('SkeletonCircle', () {
    testWidgets('renders with correct size', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonCircle(size: 44)));

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, 44);
      expect(container.constraints?.maxHeight, 44);
    });
  });

  group('HomeScreenSkeleton', () {
    testWidgets('renders all skeleton sections', (tester) async {
      await tester.pumpWidget(wrap(const HomeScreenSkeleton()));
      await tester.pump();

      // Should have Shimmer wrapper
      expect(find.byType(Shimmer), findsOneWidget);
      // Should contain a GridView for dashboard cards
      expect(find.byType(GridView), findsOneWidget);
      // Should have multiple SkeletonBox placeholders
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });

  group('ListScreenSkeleton', () {
    testWidgets('renders default item count', (tester) async {
      await tester.pumpWidget(wrap(const ListScreenSkeleton()));
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      // Should have SkeletonCircle for avatar placeholders
      expect(find.byType(SkeletonCircle), findsWidgets);
    });

    testWidgets('respects custom itemCount', (tester) async {
      await tester.pumpWidget(wrap(const ListScreenSkeleton(itemCount: 3)));
      await tester.pump();

      // 3 items, each with 1 circle = 3 circles
      expect(find.byType(SkeletonCircle), findsNWidgets(3));
    });
  });

  group('FormScreenSkeleton', () {
    testWidgets('renders form placeholder sections (deprecated wrapper)',
        (tester) async {
      await tester.pumpWidget(wrap(const FormScreenSkeleton()));
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });

  group('BonusHistorySkeleton', () {
    testWidgets('renders bonus card placeholders', (tester) async {
      await tester.pumpWidget(wrap(const BonusHistorySkeleton(itemCount: 3)));
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });

  group('AttendanceScreenSkeleton', () {
    testWidgets('renders attendance placeholder sections', (tester) async {
      await tester.pumpWidget(wrap(const AttendanceScreenSkeleton()));
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      // Avatar circle + progress ring circle in content
      expect(find.byType(SkeletonCircle), findsWidgets);
      // Multiple skeleton boxes for name, stats, calendar, button
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });

  group('StaffListSkeleton', () {
    testWidgets('renders staff card placeholders', (tester) async {
      await tester.pumpWidget(wrap(const StaffListSkeleton(itemCount: 3)));
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      // Each card has an avatar circle
      expect(find.byType(SkeletonCircle), findsWidgets);
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });

  group('TeamListSkeleton', () {
    testWidgets('renders team card placeholders', (tester) async {
      await tester.pumpWidget(wrap(const TeamListSkeleton(itemCount: 3)));
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      // Each card has a square icon placeholder (SkeletonBox)
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });

  group('BonusManagementSkeleton', () {
    testWidgets('renders header card and dropdown placeholders',
        (tester) async {
      await tester.pumpWidget(wrap(const BonusManagementSkeleton()));
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      // Header icon circle
      expect(find.byType(SkeletonCircle), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });

  group('WorksheetSkeleton', () {
    testWidgets('renders header and form card placeholders', (tester) async {
      await tester.pumpWidget(wrap(const WorksheetSkeleton()));
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      // Circle icon in header
      expect(find.byType(SkeletonCircle), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });

  group('AddMaterialSkeleton', () {
    testWidgets('renders header and 3 form cards', (tester) async {
      await tester.pumpWidget(wrap(const AddMaterialSkeleton()));
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(SkeletonCircle), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });

  group('WithdrawMaterialSkeleton', () {
    testWidgets('renders header and 3 form cards', (tester) async {
      await tester.pumpWidget(wrap(const WithdrawMaterialSkeleton()));
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(SkeletonCircle), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });
}
