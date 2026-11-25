class OfficerContact {
  const OfficerContact({
    required this.id,
    required this.name,
    required this.nameBn,
    required this.designation,
    required this.designationBn,
    required this.upazila,
    required this.upazilaBn,
    required this.district,
    required this.districtBn,
    required this.division,
    required this.divisionBn,
    required this.phone,
    this.email = '',
    this.officeAddress = '',
    this.availableHours = '9:00 AM - 5:00 PM',
  });

  final String id;
  final String name;
  final String nameBn;
  final String designation;
  final String designationBn;
  final String upazila;
  final String upazilaBn;
  final String district;
  final String districtBn;
  final String division;
  final String divisionBn;
  final String phone;
  final String email;
  final String officeAddress;
  final String availableHours;

  factory OfficerContact.fromMap(Map<String, dynamic> map) {
    return OfficerContact(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      nameBn: map['nameBn'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
      designationBn: map['designationBn'] as String? ?? '',
      upazila: map['upazila'] as String? ?? '',
      upazilaBn: map['upazilaBn'] as String? ?? '',
      district: map['district'] as String? ?? '',
      districtBn: map['districtBn'] as String? ?? '',
      division: map['division'] as String? ?? '',
      divisionBn: map['divisionBn'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      officeAddress: map['officeAddress'] as String? ?? '',
      availableHours: map['availableHours'] as String? ?? '9:00 AM - 5:00 PM',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameBn': nameBn,
      'designation': designation,
      'designationBn': designationBn,
      'upazila': upazila,
      'upazilaBn': upazilaBn,
      'district': district,
      'districtBn': districtBn,
      'division': division,
      'divisionBn': divisionBn,
      'phone': phone,
      'email': email,
      'officeAddress': officeAddress,
      'availableHours': availableHours,
    };
  }
}
