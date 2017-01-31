import 'dart:async';
import 'package:aqueduct/aqueduct.dart';

class RootObject extends ManagedObject<_RootObject> implements _RootObject {
  static int counter = 1;
  RootObject();
  RootObject.withCounter() {
    this.value1 = counter;
    this.value2 = counter;
    counter++;
  }

  bool operator ==(dynamic other) {
    return id == other.id;
  }
}

class _RootObject {
  @managedPrimaryKey
  int id;

  int value1;
  int value2;

  ManagedSet<ChildObject> children;
  ChildObject child;

  ManagedSet<RootJoinObject> join;
}

class ChildObject extends ManagedObject<_ChildObject> implements _ChildObject {
  static int counter = 1;
  ChildObject();
  ChildObject.withCounter() {
    this.value1 = counter;
    this.value2 = counter;
    counter++;
  }

  bool operator ==(dynamic other) {
    return id == other.id;
  }
}

class _ChildObject {
  @managedPrimaryKey
  int id;

  int value1;
  int value2;

  ManagedSet<GrandChildObject> grandChildren;
  GrandChildObject grandChild;

  @ManagedRelationship(#children)
  RootObject parents;

  @ManagedRelationship(#child)
  RootObject parent;
}

class GrandChildObject extends ManagedObject<_GrandChildObject>
    implements _GrandChildObject {
  static int counter = 1;
  GrandChildObject();
  GrandChildObject.withCounter() {
    this.value1 = counter;
    this.value2 = counter;
    counter++;
  }

  bool operator ==(dynamic other) {
    return id == other.id;
  }
}

class _GrandChildObject {
  @managedPrimaryKey
  int id;

  int value1;
  int value2;

  @ManagedRelationship(#grandChildren)
  ChildObject parents;

  @ManagedRelationship(#grandChild)
  ChildObject parent;
}

class OtherRootObject extends ManagedObject<_OtherRootObject>
    implements _OtherRootObject {
  static int counter = 1;
  OtherRootObject();
  OtherRootObject.withCounter() {
    this.value1 = counter;
    this.value2 = counter;
    counter++;
  }

  bool operator ==(dynamic other) {
    return id == other.id;
  }
}

class _OtherRootObject {
  @managedPrimaryKey
  int id;

  int value1;
  int value2;

  ManagedSet<RootJoinObject> join;
}

class RootJoinObject extends ManagedObject<_RootJoinObject>
    implements _RootJoinObject {
  bool operator ==(dynamic other) {
    return id == other.id;
  }
}

class _RootJoinObject {
  @managedPrimaryKey
  int id;

  @ManagedRelationship(#join)
  OtherRootObject other;

  @ManagedRelationship(#join)
  RootObject root;
}

Future<List<RootObject>> populateModelGraph(ManagedContext ctx) async {
  var rootObjects = <RootObject>[
    new RootObject.withCounter() // 1
      ..join = new ManagedSet.from([
        new RootJoinObject() // 1
          ..other = new OtherRootObject.withCounter(), // 1
        new RootJoinObject() // 2
          ..other = new OtherRootObject.withCounter() // 2
      ])
      ..child = (new ChildObject.withCounter() // 1
        ..grandChild = new GrandChildObject.withCounter() // 1
        ..grandChildren = new ManagedSet.from([
          new GrandChildObject.withCounter(), // 2
          new GrandChildObject.withCounter() // 3
        ]))
      ..children = new ManagedSet.from([
        (new ChildObject.withCounter() // 2
          ..grandChild = new GrandChildObject.withCounter() // 4
          ..grandChildren = new ManagedSet.from([
            new GrandChildObject.withCounter(), // 5
            new GrandChildObject.withCounter() // 6
          ])),
        (new ChildObject.withCounter() // 3
              ..grandChild = new GrandChildObject.withCounter() // 7
            ),
        (new ChildObject.withCounter() // 4
          ..grandChildren = new ManagedSet.from([
            new GrandChildObject.withCounter() // 8
          ])),
        new ChildObject.withCounter() // 5
      ]),
    new RootObject.withCounter() // 2
      ..join = new ManagedSet.from([
        new RootJoinObject() // 3
          ..other = new OtherRootObject.withCounter(), // 3
      ])
      ..child = new ChildObject.withCounter() // 6
      ..children = new ManagedSet.from([
        new ChildObject.withCounter() // 7
      ]),
    new RootObject.withCounter() // 3
      ..child = new ChildObject.withCounter(), // 8
    new RootObject.withCounter() // 4
      ..children = new ManagedSet.from([
        new ChildObject.withCounter() // 9
      ]),
    new RootObject.withCounter() // 5
  ];

  for (var root in rootObjects) {
    var q = new Query<RootObject>()..values = root;
    var r = await q.insert();
    root.id = r.id;

    if (root.child != null) {
      var child = root.child;
      child.parent = root;
      var cQ = new Query<ChildObject>()..values = child;
      child.id = (await cQ.insert()).id;

      if (child.grandChild != null) {
        var gc = child.grandChild;
        gc.parent = child;
        var gq = new Query<GrandChildObject>()..values = gc;
        gc.id = (await gq.insert()).id;
      }

      if (child?.grandChildren != null) {
        for (var gc in child.grandChildren) {
          gc.parents = child;
          var gq = new Query<GrandChildObject>()..values = gc;
          gc.id = (await gq.insert()).id;
        }
      }
    }

    if (root.children != null) {
      for (var child in root.children) {
        child.parents = root;
        var cQ = new Query<ChildObject>()..values = child;
        child.id = (await cQ.insert()).id;

        if (child.grandChild != null) {
          var gc = child.grandChild;
          gc.parent = child;
          var gq = new Query<GrandChildObject>()..values = gc;
          gc.id = (await gq.insert()).id;
        }

        if (child?.grandChildren != null) {
          for (var gc in child.grandChildren) {
            gc.parents = child;
            var gq = new Query<GrandChildObject>()..values = gc;
            gc.id = (await gq.insert()).id;
          }
        }
      }
    }

    if (root.join != null) {
      for (var join in root.join) {
        var otherQ = new Query<OtherRootObject>()..values = join.other;
        join.other.id = (await otherQ.insert()).id;

        join.root = new RootObject()..id = root.id;

        var joinQ = new Query<RootJoinObject>()..values = join;
        await joinQ.insert();
      }
    }
  }

  return rootObjects;
}