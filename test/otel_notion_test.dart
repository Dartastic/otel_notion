// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_notion/otel_notion.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_notion-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('databases.query records CLIENT span', () async {
    await tracedNotion<String>(
      resource: 'databases',
      action: 'query',
      databaseId: 'db-1',
      notionVersion: '2022-06-28',
      invoke: () async => 'rows',
    );
    final a = attrsOf(spans.findSpanByName('notion databases.query')!);
    expect(a['notion.resource'], 'databases');
    expect(a['notion.action'], 'query');
    expect(a['notion.operation'], 'databases.query');
    expect(a['notion.database.id'], 'db-1');
    expect(a['notion.api.version'], '2022-06-28');
  });

  test('suppression skips spans', () async {
    await runWithoutNotionInstrumentationAsync(() async {
      await tracedNotion<String>(
        resource: 'pages',
        action: 'create',
        invoke: () async => 'p',
      );
    });
    expect(spans.findSpansStartingWith('notion '), isEmpty);
  });
}
