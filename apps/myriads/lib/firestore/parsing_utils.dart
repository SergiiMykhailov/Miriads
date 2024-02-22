ReturnValueType? tryGetValueFromMap<ReturnValueType>(Map<dynamic, dynamic> map, Object key) {
  ReturnValueType? result;

  final value = map[key];
  if (value is ReturnValueType) {
    result = value;
  }

  return result;
}

double? tryGetDecimalFromMap(Map<dynamic, dynamic> map, Object key) {
  final value = map[key];
  if (value is double) {
    return value;
  }
  else if (value is int) {
    return value.toDouble();
  }

  return null;
}

ReturnValueType getValueFromMapOrFallbackToValue<ReturnValueType>(
  Map<dynamic, dynamic> map,
  Object key,
  ReturnValueType fallbackValue
) {
  final resultCandidate = tryGetValueFromMap<ReturnValueType>(map, key);

  if (resultCandidate != null) {
    return resultCandidate;
  }
  else {
    return fallbackValue;
  }
}

List<ReturnValueType> getListFromMap<ReturnValueType>(
  Map<dynamic, dynamic> map,
  Object key
) {
  List<ReturnValueType> result = [];

  final array = map[key];
  if (array is List<dynamic>) {
    for (final element in array) {
      if (element is ReturnValueType) {
        result.add(element);
      }
    }
  }

  return result;
}