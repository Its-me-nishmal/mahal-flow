import '../../l10n/l10n.dart';

/// Why an API call failed. Screens branch on this to choose between an error
/// state ("couldn't load") and an empty state ("nothing here yet") — a failed
/// fetch must never be rendered as an empty list.
enum ApiErrorKind {
  /// No server could be reached (offline, DNS, timeout, connection refused).
  network,

  /// 401 — missing or expired session token.
  unauthorized,

  /// 403 — signed in, but not allowed.
  forbidden,

  /// 404 — the record does not exist.
  notFound,

  /// 400 / 409 / 422 — the request was rejected; [ApiException.serverMessage]
  /// usually says why.
  badRequest,

  /// 5xx — the server failed.
  server,

  /// A 2xx response whose body was not the expected shape.
  badResponse,

  /// A member-scoped call was made with no signed-in member.
  noSession,
}

/// Thrown by every `...OrThrow` / paged read on [ApiService].
class ApiException implements Exception {
  final ApiErrorKind kind;
  final int? statusCode;

  /// The backend's `{"error": "..."}` text when it sent one.
  final String? serverMessage;

  /// Developer detail for logs; never shown to members.
  final Object? cause;

  const ApiException(
    this.kind, {
    this.statusCode,
    this.serverMessage,
    this.cause,
  });

  bool get isNetwork => kind == ApiErrorKind.network;
  bool get isUnauthorized =>
      kind == ApiErrorKind.unauthorized || kind == ApiErrorKind.noSession;
  bool get isNotFound => kind == ApiErrorKind.notFound;

  /// Short, human copy suitable for an error state or snackbar.
  String get userMessage {
    switch (kind) {
      case ApiErrorKind.network:
        return L10n.current.errorNetwork;
      case ApiErrorKind.unauthorized:
      case ApiErrorKind.noSession:
        return L10n.current.errorSessionExpired;
      case ApiErrorKind.forbidden:
        return L10n.current.errorForbidden;
      case ApiErrorKind.notFound:
        return L10n.current.errorNotFound;
      case ApiErrorKind.badRequest:
        return (serverMessage != null && serverMessage!.isNotEmpty)
            ? serverMessage!
            : L10n.current.errorBadRequest;
      case ApiErrorKind.server:
        return L10n.current.errorServer;
      case ApiErrorKind.badResponse:
        return L10n.current.errorBadResponse;
    }
  }

  @override
  String toString() =>
      'ApiException($kind, status: $statusCode, message: $serverMessage, cause: $cause)';
}

/// One page of a paginated admin listing (members, payments, audit logs).
class PagedResult<T> {
  final List<T> items;

  /// Total rows across all pages, as reported by the server.
  final int total;

  /// 1-based page number this result holds.
  final int page;
  final int limit;

  const PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  bool get hasMore => page * limit < total;
  bool get isEmpty => items.isEmpty;
}
