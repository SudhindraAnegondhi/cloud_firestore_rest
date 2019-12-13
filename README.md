# Cloud Firestore Package for Flutter

A Flutter Package to use the [Cloud Firestore API](https://firebase.google.com/docs/firestore/) by cross platform Flutter Apps.

## Setup

To use this package:

1. Using the [Firebase Console](http://console.firebase.google.com/), add a _web_ app to your project.
2. Go to **Project Settings** , copy down
   1. Project ID
   2. Web API Key
3. Add `cloud_firestore_rest` and `global_configuration` as a [dependency](https://flutter.dev/docs/development/packages-and-plugins/using-packages) in your `pubspec.yaml` file.
4. Edit `lib/main.dart` and edit code

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

Of course you may use any of the `GlobalConfiguration` load methods of your choice to configure your app. The package expects `projectId` and `webKey` to be available as part of global configuration.

## Usage

### Read from firestore

#### Performing a query

```dart
...

import 'package:cloud_firestore_rest/cloud_firestore_rest.dart';

Future<List<Item>> getItems({List<Query> query)}) {
  List<Item> items;
  final documents = await Firestore.get(
    collection: 'items',
    query: query,
    );
  documents.map((doc) => _items.add(Item.fromJson(doc)));
  return items;
}

...
try {
List<Item> items = await getItems(query: [
  Query(field: 'orderDate', op: FieldOp.GREATER, value: searchDate),
  Query(field: 'customerId', value: searchId),
]);
} catch(error) {
  //handle error

```

#### Get all documents from a collection

Call `Firestore.get(collection: 'collectionId')` without supplying a `query` argument to get _all_ the documents from the collection.

#### Get a specific document

```dart
...
Map<String, dynamic> document = await Firestore.getDocument(collection: 'items', id: searchId); // returns null if not found
Item item = Item.fromJson(document);
...


```

## Write to firestore

### Add new Collection/document

Creates a new collection if collection does not exist. Adds the document if the document does not exist.

```dart

try {
  await Firestore.add(
    collection: 'orders',
    id: order.id,
    body: order.toJson
    );
} catch (error) {
  // handle error
}

```

### Update document

#### Update a document, add if the document does not exist

Updates entire document. If document is not found, adds the document
to the collection.

**Note**: If an entire document is not passed to this function, the API _will not_ throw error, instead will _write a truncated document_.

```dart
...

try {
  await Firstore.setAll(
    collection: 'orders',
    id: order.id,
    body: order.toJson,
  );
} catch(error) {
  // handle error
}

```

#### Update fields in a document

Updates only the fields passed via the body argument. The fields _can_ be new - not part of the existing document.

If the document is not found, **Will not** add a new document, but _will_ throw error.

```dart
...

try {
  await Firstore.set(
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

