import '../models/officer_contact.dart';

/// Provides access to the Upazila Agriculture Officer (UAO) directory
/// and National Agricultural Helplines.
class ExtensionOfficerService {
  ExtensionOfficerService._();

  /// List of Divisions in Bangladesh
  static const List<String> divisions = [
    'All',
    'Dhaka',
    'Chittagong',
    'Rajshahi',
    'Khulna',
    'Barisal',
    'Sylhet',
    'Rangpur',
    'Mymensingh',
  ];

  static const Map<String, String> divisionNamesBn = {
    'All': 'সকল বিভাগ',
    'Dhaka': 'ঢাকা',
    'Chittagong': 'চট্টগ্রাম',
    'Rajshahi': 'রাজশাহী',
    'Khulna': 'খুলনা',
    'Barisal': 'বরিশাল',
    'Sylhet': 'সিলেট',
    'Rangpur': 'রংপুর',
    'Mymensingh': 'ময়মনসিংহ',
  };

  /// Static curated directory of Upazila Agriculture Officers (UAO)
  /// and DAE representatives across major agricultural hubs.
  static const List<OfficerContact> officerDirectory = [
    // Dhaka Division
    OfficerContact(
      id: 'uao_dhaka_savar',
      name: 'Dr. Md. Shafiul Alam',
      nameBn: 'ড. মোঃ শফিউল আলম',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Savar',
      upazilaBn: 'সাভার',
      district: 'Dhaka',
      districtBn: 'ঢাকা',
      division: 'Dhaka',
      divisionBn: 'ঢাকা',
      phone: '+8801711234567',
      email: 'uaosavar@dae.gov.bd',
      officeAddress: 'Upazila Parishad Complex, Savar, Dhaka',
    ),
    OfficerContact(
      id: 'uao_dhaka_dhamrai',
      name: 'Md. Faruk Hossain',
      nameBn: 'মোঃ ফারুক হোসেন',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Dhamrai',
      upazilaBn: 'ধামরাই',
      district: 'Dhaka',
      districtBn: 'ঢাকা',
      division: 'Dhaka',
      divisionBn: 'ঢাকা',
      phone: '+8801712345678',
      email: 'uaodhamrai@dae.gov.bd',
      officeAddress: 'Upazila Agriculture Office, Dhamrai, Dhaka',
    ),
    OfficerContact(
      id: 'uao_gazipur_sadar',
      name: 'Hasina Begum',
      nameBn: 'হাসিনা বেগম',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Gazipur Sadar',
      upazilaBn: 'গাজীপুর সদর',
      district: 'Gazipur',
      districtBn: 'গাজীপুর',
      division: 'Dhaka',
      divisionBn: 'ঢাকা',
      phone: '+8801713456789',
      email: 'uaogazipursadar@dae.gov.bd',
      officeAddress: 'DAE Complex, Rajbari, Gazipur',
    ),

    // Rajshahi Division (Mango / Grain hub)
    OfficerContact(
      id: 'uao_rajshahi_paba',
      name: 'Md. Shafiqul Islam',
      nameBn: 'মোঃ শফিকুল ইসলাম',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Paba',
      upazilaBn: 'পবা',
      district: 'Rajshahi',
      districtBn: 'রাজশাহী',
      division: 'Rajshahi',
      divisionBn: 'রাজশাহী',
      phone: '+8801714567890',
      email: 'uaopaba@dae.gov.bd',
      officeAddress: 'Upazila Complex, Paba, Rajshahi',
    ),
    OfficerContact(
      id: 'uao_rajshahi_charghat',
      name: 'Alim Uddin',
      nameBn: 'আলীম উদ্দিন',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Charghat',
      upazilaBn: 'চারঘাট',
      district: 'Rajshahi',
      districtBn: 'রাজশাহী',
      division: 'Rajshahi',
      divisionBn: 'রাজশাহী',
      phone: '+8801715678901',
      email: 'uaocharghat@dae.gov.bd',
      officeAddress: 'Charghat Upazila Campus, Rajshahi',
    ),
    OfficerContact(
      id: 'uao_bogra_sadan',
      name: 'Md. Enamul Haque',
      nameBn: 'মোঃ এনামুল হক',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Bogra Sadar',
      upazilaBn: 'বগুড়া সদর',
      district: 'Bogra',
      districtBn: 'বগুড়া',
      division: 'Rajshahi',
      divisionBn: 'রাজশাহী',
      phone: '+8801716789012',
      email: 'uaobograsadar@dae.gov.bd',
      officeAddress: 'DAE Complex, Banani, Bogra',
    ),

    // Rangpur Division (Potato & Paddy hub)
    OfficerContact(
      id: 'uao_rangpur_mithapukur',
      name: 'Saiful Islam',
      nameBn: 'সাইফুল ইসলাম',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Mithapukur',
      upazilaBn: 'মিঠাপুকুর',
      district: 'Rangpur',
      districtBn: 'রংপুর',
      division: 'Rangpur',
      divisionBn: 'রংপুর',
      phone: '+8801717890123',
      email: 'uaomithapukur@dae.gov.bd',
      officeAddress: 'Upazila Parishad, Mithapukur, Rangpur',
    ),
    OfficerContact(
      id: 'uao_dinajpur_sadar',
      name: 'Nargis Akter',
      nameBn: 'নারগিস আক্তার',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Dinajpur Sadar',
      upazilaBn: 'দিনাজপুর সদর',
      district: 'Dinajpur',
      districtBn: 'দিনাজপুর',
      division: 'Rangpur',
      divisionBn: 'রংপুর',
      phone: '+8801718901234',
      email: 'uaodinajpursadar@dae.gov.bd',
      officeAddress: 'DAE Compound, Suihari, Dinajpur',
    ),

    // Chittagong Division
    OfficerContact(
      id: 'uao_ctg_hathazari',
      name: 'Md. Nazmul Huda',
      nameBn: 'মোঃ নাজমুল হুদা',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Hathazari',
      upazilaBn: 'হাটহাজারী',
      district: 'Chittagong',
      districtBn: 'চট্টগ্রাম',
      division: 'Chittagong',
      divisionBn: 'চট্টগ্রাম',
      phone: '+8801719012345',
      email: 'uaohathazari@dae.gov.bd',
      officeAddress: 'Upazila Complex, Hathazari, Chittagong',
    ),
    OfficerContact(
      id: 'uao_comilla_sadar',
      name: 'Dr. Shahabuddin',
      nameBn: 'ড. শাহাবুদ্দিন',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Comilla Sadar',
      upazilaBn: 'কুমিল্লা সদর',
      district: 'Comilla',
      districtBn: 'কুমিল্লা',
      division: 'Chittagong',
      divisionBn: 'চট্টগ্রাম',
      phone: '+8801720123456',
      email: 'uaocomillasadar@dae.gov.bd',
      officeAddress: 'KOTBARI DAE Office, Comilla',
    ),

    // Khulna Division
    OfficerContact(
      id: 'uao_khulna_dumuria',
      name: 'Mosammat Rehana Khatun',
      nameBn: 'মোসাম্মাৎ রেহানা খাতুন',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Dumuria',
      upazilaBn: 'ডুমুরিয়া',
      district: 'Khulna',
      districtBn: 'খুলনা',
      division: 'Khulna',
      divisionBn: 'খুলনা',
      phone: '+8801721234567',
      email: 'uaodumuria@dae.gov.bd',
      officeAddress: 'Upazila Parishad, Dumuria, Khulna',
    ),
    OfficerContact(
      id: 'uao_jessore_sadar',
      name: 'Sajjad Hossain',
      nameBn: 'সাজ্জাদ হোসেন',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Jessore Sadar',
      upazilaBn: 'যশোর সদর',
      district: 'Jessore',
      districtBn: 'যশোর',
      division: 'Khulna',
      divisionBn: 'খুলনা',
      phone: '+8801722345678',
      email: 'uaojessoresadar@dae.gov.bd',
      officeAddress: 'Chanchra DAE Office, Jessore',
    ),

    // Mymensingh Division
    OfficerContact(
      id: 'uao_mymensingh_sadar',
      name: 'Kazi Mahbubur Rahman',
      nameBn: 'কাজী মাহবুবুর রহমান',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Mymensingh Sadar',
      upazilaBn: 'ময়মনসিংহ সদর',
      district: 'Mymensingh',
      districtBn: 'ময়মনসিংহ',
      division: 'Mymensingh',
      divisionBn: 'ময়মনসিংহ',
      phone: '+8801723456789',
      email: 'uaomymensinghsadar@dae.gov.bd',
      officeAddress: 'Khamarbari Compound, Mymensingh',
    ),

    // Barisal Division
    OfficerContact(
      id: 'uao_barisal_babuganj',
      name: 'Md. Moniruzzaman',
      nameBn: 'মোঃ মনিরুজ্জামান',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Babuganj',
      upazilaBn: 'বাবুগঞ্জ',
      district: 'Barisal',
      districtBn: 'বরিশাল',
      division: 'Barisal',
      divisionBn: 'বরিশাল',
      phone: '+8801724567890',
      email: 'uaobabuganj@dae.gov.bd',
      officeAddress: 'Upazila Complex, Babuganj, Barisal',
    ),

    // Sylhet Division
    OfficerContact(
      id: 'uao_sylhet_golapganj',
      name: 'Anowar Hossain',
      nameBn: 'আনোয়ার হোসেন',
      designation: 'Upazila Agriculture Officer (UAO)',
      designationBn: 'উপজেলা কৃষি অফিসার (ইউএও)',
      upazila: 'Golapganj',
      upazilaBn: 'গোলাপগঞ্জ',
      district: 'Sylhet',
      districtBn: 'সিলেট',
      division: 'Sylhet',
      divisionBn: 'সিলেট',
      phone: '+8801725678901',
      email: 'uaogolapganj@dae.gov.bd',
      officeAddress: 'Golapganj Upazila Office, Sylhet',
    ),
  ];

  /// Filters officers by search query and optional division.
  static List<OfficerContact> searchOfficers({
    String query = '',
    String selectedDivision = 'All',
  }) {
    final q = query.trim().toLowerCase();
    return officerDirectory.where((officer) {
      final matchesDivision =
          selectedDivision == 'All' || officer.division == selectedDivision;
      if (!matchesDivision) return false;
      if (q.isEmpty) return true;

      return officer.name.toLowerCase().contains(q) ||
          officer.nameBn.contains(q) ||
          officer.upazila.toLowerCase().contains(q) ||
          officer.upazilaBn.contains(q) ||
          officer.district.toLowerCase().contains(q) ||
          officer.districtBn.contains(q) ||
          officer.designation.toLowerCase().contains(q) ||
          officer.designationBn.contains(q);
    }).toList();
  }
}
