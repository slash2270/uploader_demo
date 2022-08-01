/// 配置服務器行為
class UploadServerBehavior {
  /// 用戶可見
  final String title;

  /// 後端服務器理解這一點
  final String name;

  UploadServerBehavior._(this.title, this.name);

  /// 默認行為
  static UploadServerBehavior defaultOk200 = UploadServerBehavior._('OK - 200', 'ok200');

  /// 所有可用的服務器行為。
  static List<UploadServerBehavior> all = [
    defaultOk200,
    UploadServerBehavior._('OK - 200, add random data', 'ok200randomdata'),
    UploadServerBehavior._('OK - 201', 'ok201'),
    UploadServerBehavior._('Error - 401', 'error401'),
    UploadServerBehavior._('Error - 403', 'error403'),
    UploadServerBehavior._('Error - 500', 'error500')
  ];
}