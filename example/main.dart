// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_notion/otel_notion.dart';

/// Traces Notion calls with OpenTelemetry.
///
/// `otel_notion` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Notion call in
/// [tracedNotion]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'notion-example');

  // Wraps any Notion API call in a CLIENT span.
  final notionId = await tracedNotion<String>(
    resource: 'Order',
    action: 'example',
    databaseId: 'database_8f3a2c',
    pageId: 'page_8f3a2c',
    blockId: 'block_8f3a2c',
    notionVersion: '1',
    invoke: () async {
      // Make the Notion call here, then report what it returned.
      return 'notion_8f3a2c';
    },
  );
  OTelLog.info('tracedNotion returned $notionId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutNotionInstrumentationAsync.
  await runWithoutNotionInstrumentationAsync(
    () => tracedNotion<String>(
      resource: 'Order',
      action: 'example',
      databaseId: 'database_8f3a2c',
      pageId: 'page_8f3a2c',
      blockId: 'block_8f3a2c',
      notionVersion: '1',
      invoke: () async {
        return 'notion_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
