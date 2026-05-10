List<TResult> parseTypedParts<TPart, TResult>(
  Iterable<TPart> parts,
  TResult? Function(TPart part) parse,
) {
  return List<TResult>.unmodifiable([
    for (final part in parts)
      if (parse(part) case final result?) result,
  ]);
}
