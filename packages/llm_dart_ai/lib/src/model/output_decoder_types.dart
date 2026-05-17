typedef JsonOutputDecoder<T> = T Function(Object? json);
typedef JsonObjectDecoder<T> = T Function(Map<String, Object?> json);
typedef JsonArrayElementDecoder<T> = T Function(Object? json);
