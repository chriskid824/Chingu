import 'package:cloud_functions/cloud_functions.dart';

class CloudFunctionsService {
  final FirebaseFunctions _functions;

  CloudFunctionsService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<dynamic> callFunction(String name, [Map<String, dynamic>? data]) async {
    final HttpsCallable callable = _functions.httpsCallable(name);
    final HttpsCallableResult result = await callable.call(data);
    return result.data;
  }
}
