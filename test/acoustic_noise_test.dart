import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huliot_sims/simulators/acoustic_noise/models/acoustic_models.dart';
import 'package:huliot_sims/simulators/acoustic_noise/screens/acoustic_noise_screen.dart';
import 'package:huliot_sims/simulators/acoustic_noise/widgets/acoustic_decibel_meter.dart';
import 'package:huliot_sims/simulators/acoustic_noise/widgets/fraunhofer_certificate_dialog.dart';
import 'package:huliot_sims/simulators/acoustic_noise/widgets/acoustic_testing_guide_dialog.dart';
import 'package:huliot_sims/simulators/acoustic_noise/services/acoustic_mic_service.dart';
import 'package:huliot_sims/simulators/acoustic_noise/services/acoustic_site_report_service.dart';
import 'package:huliot_sims/simulators/acoustic_noise/services/noise_isolation_service.dart';

void main() {
  group('Acoustic Physics Calculations & Standards', () {
    test('Huliot Ultra Silent conforms to Fraunhofer IBP benchmark values', () {
      final huliot = PipeAcousticProfile.huliot;

      // 0.5 L/s with acoustic clamp on solid masonry: < 10 dB(A)
      final db05 = huliot.calculateNoise(
        flowRate: 0.5,
        bracket: BracketType.huliotAcoustic,
        wall: WallType.solidMasonry,
      );
      expect(db05, lessThan(10.0));

      // 2.0 L/s with acoustic clamp on solid masonry: ~15 dB(A)
      final db20 = huliot.calculateNoise(
        flowRate: 2.0,
        bracket: BracketType.huliotAcoustic,
        wall: WallType.solidMasonry,
      );
      expect(db20, inInclusiveRange(13.0, 16.0));
      expect(db20, lessThanOrEqualTo(24.0)); // VDI 4100 SSt III Luxury pass

      // 2.0 L/s with rigid clamp: ~18-20 dB(A)
      final db20Rigid = huliot.calculateNoise(
        flowRate: 2.0,
        bracket: BracketType.rigidMetal,
        wall: WallType.solidMasonry,
      );
      expect(db20Rigid, inInclusiveRange(18.0, 21.0));
      expect(db20Rigid, lessThanOrEqualTo(30.0)); // DIN 4109 pass
    });

    test('Structure-Borne and Airborne Noise separation', () {
      final huliot = PipeAcousticProfile.huliot;
      final structDb = huliot.calculateNoise(
        flowRate: 2.0,
        bracket: BracketType.huliotAcoustic,
        wall: WallType.solidMasonry,
      );
      final airborneDb = huliot.calculateAirborneNoise(2.0);

      // Structure-borne noise travels into receiving room: ~15 dB(A)
      expect(structDb, inInclusiveRange(13.0, 16.0));

      // Airborne noise stays inside shaft/installation room: ~50-53 dB(A)
      expect(airborneDb, inInclusiveRange(48.0, 54.0));
    });

    test('Multi-brand pipe database hierarchy comparison', () {
      final pvc = PipeAcousticProfile.allPipes.firstWhere((p) => p.type == PipeTechnologyType.pvc);
      final castIron = PipeAcousticProfile.allPipes.firstWhere((p) => p.type == PipeTechnologyType.castIron);
      final hdpe = PipeAcousticProfile.allPipes.firstWhere((p) => p.type == PipeTechnologyType.hdpe);
      final huliot = PipeAcousticProfile.huliot;
      final astral = PipeAcousticProfile.allPipes.firstWhere((p) => p.type == PipeTechnologyType.astralSilencio);
      final supreme = PipeAcousticProfile.allPipes.firstWhere((p) => p.type == PipeTechnologyType.supremeSkyrise);
      final prince = PipeAcousticProfile.allPipes.firstWhere((p) => p.type == PipeTechnologyType.princeSilentfit);

      const flow = 2.0;
      const bracket = BracketType.huliotAcoustic;
      const wall = WallType.solidMasonry;

      final pvcDb = pvc.calculateNoise(flowRate: flow, bracket: bracket, wall: wall);
      final castIronDb = castIron.calculateNoise(flowRate: flow, bracket: bracket, wall: wall);
      final hdpeDb = hdpe.calculateNoise(flowRate: flow, bracket: bracket, wall: wall);
      final huliotDb = huliot.calculateNoise(flowRate: flow, bracket: bracket, wall: wall);
      final astralDb = astral.calculateNoise(flowRate: flow, bracket: bracket, wall: wall);
      final supremeDb = supreme.calculateNoise(flowRate: flow, bracket: bracket, wall: wall);
      final princeDb = prince.calculateNoise(flowRate: flow, bracket: bracket, wall: wall);

      // Huliot is quietest of all
      expect(huliotDb, lessThan(astralDb));
      expect(huliotDb, lessThan(supremeDb));
      expect(huliotDb, lessThan(princeDb));
      expect(huliotDb, lessThan(castIronDb));
      expect(huliotDb, lessThan(hdpeDb));
      expect(huliotDb, lessThan(pvcDb));

      // PVC is loudest
      expect(pvcDb, greaterThan(hdpeDb));
      expect(pvcDb, greaterThan(castIronDb));

      // Fraunhofer certification check
      expect(huliot.hasFraunhoferCert, isTrue);
      expect(astral.hasFraunhoferCert, isFalse);
    });

    test('Fraunhofer Official Test Points integrity', () {
      expect(FraunhoferTestPoint.officialData.length, equals(4));
      for (final pt in FraunhoferTestPoint.officialData) {
        expect(pt.passesDin4109, isTrue);
        expect(pt.passesVdi4100Sst3, isTrue);
      }
    });
  });

  group('ISO 16032 Background Noise Isolation Service', () {
    test('Case 1: Delta L >= 10 dB gives High Confidence with negligible background error', () {
      final res = NoiseIsolationService.isolatePipeNoise(lTotal: 45.0, lBackground: 32.0);
      expect(res.deltaL, equals(13.0));
      expect(res.confidence, equals(NoiseConfidence.high));
      expect(res.isReliable, isTrue);
      expect(res.lCorrected, inInclusiveRange(44.5, 45.0));
    });

    test('Case 2: 6 dB <= Delta L < 10 dB applies logarithmic subtraction with Medium Confidence', () {
      final res = NoiseIsolationService.isolatePipeNoise(lTotal: 40.0, lBackground: 33.0);
      expect(res.deltaL, equals(7.0));
      expect(res.confidence, equals(NoiseConfidence.medium));
      expect(res.isReliable, isTrue);
      // Corrected should be around 39.0 dB (subtracted ~1.0 dB)
      expect(res.lCorrected, inInclusiveRange(38.5, 39.5));
    });

    test('Case 3: 3 dB <= Delta L < 6 dB applies subtraction with Low Confidence warning', () {
      final res = NoiseIsolationService.isolatePipeNoise(lTotal: 38.0, lBackground: 34.0);
      expect(res.deltaL, equals(4.0));
      expect(res.confidence, equals(NoiseConfidence.low));
      expect(res.isReliable, isTrue);
      expect(res.lCorrected, inInclusiveRange(35.0, 36.5));
    });

    test('Case 4: Delta L < 3 dB is marked UNRELIABLE per ISO 16032', () {
      final res = NoiseIsolationService.isolatePipeNoise(lTotal: 36.0, lBackground: 34.5);
      expect(res.deltaL, equals(1.5));
      expect(res.confidence, equals(NoiseConfidence.unreliable));
      expect(res.isReliable, isFalse);
    });
  });

  group('Acoustic Decibel Meter Widget Tests', () {
    testWidgets('Renders needle gauge and digital readout accurately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcousticDecibelMeter(
              currentDb: 14.5,
              mode: AcousticMode.simulation,
              selectedPipe: PipeAcousticProfile.huliot,
              isLiveActive: false,
              liveJitterDb: 0.0,
              onToggleLiveMode: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ACOUSTIC SOUND LEVEL METER'), findsOneWidget);
      expect(find.text('SIMULATION MODE'), findsOneWidget);
      expect(find.text('dB(A)'), findsOneWidget);
      expect(find.textContaining('VDI 4100 Level III'), findsWidgets);
    });

    testWidgets('Fraunhofer Certificate Dialog renders test table and badges', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => FraunhoferCertificateDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('FRAUNHOFER IBP TEST REPORT SUMMARY'), findsOneWidget);
      expect(find.textContaining('P-BA 20/2019e'), findsWidgets);
      expect(find.text('DIN 4109'), findsWidgets);
      expect(find.text('VDI 4100 SSt III'), findsWidgets);
      expect(find.text('Close Certificate'), findsOneWidget);
    });

    testWidgets('Acoustic Testing Guide SOP dialog renders distance guidelines and ISO rules', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AcousticTestingGuideDialog.show(context),
                child: const Text('Open SOP'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open SOP'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ON-SITE ACOUSTIC TESTING SOP & GUIDELINES'), findsOneWidget);
      expect(find.textContaining('1. Device & Microphone Placement'), findsOneWidget);
      expect(find.textContaining('2. 3-Phase Acoustic Testing Protocol'), findsOneWidget);
      expect(find.textContaining('3. ISO 16032 Measurement Validity Rules'), findsOneWidget);
      expect(find.text('Understood / Close'), findsOneWidget);
    });

    testWidgets('Full AcousticNoiseScreen renders and handles interactions', (tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AcousticNoiseScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Top banner
      expect(find.text('HULIOT ULTRA SILENT ACOUSTIC ATTENUATION LAB'), findsOneWidget);

      // Top banner SOP button
      expect(find.text('Testing Guidelines (SOP)'), findsOneWidget);

      // Mode tabs
      expect(find.text('Mode A: Physics Simulation Lab'), findsOneWidget);
      expect(find.text('Mode B: Live Site Sound Testing'), findsOneWidget);

      // Comparison Bench
      expect(find.text('MULTI-PIPE ACOUSTIC BENCHMARK COMPARISON'), findsOneWidget);
      expect(find.text('Standard Thin-Wall PVC'), findsWidgets);
      expect(find.text('Traditional Cast Iron SML'), findsWidgets);
      expect(find.text('Standard HDPE'), findsWidgets);
      expect(find.text('Huliot Ultra Silent PP-MD'), findsWidgets);

      // 3-Layer Technology
      expect(find.text('Ultra-Smooth PP Bore'), findsOneWidget);
      expect(find.text('Mineral-Reinforced PP-MD'), findsOneWidget);
      expect(find.text('Impact Casing Shield'), findsOneWidget);

      // Switch to Mode B (Live Site Sound Testing)
      await tester.tap(find.text('Mode B: Live Site Sound Testing'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('LIVE MIC ACTIVE'), findsWidgets);

      // In Mode B: 3-Phase ISO 16032 card is visible
      expect(find.textContaining('ISO 16032 ON-SITE ACOUSTIC NOISE ISOLATION PROTOCOL'), findsOneWidget);
      expect(find.textContaining('Step 1: Calibrate Site Background Ambient Noise Floor'), findsOneWidget);

      // Tap preset 4.0 L/s flow rate
      await tester.tap(find.text('4.0 L/s (Peak Flush)'));
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Rigid Metal Clamp
      await tester.tap(find.text('Rigid Metal Clamp'));
      await tester.pump(const Duration(milliseconds: 300));

      // Open Testing Guidelines SOP
      await tester.tap(find.text('Testing Guidelines (SOP)').first);
      await tester.pumpAndSettle();
      expect(find.text('Understood / Close'), findsOneWidget);
      await tester.tap(find.text('Understood / Close'));
      await tester.pumpAndSettle();

      // Open Fraunhofer Certificate
      await tester.tap(find.text('Fraunhofer Certificate').first);
      await tester.pumpAndSettle();
      expect(find.text('Close Certificate'), findsOneWidget);
      await tester.tap(find.text('Close Certificate'));
      await tester.pumpAndSettle();

      // Open Site Test Report Dialog
      await tester.tap(find.text('Site Test Report').first);
      await tester.pumpAndSettle();
      expect(find.text('ON-SITE ACOUSTIC TEST REPORT'), findsOneWidget);
      expect(find.text('Print / Save PDF Report'), findsOneWidget);
      expect(find.text('Download HTML'), findsOneWidget);

      // Close Report Dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    test('AcousticSiteReportService generates valid compliant HTML with ISO 16032 isolation', () {
      const reading = AcousticMicReading(
        isActive: false,
        permissionState: 'granted',
        errorMsg: '',
        currentDb: 15.2,
        minDb: 10.4,
        maxDb: 18.0,
        avgDb: 15.0,
        durationSec: 20,
        sampleCount: 200,
      );

      final isolation = NoiseIsolationService.isolatePipeNoise(lTotal: 22.0, lBackground: 15.0);

      final html = AcousticSiteReportService.generateSiteReportHtml(
        reading: reading,
        testedPipe: PipeAcousticProfile.huliot,
        bracket: BracketType.huliotAcoustic,
        wall: WallType.solidMasonry,
        measurementPosition: MeasurementPosition.installationShaft,
        isolationResult: isolation,
        projectName: 'High-Rise Tower A',
      );

      expect(html.contains('HULIOT PIPING SYSTEMS'), isTrue);
      expect(html.contains('High-Rise Tower A'), isTrue);
      expect(html.contains('COMPLIANT &amp; APPROVED (PASS)') || html.contains('COMPLIANT & APPROVED (PASS)'), isTrue);
      expect(html.contains('P-BA 20/2019e'), isTrue);
      expect(html.contains('ISO 16032 Background Noise'), isTrue);
      expect(html.contains('Statutory Building Codes'), isTrue);
    });
  });
}
