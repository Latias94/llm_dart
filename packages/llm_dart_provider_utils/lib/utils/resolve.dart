/// Resolves a value that can be a raw value, a Future, or a function returning
/// either.
///
/// Mirrors Vercel AI SDK's `resolve(...)`.
Future<T> resolve<T>(Object? value) async {
  Object? current = value;

  if (current is Function) {
    current = current();
  }

  if (current is Future) {
    return (await current) as T;
  }

  return current as T;
}
