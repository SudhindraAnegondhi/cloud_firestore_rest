# Cloud Firestore REST API for Flutter

A Flutter Package to use the [Cloud Firestore API](https://firebase.google.com/docs/firestore/) by cross platform Flutter Apps.

This package supports Android, IOS, Linux, macOs platforms.

The package has not been tested on Windows platform but there
should be no technical reason for it not to function correctly in Windows environment.

## Contents

- [Cloud Firestore REST API for Flutter](#cloud-firestore-rest-api-for-flutter)
  - [Contents](#contents)
    - [Setup](#setup)
    - [Read from firestore](#read-from-firestore)
    - [Get Documents](#get-documents)
      - [Parameters](#parameters)
      - [Get() Usage](#get-usage)
    - [Get a document by ID](#get-a-document-by-id)
      - [Usage](#usage)
    - [Create new Document](#create-new-document)
    - [Update document](#update-document)
    - [Delete document](#delete-document)
    - [Authentication](#authentication)
      - [Signup](#signup)
      - [Signin](#signin)

### Setup

To use this package:

1. Using the [Firebase Console](http://console.firebase.google.com/), add a _web_ app to your project.
2. Go to **Project Settings** , copy
   1. Project ID
   2. Web API Key
3. Add `cloud_firestore_rest` and `global_configuration` as a [dependency](https://flutter.dev/docs/development/packages-and-plugins/using-packages) in your `pubspec.yaml` file.
4. Edit your app's `lib/main.dart`

   ```dart
   +import 'package:global_configuration/global_configuration.dart';
   ...

   void main()  {
    + GlobalConfiguration().loadFromMap({
    +  'projectId': '<project ID>',
    +  'webKey': 'web API key',
    +});
     runApp(MyApp());
   }
   ...

   ```

Of course, you may use any of the `GlobalConfiguration` load methods of your choice to configure your app. The package expects `projectId` and `webKey` to be available as part of global configuration.

### Read from firestore

### Get Documents

`Firestore.get()` may be used to read all documents in a collection or any documents that meet specified filters.

#### Parameters

**collection** _string_ _**required**_

 name of the collection root. example: 'users', 'users/seniors'

**sort** _List<Map<String, String>>_
  
To specifiy one or more sort fields

```dart
  sort: [
    { 'field: 'date', 'direction': 'ASCENDING' },
    { 'field: 'orderNumber' },
  ],
```

__Alternatively_, 
  If it's just one field you can use the **sortField** and **sortOrder** parameters.Direction can be either 'ASCENDING' or 'DESCENDING'.

**query** _List<Map<String, dynamic>>_

Multiple filters can be specified by using the **query** parameter.

Multiple filters can be specified. As on date Firestore
supports joining multiple filter conditions only using 'AND'.


```dart
  query: [
    Query(field: 'age', op: 'EQUAL', value: 31),
    Query(...)
  ],

```

Field logical operator - 
**op** can be omitted if you are testing equality. The op can be any one of the following strings:

`LESS_THAN,
  LESS_THAN_OR_EQUAL,
  GREATER_THAN,
  GREATER_THAN_OR_EQUAL,
  EQUAL,
  ARRAY_CONTAINS,
  IN,
  ARRAY_CONTAINS_ANY,`

```dart
   Future<List<Map<String, dynamic>>> get({
    @required String collection,
    String sortField,
    String sortOrder = 'ASCENDING',
    String keyField,
    String keyOp = 'EQUAL',
    String keyValue,
    List<Map<String, dynamic>> sort,
    List<Query> query,
  })
```

#### Get() Usage

```dart
import 'package:cloud_firestore_rest/cloud_firestore_rest.dart';

try {
List<Item> items = await getItems(query: [
  Query(field: 'orderDate', op: FieldOp.GREATER_THAN, value: searchDate),
  Query(field: 'customerId', value: searchId),
]);
} catch(error) {
  //handle error
}

```

### Get a document by ID

Cloud Firestore REST API generates a unique ID for each document stored in  a collection.

If the specified document could not be found, API throws an error.


#### Usage

```dart
try {
  final Map<String, dynamic> document = await Firestore.getDocument(
    collection: 'users',
    id: 'ACDZ638V565577'
  );
  // found!
} catch(error) {
  if(error.contains('NOT FOUND)) {
    // not found
  }
  // some other error
}

```

### Create new Document

Adds a new document to the specified collection. Creates a new collection if the collection did not exist.

The newly added document is returned along with _the id created by **Firestore**_.

```dart

try {
  final Map<String, dynamic> document = await Firestore.add(
    collection: 'orders',
    body: order.toJson
    );
  // document['id] contains the newly created document's id.
} catch (error) {
  // handle error
}

```

### Update document

Updates entire document. If document is not found, _adds the document
to the collection._

**Note**: If an entire document is not passed to this function, the API _will not_ throw error, instead will _write a truncated document_.

```dart
...

try {
  await Firstore.update(
    collection: 'orders',
    id: order.id,
    body: order.toJson,
  );
} catch(error) {
  // handle error
}

```



### Delete document

Deletes the document in the collection specified.

Throws error if document does not exist.

```dart
...

try {
  await Firstore.delete(
    collection: 'orders',
    id: order.id,
  );
} catch(error) {
  // handle error
}

```

### Authentication

#### Signup

SignUp registers a new email with [firebase](https://firebase.com)

```dart
...

try {
final Map<String, dynamic> auth = await Firestore.signInOrSignUp(
  email: 'test1@test.com',
  password: '123456',
  action: AuthAction.signUp,
);
} catch(error) {
  // handle errors including id already exists
}

```

#### Signin

```dart
...

try {
final Map<String, dynamic> auth = await Firestore.signInOrSignUp(
  email: 'test1@test.com',
  password: '123456',
  action: AuthAction.signInWithPassword
);
} catch(error) {
  // handle errors including id already exists
}

```

On successful authentication,  the function returns a map containing `idToken, expiryDate, userId, email` as keys.
