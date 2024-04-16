## Example

```Dart

final networkServiceProvider =
    Provider<NetworkService>((ref) => NetworkService(baseUrl: 'https://jsonplaceholder.typicode.com'));

var service = ref.read(networkServiceProvider);
final request = NetworkRequest(
  path: '/posts/2',
  type: NetworkRequestType.GET,
  data: NetworkRequestBody.empty(),
);
final response =
    await service.execute<Post>(request, Post.fromMap);
response.maybeWhen(
  ok: (data) {
    print(data.id);
  },
  noData: (message) {
    print(message);
  },
  orElse: () {
    print('other error');
  },
);
```