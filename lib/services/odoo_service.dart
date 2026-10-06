import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:xml_rpc/client.dart' as xml_rpc;

import 'local_database.dart';

class OdooService {
  static const String baseUrl =
      'https://wear1.odoo.com';

  static const String database =
      'wear1';

  OdooClient? _client;

  bool _usingXmlRpc = false;

  int? _xmlRpcUid;
  String? _xmlRpcPassword;

  String authenticationMethod = '';

  final LocalDatabase _localDatabase =
      LocalDatabase.instance;

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> login(
    String username,
    String password,
  ) async {
    _resetAuthentication();

    try {
      await _loginPrimary(
        username,
        password,
      );

      _usingXmlRpc = false;

      authenticationMethod =
          'Odoo JSON-RPC / HTTP session';

      print(
        'LOGIN METHOD: $authenticationMethod',
      );
    } catch (primaryError) {
      print(
        'Primary authentication failed.',
      );

      print(
        'Trying XML-RPC fallback...',
      );

      await _loginXmlRpcFallback(
        username,
        password,
      );

      _usingXmlRpc = true;

      authenticationMethod =
          'XML-RPC fallback';

      print(
        'LOGIN METHOD: $authenticationMethod',
      );
    }

    _startConnectivityListener();

    await syncPendingPhoneUpdates();
  }

  // =========================================================
  // RESET AUTHENTICATION
  // =========================================================

  void _resetAuthentication() {
    try {
      _client?.close();
    } catch (_) {}

    _client = null;

    _usingXmlRpc = false;

    _xmlRpcUid = null;
    _xmlRpcPassword = null;

    authenticationMethod = '';
  }

  // =========================================================
  // PRIMARY LOGIN
  // =========================================================

  Future<void> _loginPrimary(
    String username,
    String password,
  ) async {
    final client =
        OdooClient(baseUrl);

    try {
      await client.authenticate(
        database,
        username,
        password,
      );

      if (client.sessionId == null) {
        throw Exception(
          'Authentication failed',
        );
      }

      _client = client;
    } catch (e) {
      client.close();
      rethrow;
    }
  }

  // =========================================================
  // XML-RPC FALLBACK
  // =========================================================

  Future<void> _loginXmlRpcFallback(
    String username,
    String password,
  ) async {
    final url = Uri.parse(
      '$baseUrl/xmlrpc/2/common',
    );

    final result =
        await xml_rpc.call(
      url,
      'authenticate',
      [
        database,
        username,
        password,
        <String, dynamic>{},
      ],
    );

    if (result == false ||
        result == null) {
      throw Exception(
        'Invalid username or password',
      );
    }

    final int? uid;

    if (result is int) {
      uid = result;
    } else {
      uid = int.tryParse(
        result.toString(),
      );
    }

    if (uid == null ||
        uid <= 0) {
      throw Exception(
        'XML-RPC authentication failed',
      );
    }

    _xmlRpcUid = uid;
    _xmlRpcPassword = password;
  }

  // =========================================================
  // GENERIC ODOO CALL
  // =========================================================

  Future<dynamic> _callKw({
    required String model,
    required String method,
    required List<dynamic> args,
    Map<String, dynamic> kwargs =
        const {},
  }) async {
    if (_usingXmlRpc) {
      return _callXmlRpc(
        model: model,
        method: method,
        args: args,
        kwargs: kwargs,
      );
    }

    if (_client == null) {
      throw Exception(
        'Not logged in',
      );
    }

    return _client!.callKw({
      'model': model,
      'method': method,
      'args': args,
      'kwargs': kwargs,
    });
  }

  // =========================================================
  // GENERIC XML-RPC CALL
  // =========================================================

  Future<dynamic> _callXmlRpc({
    required String model,
    required String method,
    required List<dynamic> args,
    Map<String, dynamic> kwargs =
        const {},
  }) async {
    final uid =
        _xmlRpcUid;

    final password =
        _xmlRpcPassword;

    if (uid == null ||
        password == null) {
      throw Exception(
        'Not logged in with XML-RPC',
      );
    }

    final url = Uri.parse(
      '$baseUrl/xmlrpc/2/object',
    );

    return xml_rpc.call(
      url,
      'execute_kw',
      [
        database,
        uid,
        password,
        model,
        method,
        args,
        kwargs,
      ],
    );
  }

  // =========================================================
  // CONNECTION LISTENER
  // =========================================================

  void _startConnectivityListener() {
    _connectivitySubscription?.cancel();

    _connectivitySubscription =
        Connectivity()
            .onConnectivityChanged
            .listen(
      (results) {
        final hasConnection =
            results.any(
          (result) =>
              result !=
              ConnectivityResult.none,
        );

        if (hasConnection) {
          syncPendingPhoneUpdates();
        }
      },
    );
  }

  // =========================================================
  // INTERNAL USER
  // =========================================================

  Future<bool> isInternalUser() async {
    final userId =
        _usingXmlRpc
            ? _xmlRpcUid
            : _client
                ?.sessionId
                ?.userId;

    if (userId == null) {
      throw Exception(
        'Not logged in',
      );
    }

    final result =
        await _callKw(
      model: 'res.users',
      method: 'has_group',
      args: [
        [userId],
        'base.group_user',
      ],
    );

    return result == true;
  }

  // =========================================================
  // CUSTOMERS
  // ONLINE -> ODOO + CACHE
  // OFFLINE -> CACHE
  // =========================================================

  Future<List<dynamic>>
      getCustomers() async {
    try {
      await syncPendingPhoneUpdates();

      final result =
          await _callKw(
        model: 'res.partner',
        method: 'search_read',
        args: [
          [
            [
              'customer_rank',
              '>',
              0,
            ]
          ]
        ],
        kwargs: {
          'fields': [
            'id',
            'name',
            'phone',
            'email',
            'street',
            'street2',
            'city',
            'zip',
            'state_id',
            'country_id',
          ],
          'limit': 50,
        },
      );

      final customers =
          List<dynamic>.from(
        result,
      );

      await _localDatabase
          .saveCustomers(
        customers,
      );

      print(
        'Customers downloaded from Odoo and cached locally.',
      );

      return customers;
    } catch (e) {
      print(
        'Odoo unavailable. Loading cached customers.',
      );

      final cachedCustomers =
          await _localDatabase
              .getCustomers();

      if (cachedCustomers.isEmpty) {
        rethrow;
      }

      return cachedCustomers;
    }
  }

  // =========================================================
  // UPDATE CUSTOMER PHONE
  //
  // ONLINE:
  // ODOO + LOCAL CACHE
  //
  // OFFLINE:
  // LOCAL CACHE + PENDING QUEUE
  // =========================================================

  Future<void> updateCustomerPhone(
    int customerId,
    String phone,
  ) async {
    // Update local copy immediately.
    await _localDatabase
        .updateCustomerPhoneLocally(
      customerId,
      phone,
    );

    try {
      await _updateCustomerPhoneRemote(
        customerId,
        phone,
      );

      print(
        'Phone updated directly in Odoo.',
      );
    } catch (e) {
      await _localDatabase
          .queuePhoneUpdate(
        customerId,
        phone,
      );

      print(
        'Offline: phone update saved locally and queued.',
      );
    }
  }

  // =========================================================
  // REMOTE PHONE UPDATE
  // =========================================================

  Future<void>
      _updateCustomerPhoneRemote(
    int customerId,
    String phone,
  ) async {
    final result =
        await _callKw(
      model: 'res.partner',
      method: 'write',
      args: [
        [customerId],
        {
          'phone': phone,
        }
      ],
    );

    if (result != true) {
      throw Exception(
        'Failed to update phone number',
      );
    }
  }

  // =========================================================
  // SYNC OFFLINE PHONE UPDATES
  // =========================================================

  Future<void>
      syncPendingPhoneUpdates() async {
    final pendingUpdates =
        await _localDatabase
            .getPendingPhoneUpdates();

    if (pendingUpdates.isEmpty) {
      return;
    }

    print(
      'Trying to sync ${pendingUpdates.length} offline update(s)...',
    );

    for (final update
        in pendingUpdates) {
      try {
        final queueId =
            update['id'] as int;

        final customerId =
            update['customer_id']
                as int;

        final phone =
            update['phone']
                .toString();

        await _updateCustomerPhoneRemote(
          customerId,
          phone,
        );

        await _localDatabase
            .removePendingUpdate(
          queueId,
        );

        print(
          'Synced phone update for customer $customerId.',
        );
      } catch (e) {
        print(
          'Sync stopped because Odoo is unavailable.',
        );

        break;
      }
    }
  }

  // =========================================================
  // SALES ORDERS
  // =========================================================

  Future<List<dynamic>>
      getSaleOrders() async {
    final result =
        await _callKw(
      model: 'sale.order',
      method: 'search_read',
      args: [
        []
      ],
      kwargs: {
        'fields': [
          'id',
          'name',
          'partner_id',
          'date_order',
          'state',
          'amount_total',
          'currency_id',
        ],
        'order':
            'date_order desc',
        'limit': 100,
      },
    );

    return List<dynamic>.from(
      result,
    );
  }

  // =========================================================
  // SALES ORDER LINES
  // =========================================================

  Future<List<dynamic>>
      getSaleOrderLines(
    int orderId,
  ) async {
    final result =
        await _callKw(
      model:
          'sale.order.line',
      method:
          'search_read',
      args: [
        [
          [
            'order_id',
            '=',
            orderId,
          ]
        ]
      ],
      kwargs: {
        'fields': [
          'id',
          'product_id',
          'name',
          'product_uom_qty',
          'price_unit',
          'price_subtotal',
        ],
        'order':
            'id asc',
      },
    );

    return List<dynamic>.from(
      result,
    );
  }

  // =========================================================
  // CONFIRM SALE ORDER
  // =========================================================

  Future<void> confirmSaleOrder(
    int orderId,
  ) async {
    await _callKw(
      model: 'sale.order',
      method:
          'action_confirm',
      args: [
        [orderId]
      ],
    );
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    await _connectivitySubscription
        ?.cancel();

    _connectivitySubscription =
        null;

    if (_client != null) {
      try {
        await _client!
            .destroySession();
      } catch (_) {}

      try {
        _client!.close();
      } catch (_) {}
    }

    _resetAuthentication();
  }
}