library cloud_firestore_rest;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:global_configuration/global_configuration.dart';

String _projectId = GlobalConfiguration().getString('projectId');
String _webKey = GlobalConfiguration().getString('webKey');
String _baseUrl =
    'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';
const _authUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:';

class Query {
  final String field;
  final FieldOp op;
  final dynamic value;
  final FilterOp connector;
  Query(
      {this.field,
      this.op = FieldOp.EQUAL,
      this.value,
      this.connector = FilterOp.NotSpecified});
}

///
///  A Flutter Package to use the **Cloud Firestore REST API**
///

class Firestore {
  ///
  /// Returns all documents in a collection as List<Map<String, dynamic>> .
  /// #### Parameters
  /// **collection** name of the collection root. example: 'users', 'users/seniors'
  /// #### Optional Parameters
  /// **sort** Specifies more than one sort fields List: [ {'field: 'date', 'direction': 'ASCENDING' },]. If it's just one field you may use **sortField**, **sortOrder** parameters.Direction can be either 'ASCENDING' or 'DESCENDING'.
  ///
  /// **query** Specifies multiple filters linked by *AND*.
  /// **query** is a List of Query objects.
  ///
  /// **keyField**, **keyOp**, **keyValue** can be used fopr single condition.
  ///
  ///
  static Future<List<Map<String, dynamic>>> get({
    String collection,
    String sortField,
    String sortOrder = 'ASCENDING',
    String keyField,
    String keyOp = 'EQUAL',
    String keyValue,
    List<Map<String, dynamic>> sort,
    List<Query> query,
  }) async {
    try {
      Map<String, Map<String, dynamic>> sQuery = {
        "structuredQuery": {
          "from": [
            {"collectionId": collection},
          ],
        }
      };
      if (sortField != null) {
        sQuery['structuredQuery']['orderBy'] = [
          {
            "field": {"fieldPath": sortField},
            "direction": sortOrder
          },
        ];
      } else if (sort != null) {
        List<Map<String, dynamic>> fields = [];
        sort.forEach((item) {
          fields.add({
            "field": {"fieldPath": item['field']},
            "direction": item['direction'],
          });
        });
        sQuery['structuredQuery']['orderBy'] = fields;
      }
      if (keyField != null) {
        sQuery['structuredQuery']['where'] = {
          "fieldFilter": {
            "field": {"fieldPath": keyField},
            "op": keyOp,
            "value": {_firestoreType(keyValue): keyValue},
          }
        };
      } else if (query != null) {
        List<Map<String, dynamic>> rows = [];

        // ensure input order
        for (int i = 0; i < query.length; i++) {
          rows.add({
            'fieldfilter': {
              "field": {"fieldPath": query[i].field},
              "op": describeEnum(query[i].op),
              "value": {_firestoreType(query[i].value): query[i].value},
            },
          });
        }
        // TODO: allow queries of aribitrary complexities

        sQuery['structuredQuery']['where'] = {
          "compositeFilter": {
            "filters": rows,
            "op": 'AND',
          }
        };
      }

      List<Map<String, dynamic>> items = [];
      final response = await http.post(
        '$_baseUrl:runQuery?key=$_webKey',
        body: json.encode(sQuery),
      );

      if (response.statusCode < 400) {
        final docs = json.decode(response.body);
        docs.forEach((doc) async {
          Map<String, dynamic> item = {};
          final fields = doc['document']['fields'];
          fields.forEach((k, v) => {item[k] = parse(v)});
          items.add(item);
        });
        return items;
      } else {
        throw HttpException(
            'Error reading $collection. ${response.reasonPhrase}');
      }
    } catch (error) {
      throw HttpException('Error reading $collection. ${error.toString()}');
    }
  }

  ///
  /// returns a single document from collection specified by **id** as *Map<String, dynamic> .
  ///
  /// Throws exception if document not found
  ///
  static Future<Map<String, dynamic>> getDocument({
    String collection,
    dynamic id,
  }) async {
    Map<String, dynamic> item = {};
    try {
      final response = await http.get(
          '$_baseUrl/$collection/${id.runtimeType.toString() == 'String' ? id : id.toString()}?key=$_webKey');

      if (response.statusCode < 400) {
        final doc = json.decode(response.body);
        final fields = doc['fields'];
        fields.forEach((k, v) => {item[k] = parse(v)});
        return item;
      } else {
        throw HttpException(
            'Error reading $collection. ${response.reasonPhrase}');
      }
    } catch (error) {
      throw HttpException('Error reading $collection. ${error.toString()}');
    }
  }

  /// Updates firestore document specified by **id**
  /// **body** contains a map with records contents
  ///
  /// *adds* a new document to the collection if there is no document corresponding to the **id**
  ///
  /// **collection** must exist
  ///
  /// throws exception on error
  ///

  static Future<void> setAll(
      {String collection, dynamic id, Map<String, dynamic> body}) async {
    try {
      final response = await http.put(
        '$_baseUrl/$collection/${id.runtimeType.toString() == 'String' ? id : id.toString()}?key=$_webKey',
        body: json.encode(serialize(body)),
      );
      if (response.statusCode >= 400) {
        if (response.statusCode == 404) {
          return await add(collection: collection, id: id, body: body);
        } else
          throw HttpException(
              'Error updating $collection. ${response.reasonPhrase}');
      }
    } catch (error) {
      throw HttpException('Error updating $collection. ${error.toString()}');
    }
  }

  /// Updates the fields contained in the **body** of the document identified by **id**
  /// **Note** Throws exception if corresponding document is not found.
  ///
  ///**collection** must exist
  ///
  /// throws exception on error

  static Future<void> set(
      {String collection, dynamic id, Map<String, dynamic> body}) async {
    try {
      final response = await http.patch(
        '$_baseUrl/$collection/${id.runtimeType.toString() == 'String' ? id : id.toString()}?key=$_webKey',
        body: json.encode(serialize(body)),
      );
      if (response.statusCode >= 400) {
        throw HttpException(
            'Error updating $collection. ${response.reasonPhrase}');
      }
    } catch (error) {
      throw HttpException('Error updating $collection. ${error.toString()}');
    }
  }

  ///
  /// Adds a record to the specified document/id.
  ///
  /// Creates a new collection if collection does not exist.
  ///
  /// Throws exception if record exists
  /// Throws exception on IO error
  ///
  static Future<void> add({String collection, dynamic id, dynamic body}) async {
    try {
      final response = await http.post(
        '$_baseUrl/$collection/${id.runtimeType.toString() == 'String' ? id : id.toString()}?key=$_webKey',
        body: json.encode(serialize(body)),
      );
      if (response.statusCode >= 400) {
        throw HttpException(
            'Error adding $collection. ${response.reasonPhrase}');
      }
    } catch (error) {
      throw HttpException('Error adding $collection. ${error.toString()}');
    }
  }

  ///
  /// Deletes a document identified by collection and id
  ///
  /// Throws exception if document does not exist
  /// Throws exception on I/O error

  static Future<void> delete({String collection, dynamic id}) async {
    try {
      await http.put(
          '$_baseUrl/$collection/${id.runtimeType.toString() == 'String' ? id : id.toString()}?key=$_webKey');
    } catch (error) {
      throw HttpException('Error deleting $collection. ${error.toString()}');
    }
  }

  ///
  /// Authentication API
  ///

  ///
  /// Returns idToken, expiryDate, userId in a Map
  /// if successful or null
  /// Specify either AuthAction.signUp for a new login
  /// registration or AuthAction.signInWithEmailPassword
  /// Throws Exception on failure or error
  ///

  static Future<Map<String, dynamic>> signInOrSignUp({
    String email,
    String password,
    AuthAction action,
  }) async {
    try {
      final response =
          await http.post('$_authUrl:${describeEnum(action)}?key=$_webKey');
      if (response.statusCode >= 400) {
        throw HttpException(response.reasonPhrase);
      }
      return json.decode(response.body);
    } catch (error) {
      throw HttpException(error.toString());
    }
  }
}

///
/// Specifes action to be taken with the passed email, password
///
enum AuthAction {
  signUp,
  signInWithEmailPassword,
}

///
///  Supporting methods & classes
///

// Deserialize/Serialize methods

///
/// returns integer value of argument passed.
/// returns double if value is double
/// Can be coerced to a double by passing double as type
///
dynamic _intTryParse(dynamic value, [String type]) {
  if (value == null) return 0;
  if (type != null && type == 'double') return _doubleTryParse(value);
  return value.runtimeType.toString() == 'String' ? int.tryParse(value) : value;
}

///
/// returns double value of argument passed.
/// returns integer if value is integer
/// Can be coerced to a integer by passing int as type
///
dynamic _doubleTryParse(dynamic value, [String type]) {
  if (value == null) return 0.0;
  if (type != null && type == 'int') return _intTryParse(value);
  var val = value.runtimeType.toString() == 'String' && !value.contains('.')
      ? value + '.0'
      : value * 1.0;
  return val.runtimeType.toString() == 'String' ? double.tryParse(val) : val;
}

///
/// returns the Google Firestore type of the value passed
///

String _firestoreType(dynamic value) {
  if (value is String) return 'stringValue';
  if (value is int) return 'integerValue';
  if (value is double) return 'doubleValue';
  if (value is bool) return 'booleanValue';
  if (value is DateTime) return 'timestampValue';
  if (value is Map) return 'MapValue';
  if (value is List) return 'ArrayValue';
  return 'stringValue';
}

///
/// Returns dart value from firestore value passed
/// Can coerce the return type by passing either 'int' or 'double' as type
///
dynamic parse(dynamic valueMap, [String type]) {
  dynamic fieldValue;
  if (valueMap == null) {
    return null;
  }

  valueMap.forEach((key, value) {
    try {
      switch (key) {
        case 'booleanValue':
          fieldValue = value as bool;
          break;
        case 'stringValue':
          fieldValue = value as String;
          break;
        case 'integerValue':
          fieldValue = _intTryParse(value, type);
          break;
        case 'doubleValue':
          fieldValue = _doubleTryParse(value, type);
          break;
        case 'timestampValue':
          fieldValue = value.runtimeType.toString() == 'String'
              ? DateTime.parse(value)
              : value;
          break;
        case 'mapValue':
          final fields = value['fields'] as Map<String, dynamic>;
          var arrayMap = {};
          fields.forEach((fkey, fvalue) {
            arrayMap[fkey] = parse(fvalue as Map<String, dynamic>);
          });
          fieldValue = arrayMap;
          break;
        case 'arrayValue':
          List<dynamic> list = [];
          final valList = value['values'] as List<dynamic>;
          if (valList != null)
            valList.forEach((item) {
              final fields = item['mapValue']['fields'] as Map<String, dynamic>;
              var arrayMap = {};
              fields.forEach((fkey, fvalue) {
                arrayMap[fkey] = parse(fvalue as Map<String, dynamic>);
              });
              list.add(arrayMap);
            });

          fieldValue = list;
          break;
        default:
          break;
      }
    } catch (error) {
      // print(error.toString());
      fieldValue = null;
    }
  });
  return fieldValue;
}

///
/// Returns a Map with firestore value objects
/// required by the API for updating firestore
///

Map<String, dynamic> serialize(Map<String, dynamic> item) {
  Map<String, dynamic> n = {};
  item.forEach((k, v) {
    n[k] = {_firestoreType(v): v};
  });
  return n;
}

///
/// Returns a Map with dart values for keys
/// given  a Map obtained from reading Firestore
/// can be coerced to int/double by passing
/// schema of the model
///
Map<String, dynamic> deserialize(Map<String, dynamic> fields,
    [Map<String, String> schema]) {
  Map<String, dynamic> items = {};

  fields.forEach((field, value) {
    var val = parse(value, schema[field]);
    items[field] = val;
  });
  return items;
}

///
///**HttpExeception(String message)**
///
/// Implements Exception class to encapsulate Http errors - both io errors
/// and http response errors as error text
///

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() {
    return message;
  }
}

enum FilterOp {
  NotSpecified,
  AND,
}

enum FieldOp {
  OPERATOR_UNSPECIFIED,
  LESS_THAN,
  LESS_THAN_OR_EQUAL,
  GREATER_THAN,
  GREATER_THAN_OR_EQUAL,
  EQUAL,
  ARRAY_CONTAINS,
  IN,
  ARRAY_CONTAINS_ANY,
}
