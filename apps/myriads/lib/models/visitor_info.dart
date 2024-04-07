class VisitorSessionInfo {

  // Public methods and properties

  final String id;
  final String? walletId;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;

  VisitorSessionInfo({
    required this.id,
    this.walletId,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign
  });

}

class VisitorInfo {

  // Public methods and properties

  final String id;
  final List<VisitorSessionInfo> sessions;

  VisitorInfo({
    required this.id,
    required this.sessions
  });

}