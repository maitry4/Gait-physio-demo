class UserModel {
  final String id;
  final String name;
  final int age;
  final String dateAdded;

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.dateAdded,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'date_added': dateAdded,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      age: map['age'] as int,
      dateAdded: map['date_added'] as String,
    );
  }
}
