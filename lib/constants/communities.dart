/// Supported religious communities in FaithConnect
class Communities {
  static const String hindu = 'Hindu';
  static const String christian = 'Christian';
  static const String sikh = 'Sikh';
  static const String muslim = 'Muslim';
  static const String buddhist = 'Buddhist';
  static const String jain = 'Jain';
  static const String other = 'Other';

  /// List of all supported communities
  static const List<String> all = [
    hindu,
    christian,
    sikh,
    muslim,
    buddhist,
    jain,
    other,
  ];

  /// Validate if a community string is valid
  static bool isValid(String community) {
    return all.contains(community);
  }
}
