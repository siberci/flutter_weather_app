import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:havadurumu/models/weather_model.dart';

class WeatherService {
  // Kullanıcının konumunu güvenli şekilde alır
  Future<String> _getLocation() async {
    // Konum servisi açık mı kontrol
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error("Konum servisiniz kapalı");

    // Konum izni kontrolü
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Konum izni vermelisiniz");
      }
    }

    // Kullanıcının pozisyonunu al
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Pozisyondan yerleşim noktasını al
    final List<Placemark> placemark = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final String? city = placemark[0].administrativeArea;
    if (city == null) return Future.error("Konumdan şehir alınamadı");

    return city;
  }

  // Hava durumu verilerini API'den çeker
  Future<List<WeatherModel>> getWeatherData() async {
    final String city = await _getLocation();

    final String url =
        "https://api.collectapi.com/weather/getWeather?lang=tr&city=$city";
    const Map<String, dynamic> headers = {
      "authorization": "apikey 2iBbBMAZfRbYf9e2GmG2dV:7JjTW7erngmH2g3xCYqWBH",
      "content-type": "application/json",
    };

    final dio = Dio();
    final response = await dio.get(url, options: Options(headers: headers));

    if (response.statusCode != 200) {
      return Future.error("API’den veri alınamadı");
    }

    // API verisini kontrol et
    final data = response.data;

    List resultList = [];

    if (data is List) {
      // API direkt liste döndüyse
      resultList = data;
    } else if (data is Map && data['result'] is List) {
      // API map dönüp içinde 'result' listesi varsa
      resultList = data['result'];
    } else {
      return Future.error("API yanıtı beklenen formatta değil");
    }

    if (resultList.isEmpty) {
      return Future.error("API’den veri gelmedi");
    }

    // List'i WeatherModel listesine çevir
    final List<WeatherModel> weatherList =
        resultList.map((e) => WeatherModel.fromJson(e)).toList();

    return weatherList;
  }
}
