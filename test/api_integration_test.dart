import 'dart:convert';

import 'package:ajoplus/models/savings_group.dart';
import 'package:ajoplus/providers/app_provider.dart';
import 'package:ajoplus/services/api_client.dart';
import 'package:ajoplus/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemoryCredentials extends CredentialStore {
  String? accessToken;
  String? refreshToken;
  MemoryCredentials({this.accessToken, this.refreshToken});

  @override
  Future<String?> get access async => accessToken;
  @override
  Future<String?> get refresh async => refreshToken;
  @override
  Future<void> save(String access, String refresh) async {
    accessToken = access;
    refreshToken = refresh;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

final user = {
  'id': 7,
  'name': 'Ada Okafor',
  'email': 'ada@example.com',
  'phone': '08012345678',
  'created_at': '2026-09-30T12:00:00.000000Z',
};
final group = {
  'id': 3,
  'creator_id': 7,
  'name': 'Savings circle',
  'description': 'Monthly savings',
  'contribution_amount_kobo': 125050,
  'frequency': 'monthly',
  'max_members': 2,
  'requires_approval': false,
  'start_date': '2026-10-01',
  'invite_code': 'ABCD1234',
  'current_cycle': 1,
  'created_at': '2026-09-30T12:00:00.000000Z',
};
http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);
Map<String, Object?> page(List<Object?> data) => {'data': data, 'last_page': 1};

void main() {
  test('expired access token rotates and retries once', () async {
    final calls = <String>[];
    final credentials = MemoryCredentials(
      accessToken: 'old',
      refreshToken: 'refresh',
    );
    final api = ApiClient(
      baseUri: Uri.parse('https://example.com/api/v1/'),
      credentials: credentials,
      httpClient: MockClient((request) async {
        calls.add(
          '${request.url.path}:${request.headers['Authorization'] ?? ''}',
        );
        if (request.url.path.endsWith('auth/refresh')) {
          expect(jsonDecode(request.body)['refresh_token'], 'refresh');
          return jsonResponse({'token': 'new', 'refresh_token': 'new-refresh'});
        }
        if (request.headers['Authorization'] == 'Bearer old') {
          return jsonResponse({'message': 'Unauthenticated.'}, 401);
        }
        return jsonResponse({'user': user});
      }),
    );
    await api.restore();
    final restored = await AuthService(api).restore();
    expect(restored!.fullName, 'Ada Okafor');
    expect(credentials.accessToken, 'new');
    expect(credentials.refreshToken, 'new-refresh');
    expect(calls.where((call) => call.contains('auth/refresh')).length, 1);
  });

  test('invalid refresh clears credentials and signals sign out', () async {
    final credentials = MemoryCredentials(
      accessToken: 'old',
      refreshToken: 'expired',
    );
    final api = ApiClient(
      baseUri: Uri.parse('https://example.com/api/v1/'),
      credentials: credentials,
      httpClient: MockClient(
        (request) async => jsonResponse({'message': 'Unauthenticated.'}, 401),
      ),
    );
    await api.restore();
    var signedOut = false;
    api.onUnauthorized = () => signedOut = true;
    await expectLater(api.get('auth/me'), throwsA(isA<ApiException>()));
    expect(signedOut, isTrue);
    expect(credentials.accessToken, isNull);
    expect(credentials.refreshToken, isNull);
  });

  test(
    'logout revokes the rotated refresh token after access expiry',
    () async {
      final credentials = MemoryCredentials(
        accessToken: 'expired-access',
        refreshToken: 'old-refresh',
      );
      final logoutBodies = <Map<String, dynamic>>[];
      final api = ApiClient(
        baseUri: Uri.parse('https://example.com/api/v1/'),
        credentials: credentials,
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('auth/refresh')) {
            return jsonResponse({
              'token': 'new-access',
              'refresh_token': 'new-refresh',
            });
          }
          logoutBodies.add(
            Map<String, dynamic>.from(jsonDecode(request.body) as Map),
          );
          if (request.headers['Authorization'] == 'Bearer expired-access') {
            return jsonResponse({'message': 'Unauthenticated.'}, 401);
          }
          return jsonResponse({'message': 'Logged out.'});
        }),
      );
      await api.restore();
      await AuthService(api).logout();
      expect(logoutBodies.last['refresh_token'], 'new-refresh');
      expect(credentials.accessToken, isNull);
      expect(credentials.refreshToken, isNull);
    },
  );

  test(
    'group data and kobo amounts come from paginated API responses',
    () async {
      final calls = <String>[];
      final api = ApiClient(
        baseUri: Uri.parse('https://example.com/api/v1/'),
        httpClient: MockClient((request) async {
          calls.add(request.url.path);
          final path = request.url.path;
          if (path.endsWith('/groups')) return jsonResponse(page([group]));
          if (path.endsWith('/groups/3')) {
            return jsonResponse({
              ...group,
              'members': [
                {
                  'id': 11,
                  'group_id': 3,
                  'user_id': 7,
                  'payout_position': 1,
                  'joined_at': '2026-09-30T12:00:00.000000Z',
                  'user': {'id': 7, 'name': 'Ada Okafor'},
                },
              ],
              'payouts': [],
            });
          }
          if (path.endsWith('/groups/3/contributions')) {
            return jsonResponse(
              page([
                {
                  'id': 21,
                  'group_id': 3,
                  'member_id': 11,
                  'cycle': 1,
                  'amount_kobo': 125050,
                  'status': 'pending',
                  'payment_reference': null,
                  'paid_at': null,
                },
              ]),
            );
          }
          if (path.endsWith('/groups/3/schedule')) {
            return jsonResponse({
              'data': [
                {
                  'cycle': 1,
                  'recipient': {'id': 7, 'name': 'Ada Okafor'},
                  'scheduled_for': '2026-10-01',
                  'amount_kobo': 250100,
                  'status': 'pending',
                },
              ],
            });
          }
          if (path.endsWith('/transactions') ||
              path.endsWith('/notifications')) {
            return jsonResponse(page([]));
          }
          return jsonResponse({'message': 'Not found'}, 404);
        }),
      );
      final app = AppProvider(api: api);
      await app.refresh();
      expect(app.groups.single.name, 'Savings circle');
      expect(app.ownContribution(app.groups.single, '7')!.amountKobo, 125050);
      expect(
        app.nextContribution('7', DateTime(2026, 9, 30))!.dueDate,
        DateTime(2026, 10, 1),
      );
      expect(calls, contains('/api/v1/groups/3/contributions'));
      expect(app.loadError, isNull);
      app.dispose();
    },
  );

  test('malformed required API money fails at the boundary', () {
    expect(
      () => SavingsGroup.fromApi({
        ...group,
        'contribution_amount_kobo': '1250.50',
      }),
      throwsA(isA<ApiException>()),
    );
  });

  test(
    'a join request stays pending until the organizer approves it',
    () async {
      final api = ApiClient(
        baseUri: Uri.parse('https://example.com/api/v1/'),
        credentials: MemoryCredentials(accessToken: 'access'),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/groups/join');
          expect(jsonDecode(request.body), {'invite_code': 'ABCD1234'});
          return jsonResponse({'group_id': 3, 'join_status': 'pending'}, 202);
        }),
      );
      final app = AppProvider(api: api);

      final result = await app.join('abcd1234');

      expect(result.groupId, '3');
      expect(result.pendingApproval, isTrue);
      app.dispose();
    },
  );
}
