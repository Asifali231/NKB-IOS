class MyData_Class
{
  static Map<String, dynamic> _MyMapData = {};

  static Map<String, dynamic> get MyMapData => _MyMapData;

  static set MyMapData(Map<String, dynamic> value) {
    _MyMapData = value;
  }
}
