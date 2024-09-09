class Student {
  int? id;  // Nullable for new students without an id
  String name;
  String idNumber;
  String schoolName;

  Student({
    this.id,  // Nullable, used only for updates
    required this.name,
    required this.idNumber,
    required this.schoolName,
  });

  // Factory method to create a Student object from JSON
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],  // Parse the id from JSON
      name: json['name'] ?? 'Unknown',  // Provide default value if name is null
      idNumber: json['id_number'] ?? 'N/A',  // Handle missing id_number with a default value
      schoolName: json['school_name'] ?? 'Unknown',  // Provide default value if school_name is null
    );
  }

  // Convert the Student object to JSON
  Map<String, dynamic> toJson() {
    final data = {
      'name': name,
      'id_number': idNumber,
      'school_name': schoolName,
    };

    // Include 'id' only if it's not null (useful for updates)
    if (id != null) {
      data['id'] = id.toString();
    }

    return data;
  }
}
