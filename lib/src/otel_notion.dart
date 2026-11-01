// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_notion_suppression.dart';

const _tracerName = 'dartastic_otel_libs_notion';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps any Notion API call in a CLIENT span. `resource` is one of
/// `databases`, `pages`, `blocks`, `users`, `search`; `action` is
/// `query`, `create`, `update`, `retrieve`, etc.
Future<T> tracedNotion<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? databaseId,
  String? pageId,
  String? blockId,
  String? notionVersion,
}) async {
  if (notionInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'notion.resource': resource,
    'notion.action': action,
    'notion.operation': '$resource.$action',
  };
  if (databaseId != null) m['notion.database.id'] = databaseId;
  if (pageId != null) m['notion.page.id'] = pageId;
  if (blockId != null) m['notion.block.id'] = blockId;
  if (notionVersion != null) m['notion.api.version'] = notionVersion;

  final span = _tracer().startSpan(
    'notion $resource.$action',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
