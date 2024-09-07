class Student {
  int id;
  String name;
  String idNumber;
  String schoolName;

  Student({
    required this.id,
    required this.name,
    required this.idNumber,
    required this.schoolName,
  });

  // Factory method to create a Student object from JSON
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,  // Assuming 'id' is always present in the backend, but default to 0 if null
      name: json['name'] ?? 'Unknown',  // Handle null name with a default 'Unknown'
      idNumber: json['id_number'] ?? 'N/A',  // Handle null id_number with 'N/A'
      schoolName: json['school_name'] ?? 'Unknown',  // Handle null school_name
    );
  }

  // Convert the Student object to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id_number': idNumber,
      'school_name': schoolName,
    };
  }
}