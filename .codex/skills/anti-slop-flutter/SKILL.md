---
name: anti-slop-flutter
description: Simplify Flutter and Dart code by removing defensive over-engineering, unnecessary widget abstractions, excessive state management, fake null safety, redundant models and mappers, pointless repositories/services, async ceremony, and AI-generated architectural noise.
---

# Flutter Anti-Slop

Apply these rules whenever modifying Flutter or Dart code.

The goal is simple, readable, idiomatic Flutter that uses Dart's type system properly, keeps widget trees understandable, introduces architecture only where it solves a real problem, and validates uncertainty only at genuine boundaries.

## Core rule

> Validate external data at the boundary. Trust typed Dart code everywhere else.

Also:

> Do not turn ordinary Flutter development into an architecture exercise.

Prefer the simplest design that preserves correctness, maintainability, testability, and existing project conventions.

---

# 1. Do not propagate `dynamic` unnecessarily

Be suspicious of:

```dart
dynamic data;
dynamic payload;
Map<String, dynamic> value;
Map<String, Object?> value;
```

inside normal application logic.

If the shape is known, use the actual type.

Bad:

```dart
void handleUser(dynamic data) {
  final name = data['name'] as String?;
}
```

Good:

```dart
void handleUser(User user) {
  print(user.name);
}
```

Fix broad typing at the source instead of carrying `dynamic` through the application.

---

# 2. `Map<String, dynamic>` belongs near JSON boundaries

This is reasonable:

```dart
factory User.fromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}
```

This is suspicious:

```dart
Future<void> updateProfile(
  Map<String, dynamic> user,
) async {
  // business logic
}
```

Once JSON has been parsed, application code should normally work with typed models.

Desired flow:

```text
API JSON
→ parse
→ typed model
→ application logic
```

Not:

```text
API JSON
→ Map<String, dynamic>
→ service
→ provider
→ widget
→ repeated casts
```

---

# 3. Do not replace Dart's type system with runtime ceremony

Bad:

```dart
if (value is Map<String, dynamic>) {
  if (value['name'] is String) {
    final name = value['name'] as String;
  }
}
```

when the value is already supposed to be:

```dart
User user
```

Use runtime validation only where data is genuinely untrusted.

Do not repeatedly rediscover types that Dart already knows.

---

# 4. Do not use `dynamic` because typing is inconvenient

Bad:

```dart
dynamic selectedUser;
dynamic response;
dynamic item;
```

Ask:

> What is this value actually supposed to represent?

Prefer:

```dart
User? selectedUser;
ApiResponse response;
Product item;
```

Do not weaken types just to avoid defining the correct domain shape.

---

# 5. Avoid fake null safety

Do not add `?`, `??`, `?.`, and empty defaults everywhere merely because a value might theoretically be absent.

Bad:

```dart
final name =
    user?.profile?.name ?? '';
```

when the application contract guarantees:

```dart
User user;
Profile profile;
String name;
```

Prefer:

```dart
final name = user.profile.name;
```

Nullability must reflect real application semantics.

---

# 6. Do not make every field nullable

Bad:

```dart
class User {
  final String? id;
  final String? name;
  final String? email;
  final Profile? profile;
}
```

when these fields are required after authentication.

Prefer:

```dart
class User {
  final String id;
  final String name;
  final String email;
  final Profile profile;
}
```

Do not model malformed API responses as valid application states.

Parse or reject malformed data at the boundary.

---

# 7. Avoid multiple absence states

Question types like:

```dart
String?
List<Item>?
```

when:

```dart
String
List<Item>
```

with an explicit domain state would be clearer.

Also avoid having all of:

```text
null
""
[]
loading == false
loaded == false
initialized == false
```

represent the same conceptual state.

Model state intentionally.

---

# 8. Do not silently convert invalid data into empty values

Be suspicious of:

```dart
value ?? ''
value ?? []
value ?? {}
```

when absence indicates invalid application state.

Bad:

```dart
final userId = user?.id ?? '';
```

If the operation requires an authenticated user, the system should not proceed using an empty ID.

Prefer a meaningful invariant or explicit failure.

---

# 9. Keep legitimate fallbacks

This is not a ban on defaults.

Defaults are appropriate when the domain explicitly allows them.

Example:

```dart
final displayName =
    user.nickname ?? user.name;
```

That represents real business semantics.

This:

```dart
final userId = user.id ?? '';
```

usually does not.

---

# 10. Avoid unnecessary `late`

Be suspicious of:

```dart
late User user;
late TextEditingController controller;
late String token;
```

Ask whether the value can be initialized immediately.

Prefer:

```dart
final controller = TextEditingController();
```

or constructor initialization where appropriate.

Use `late` when lifecycle-based initialization genuinely requires it.

---

# 11. Avoid unnecessary force unwraps

Search for:

```dart
value!
user!
response.data!
```

A force unwrap should correspond to a real invariant.

Do not scatter `!` merely to silence analyzer errors.

If the value can genuinely be null, handle that state.

If it cannot, improve its type or lifecycle.

---

# 12. Do not overreact to every `!`

At the same time, do not replace one legitimate invariant:

```dart
_formKey.currentState!.validate();
```

with excessive defensive machinery if Flutter's lifecycle and surrounding logic guarantee the state exists.

Use judgment.

---

# 13. Parse external JSON once

External APIs are boundaries.

Do:

```text
HTTP response
→ decode
→ fromJson
→ typed object
```

Do not keep re-reading JSON maps throughout the UI.

Bad:

```dart
Text(
  response['data']['user']['profile']['name']
      ?.toString() ??
      '',
)
```

Prefer:

```dart
Text(user.profile.name)
```

---

# 14. Do not put JSON parsing in widgets

Bad:

```dart
Widget build(BuildContext context) {
  final user = User.fromJson(response.data);
  ...
}
```

Parsing belongs near the network/data boundary.

Widgets should preferably receive data that is ready to display.

---

# 15. Avoid generic JSON helpers

Be suspicious of:

```dart
getString()
getInt()
getBool()
getList()
safeString()
safeInt()
parseValue()
getValue<T>()
```

used across known API models.

Bad:

```dart
final name = getString(json, 'name');
```

Prefer:

```dart
name: json['name'] as String,
```

or the serialization approach already used by the project.

Generic access helpers often hide unclear contracts.

---

# 16. Use the project's existing serialization approach

If the project already uses:

```text
json_serializable
freezed
built_value
manual fromJson/toJson
```

follow that approach.

Do not introduce another model/serialization package merely because you are touching one endpoint.

---

# 17. Do not create models for every temporary shape

Avoid unnecessary chains such as:

```text
UserResponse
UserResponseData
UserDTO
UserEntity
UserModel
UserViewModel
UserPayload
```

when they contain almost identical fields.

Separate representations only when their contracts genuinely differ.

---

# 18. Remove meaningless mapper layers

Audit:

```dart
toEntity()
fromEntity()
toModel()
fromModel()
toDto()
fromDto()
toDomain()
```

If they copy identical fields:

```dart
UserEntity(
  id: model.id,
  name: model.name,
)
```

ask whether both types need to exist.

Mapping code needs a semantic reason.

---

# 19. Do not blindly copy Clean Architecture diagrams

Flutter code does not automatically need:

```text
presentation
domain
data
repositories
datasources
usecases
entities
models
mappers
core
```

for every feature.

Architecture must match project scale and complexity.

A five-screen application does not need twenty-five abstraction layers.

---

# 20. Avoid repository ceremony

A repository is useful when it abstracts meaningful data-access decisions.

This may be justified:

```text
UserRepository
→ remote API
→ local cache
→ synchronization policy
```

This is suspicious:

```dart
class UserRepository {
  UserRepository(this.api);

  final UserApi api;

  Future<User> getUser() {
    return api.getUser();
  }
}
```

when every method merely forwards arguments.

Do not preserve layers solely because an architecture tutorial showed them.

---

# 21. Avoid pointless service wrappers

Bad:

```dart
class UserService {
  final UserRepository repository;

  Future<User> getUser(String id) {
    return repository.getUser(id);
  }
}
```

if it adds no business logic.

A layer should own meaningful behavior, policy, transformation, orchestration, or abstraction.

---

# 22. Avoid one-class-per-action use cases without reason

Be suspicious of:

```text
GetUserUseCase
UpdateUserUseCase
DeleteUserUseCase
GetProductsUseCase
CreateProductUseCase
```

where each class contains:

```dart
return repository.method();
```

Use cases can be valuable in complex domains.

They are not mandatory wrappers around every repository call.

---

# 23. Avoid dependency injection ceremony

Constructor injection is usually enough:

```dart
UserController(
  this.userRepository,
);
```

Do not introduce elaborate:

```text
ServiceLocator
DependencyContainer
Registry
Resolver
ProviderFactory
InjectionModule
```

without a real need.

If the project already uses GetIt, Riverpod, Provider, etc., follow the existing convention without adding another DI system.

---

# 24. Do not introduce state management casually

Before adding:

```text
Bloc
Riverpod
Provider
GetX
MobX
Redux
Signals
```

ask whether existing Flutter mechanisms are sufficient.

For local UI state:

```dart
setState
ValueNotifier
TextEditingController
AnimationController
```

may be completely adequate.

Use application-wide state tooling when the state actually crosses meaningful boundaries.

---

# 25. Do not replace simple `setState` just to look architectural

Bad:

```text
Dropdown selection
→ event
→ bloc
→ reducer
→ state
→ builder
```

for a value used by one widget.

Prefer:

```dart
setState(() {
  selectedValue = value;
});
```

when the state is local.

Simple code is not immature code.

---

# 26. Do not put global state management around ephemeral UI state

Examples usually local to a widget:

```text
selected tab
password visibility
expanded section
current carousel page
temporary form value
hover state
focus state
animation progress
```

Do not make them application state unless another part of the application genuinely needs them.

---

# 27. Do not create Providers for every object

Bad:

```text
ThemeButtonProvider
PasswordVisibilityProvider
DropdownProvider
LoadingProvider
DialogProvider
```

State ownership should follow actual application boundaries.

---

# 28. Keep state close to where it is used

Prefer:

```text
local widget state
```

before:

```text
feature state
```

before:

```text
application state
```

Move state upward only when consumers require it.

---

# 29. Avoid generic loading booleans everywhere

Be suspicious of:

```dart
bool isLoading = false;
bool hasError = false;
String? errorMessage;
User? data;
```

if mutually exclusive states are becoming hard to reason about.

For sufficiently complex asynchronous state, use an explicit state model.

For simple calls, do not build an entire state machine unnecessarily.

Use complexity proportional to the problem.

---

# 30. Prefer explicit states when states are truly mutually exclusive

For meaningful state machines:

```dart
sealed class UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  UserLoaded(this.user);

  final User user;
}

class UserFailed extends UserState {
  UserFailed(this.error);

  final Object error;
}
```

may be clearer than several independent booleans.

But do not introduce sealed state hierarchies for every button request.

---

# 31. Avoid state duplication

Bad:

```dart
User? user;
String? userName;
String? userEmail;
String? userAvatar;
```

when all fields derive from:

```dart
User user;
```

Do not maintain multiple sources of truth unnecessarily.

---

# 32. Derive values instead of synchronizing them manually

Bad:

```dart
bool hasItems = false;

void updateItems(List<Item> value) {
  items = value;
  hasItems = items.isNotEmpty;
}
```

Prefer:

```dart
bool get hasItems => items.isNotEmpty;
```

Do not store derived state unless there is a genuine performance or lifecycle reason.

---

# 33. Avoid copying state merely "for safety"

Be suspicious of:

```dart
final copiedItems = [...items];
final newUser = user.copyWith();
```

if nothing is mutating the original.

Copy when immutability or ownership requires it.

Do not allocate because copying feels safer.

---

# 34. Keep widget trees readable

Avoid both extremes:

### Giant build method

```dart
Widget build(BuildContext context) {
  // 700 lines
}
```

and:

### Fragment explosion

```text
_buildTitle()
_buildSubtitle()
_buildIcon()
_buildSpacer()
_buildPadding()
_buildCard()
_buildRow()
_buildText()
```

Extract meaningful UI concepts.

---

# 35. Do not extract every widget into a method

Bad:

```dart
Widget _buildTitle() {
  return Text('Profile');
}
```

used once.

Prefer:

```dart
const Text('Profile')
```

inline when it remains readable.

---

# 36. Prefer widget classes when extracted UI has real identity

An extracted widget is useful when it has:

- meaningful inputs
- reuse
- substantial rendering logic
- isolated rebuild behavior
- independent testing value
- a clear UI concept

Example:

```dart
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    required this.transaction,
    super.key,
  });

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    ...
  }
}
```

That represents a real component.

---

# 37. Do not create widgets for one-line wrappers

Be suspicious of:

```dart
class Gap8 extends StatelessWidget
class StandardPadding extends StatelessWidget
class AppCenter extends StatelessWidget
```

unless they represent an established design-system primitive.

Flutter already has:

```dart
SizedBox
Padding
Center
Align
Container
```

Do not abstract the framework itself.

---

# 38. Avoid Container abuse

Do not automatically use:

```dart
Container(
  padding: ...,
  margin: ...,
  alignment: ...,
  child: ...,
)
```

when a more specific widget communicates intent.

Prefer:

```dart
Padding
SizedBox
Align
ColoredBox
DecoratedBox
```

where appropriate.

But do not rewrite working `Container` code merely to satisfy style purity.

---

# 39. Avoid nested layout ceremony

Bad:

```dart
Container(
  child: Padding(
    padding: ...,
    child: Container(
      child: Align(
        child: Center(
          child: ...
        ),
      ),
    ),
  ),
)
```

Understand which widget actually owns the required behavior.

Remove redundant wrappers.

---

# 40. Do not wrap everything in `Builder`

Use `Builder` when a new `BuildContext` scope is actually required.

Do not introduce it as generic structure.

---

# 41. Do not use `LayoutBuilder` unless layout constraints matter

Bad:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    return Text('Hello');
  },
)
```

If `constraints` are irrelevant, remove it.

---

# 42. Do not use `FutureBuilder` merely because a function is async

Ask whether the future should execute every rebuild.

Bad:

```dart
FutureBuilder(
  future: api.getUser(),
  builder: ...
)
```

inside a rebuilding widget without intentional request lifecycle.

Understand ownership of the future.

---

# 43. Avoid accidental repeated API calls

Watch for:

```dart
build()
→ repository.fetch()
```

or creating a new `Future` every rebuild.

Network requests should have deliberate lifecycle ownership.

---

# 44. Keep side effects out of `build`

Do not:

```dart
Widget build(BuildContext context) {
  analytics.trackScreen();
  api.fetchUser();
  controller.load();
  ...
}
```

`build` may run many times.

Rendering should remain side-effect free.

---

# 45. Do not fear rebuilds blindly

Do not add:

```text
RepaintBoundary
const gymnastics
Selector
Consumer splitting
memoization
cached widgets
GlobalKey
```

everywhere simply because Flutter rebuilds widgets.

Rebuilding lightweight widgets is a normal part of Flutter.

Optimize measured bottlenecks.

---

# 46. Use `const` naturally, not obsessively

Prefer `const` when valid:

```dart
const SizedBox(height: 16)
```

But do not distort architecture solely to maximize the number of `const` constructors.

`const` is an optimization and clarity tool, not a design objective.

---

# 47. Avoid premature performance optimization

Do not optimize based on intuition alone.

Before introducing complexity for performance, identify:

- excessive rebuilds
- expensive layout
- expensive painting
- large lists
- image memory pressure
- blocking synchronous work
- repeated serialization
- unnecessary network calls

Use profiling when performance matters.

---

# 48. Use lazy list widgets for large collections

For substantial dynamic lists, prefer:

```dart
ListView.builder
GridView.builder
SliverList
```

over eagerly building hundreds of children.

This is a real Flutter performance concern.

---

# 49. Do not use ListView.builder for three static widgets

If the collection is tiny and static:

```dart
Column(
  children: const [
    ...
  ],
)
```

may be clearer.

Again, proportional complexity.

---

# 50. Avoid unnecessary `SingleChildScrollView`

Do not wrap screens reflexively in:

```dart
SingleChildScrollView
```

Understand the expected layout and scrolling behavior.

For large dynamic content, use lazy scrolling widgets.

---

# 51. Avoid nested scroll hacks

Be suspicious of:

```dart
ListView(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
)
```

inside another scroll view.

Sometimes it is valid.

Often it indicates that the scroll architecture should be reconsidered.

Use slivers or a single scroll owner where appropriate.

---

# 52. Do not overuse `shrinkWrap`

`shrinkWrap: true` has layout cost.

Use it because the layout requires it, not because it fixes a constraint error you did not investigate.

---

# 53. Understand constraints instead of patching overflow

Do not fix every layout exception using random combinations of:

```text
Expanded
Flexible
SizedBox
FittedBox
SingleChildScrollView
IntrinsicHeight
IntrinsicWidth
```

Understand Flutter's constraint flow:

```text
constraints go down
sizes go up
parents set positions
```

Fix the actual layout.

---

# 54. Avoid `IntrinsicHeight` / `IntrinsicWidth` casually

These can trigger additional layout work.

Use them only when intrinsic measurement is genuinely required.

Do not use them as generic alignment fixes.

---

# 55. Avoid fixed dimensions without reason

Be suspicious of:

```dart
width: 375
height: 812
```

copied from Figma.

Flutter screens vary.

Prefer constraints, available width, flex layout, and design-system sizing.

Fixed dimensions are appropriate for genuinely fixed components.

---

# 56. Do not create responsive abstraction machinery too early

Avoid immediately introducing:

```text
ResponsiveBuilder
DeviceType
BreakpointManager
ScreenUtils
DimensionScaler
ResponsiveValue<T>
```

for an application whose layout only needs:

```dart
MediaQuery.sizeOf(context).width
```

or a small `LayoutBuilder`.

Use a real breakpoint system when the product genuinely has multiple layouts.

---

# 57. Do not use `MediaQuery` everywhere

If one parent can determine the responsive layout, do that.

Do not repeatedly query screen dimensions deep throughout the widget tree for unrelated calculations.

---

# 58. Respect Flutter lifecycle

Understand:

```text
initState
didChangeDependencies
didUpdateWidget
dispose
build
```

before adding workarounds.

Many Flutter bugs come from putting initialization or updates in the wrong lifecycle method.

---

# 59. Always dispose owned disposable resources

If a State object owns:

```text
TextEditingController
AnimationController
ScrollController
FocusNode
StreamSubscription
Timer
```

dispose or cancel it appropriately.

This is real defensive programming.

Do not remove lifecycle cleanup in the name of simplicity.

---

# 60. Do not dispose resources you do not own

If a controller is injected from outside, determine ownership before disposing it.

Lifecycle cleanup must reflect ownership.

---

# 61. Avoid unnecessary controllers

Do not introduce `TextEditingController` if you only need the final value and a simpler form mechanism suffices.

But use controllers when programmatic access or mutation is actually required.

---

# 62. Keep `setState` synchronous

Do not write:

```dart
setState(() async {
  await save();
});
```

Perform asynchronous work outside:

```dart
final result = await save();

if (!mounted) return;

setState(() {
  data = result;
});
```

---

# 63. Handle `mounted` where asynchronous lifecycle uncertainty is real

After an `await`, a State object may have been disposed.

This is legitimate:

```dart
await save();

if (!mounted) return;

Navigator.of(context).pop();
```

Do not remove such checks simply because they look defensive.

---

# 64. Do not sprinkle `mounted` everywhere

If no asynchronous gap exists, this:

```dart
if (!mounted) return;
```

is usually unnecessary.

Use lifecycle checks where lifecycle uncertainty actually exists.

---

# 65. Respect `BuildContext` async gaps

Be careful with:

```dart
await operation();

Navigator.of(context).push(...);
```

when the originating widget could disappear.

Use the project's Flutter/Dart lint guidance and ownership semantics.

---

# 66. Do not create global `BuildContext` hacks

Avoid:

```dart
GlobalKey<NavigatorState> navigatorKey
```

as a universal substitute for proper navigation/context architecture.

A navigator key may be appropriate for certain cross-cutting concerns.

It should not become an escape hatch for every service.

---

# 67. Keep UI concerns out of repositories

Bad:

```dart
class UserRepository {
  Future<void> saveUser(BuildContext context) async {
    ...
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

Repositories should not normally know about Flutter UI context.

Return information or throw meaningful failures.

Let the presentation layer decide how to present them.

---

# 68. Do not pass `BuildContext` through business logic

Be suspicious of service signatures such as:

```dart
Future<void> login(
  BuildContext context,
  String email,
  String password,
)
```

unless the function is explicitly a UI function.

Business logic should not require UI context merely to navigate or show a snackbar.

---

# 69. Keep navigation centralized enough, not abstracted to death

Direct navigation is fine:

```dart
Navigator.of(context).push(...);
```

or the project's router API.

Do not build:

```text
NavigationService
NavigationRepository
NavigationManager
NavigationCoordinator
NavigationUseCase
```

around simple navigation.

Follow the router already used by the application.

---

# 70. Do not introduce a new routing package casually

If the app uses:

```text
Navigator
GoRouter
AutoRoute
Beamer
```

continue with the existing system unless there is a real architectural reason to change.

---

# 71. Avoid route string scattering when route contracts are known

If using named routes extensively, centralizing route names may be useful.

But do not construct a huge routing abstraction merely to avoid:

```dart
'/profile'
```

three times.

---

# 72. Handle errors at meaningful boundaries

Do not:

```dart
try {
  await repository.load();
} catch (_) {
  return null;
}
```

unless failure genuinely maps to an optional result.

Do not silently erase operational failures.

---

# 73. Avoid catch-and-rethrow

Bad:

```dart
try {
  return await repository.getUser();
} catch (e) {
  rethrow;
}
```

Remove the `try/catch`.

Catch when you are:

- translating an error
- recovering
- adding meaningful context
- cleaning up resources
- mapping infrastructure failure to a domain result

---

# 74. Avoid wrapping errors at every layer

Bad:

```text
Failed to load page
Failed to get user
Failed to call repository
Failed to call API
HTTP request failed
SocketException
```

Do not create an error onion.

Add context where it materially improves debugging or user-facing behavior.

---

# 75. Do not replace exceptions with arbitrary booleans

Bad:

```dart
Future<bool> login() async {
  try {
    await api.login();
    return true;
  } catch (_) {
    return false;
  }
}
```

when callers need to distinguish:

```text
invalid credentials
network failure
account disabled
server failure
```

Choose error semantics that match the product.

---

# 76. Do not create custom Result types automatically

Avoid introducing:

```dart
Result<T>
Either<L, R>
Failure<T>
ApiResult<T>
OperationResult<T>
```

for every operation unless the project already follows that pattern or explicit result modeling solves a real need.

Dart exceptions are not inherently bad architecture.

---

# 77. Preserve meaningful domain errors

A domain-specific failure can be useful:

```dart
throw InsufficientBalanceException();
```

when callers need that semantic distinction.

Do not collapse meaningful failures into:

```dart
Exception('Something went wrong');
```

---

# 78. Do not show raw exception text to users

Bad:

```dart
Text(error.toString())
```

for arbitrary backend or infrastructure errors.

Technical error detail and user-facing messaging are separate concerns.

---

# 79. Avoid generic API services

Be suspicious of giant classes like:

```text
ApiService
NetworkService
HttpService
BackendService
```

containing every endpoint in the application.

Prefer feature ownership when the service becomes difficult to navigate.

Do not split tiny projects prematurely.

---

# 80. Avoid one API class per endpoint

The opposite extreme is also bad:

```text
GetUserApi
UpdateUserApi
DeleteUserApi
GetTransactionsApi
```

with one method each.

Group endpoints according to meaningful feature/API boundaries.

---

# 81. Do not wrap Dio/http methods without semantic value

Bad:

```dart
Future<Response> get(
  String url,
) {
  return dio.get(url);
}
```

when the wrapper adds nothing.

A network client wrapper becomes useful when it consistently handles real concerns such as:

- authentication headers
- refresh tokens
- serialization
- base URL
- interceptors
- observability
- standardized transport configuration

---

# 82. Keep authentication handling at a sensible boundary

Token attachment and refresh behavior should generally not be duplicated in every repository.

Use the networking mechanism already present in the codebase.

Do not scatter:

```dart
headers: {
  'Authorization': 'Bearer $token',
}
```

across fifty API calls if the HTTP client can own it centrally.

---

# 83. Do not add interceptors for every concern

Interceptors are useful for cross-cutting network behavior.

Do not turn them into hidden business-logic pipelines.

Avoid:

```text
AuthInterceptor
UserInterceptor
LoadingInterceptor
DialogInterceptor
NavigationInterceptor
FeatureFlagInterceptor
ResponseMutationInterceptor
```

without real cross-cutting semantics.

---

# 84. Do not over-abstract local storage

If the project only needs:

```dart
prefs.setString('token', token);
```

a twelve-layer storage architecture may not be necessary.

But token/security requirements may justify secure storage and a focused abstraction.

Use the correct security primitive without architectural ceremony.

---

# 85. Never store sensitive data insecurely just for simplicity

Anti-slop does not override security.

Use appropriate storage for:

- authentication credentials
- sensitive tokens
- secrets
- regulated personal information

Do not simplify away required protections.

---

# 86. Avoid SharedPreferences as an application database

SharedPreferences is appropriate for small key-value preferences.

Do not force structured domain data into dozens of JSON strings merely to avoid a proper persistence layer.

---

# 87. Avoid premature caching

Do not add cache layers simply because network data exists.

Caching introduces:

- invalidation
- expiration
- synchronization
- stale state
- persistence decisions

Add caching when product or performance requirements justify it.

---

# 88. Do not write manual cache invalidation everywhere

If caching is required, define ownership and policy.

Avoid random:

```dart
cachedUser = null;
cachedProducts.clear();
reload = true;
```

across unrelated screens.

---

# 89. Keep async code direct

Bad:

```dart
Future<User> getUser() async {
  return await repository.getUser();
}
```

when no surrounding work requires `await`.

Prefer:

```dart
Future<User> getUser() {
  return repository.getUser();
}
```

---

# 90. Avoid unnecessary `Future.value`

Bad:

```dart
Future<User> getUser() async {
  return Future.value(user);
}
```

Prefer the correct synchronous or asynchronous contract.

---

# 91. Avoid unnecessary Completers

Be suspicious of:

```dart
final completer = Completer<User>();
```

when an existing Future can simply be returned.

Use `Completer` when bridging callback-style APIs or manually controlling completion is genuinely required.

---

# 92. Do not wrap existing Futures

Bad:

```dart
return Future(() async {
  return await api.getUser();
});
```

Prefer:

```dart
return api.getUser();
```

---

# 93. Use parallelism when operations are actually independent

Instead of:

```dart
final user = await getUser();
final settings = await getSettings();
```

if independent:

```dart
final results = await Future.wait([
  getUser(),
  getSettings(),
]);
```

But do not parallelize dependent operations.

---

# 94. Avoid isolates for ordinary async work

Network I/O does not require an isolate.

Use isolates for expensive CPU-bound work that would meaningfully block the UI thread.

Do not introduce `compute` because a function happens to be asynchronous.

---

# 95. Do not overuse Streams

A value that changes occasionally does not automatically need:

```dart
StreamController
StreamBuilder
BehaviorSubject
RxDart
```

Streams are appropriate for genuinely stream-like sequences.

Use simpler state primitives when sufficient.

---

# 96. Dispose StreamControllers you own

If you create:

```dart
StreamController
StreamSubscription
```

manage its lifecycle correctly.

Anti-slop removes fake safety, not resource safety.

---

# 97. Avoid Rx-style transformations for trivial state

Do not turn:

```dart
bool isVisible
```

into a large reactive pipeline without a product-level reason.

---

# 98. Avoid `notifyListeners()` explosion

With ChangeNotifier/Provider, if every method ends with several unrelated mutations and:

```dart
notifyListeners();
```

consider whether the state object owns too many concerns.

But do not split a notifier merely to achieve theoretical purity.

---

# 99. Avoid mega providers/controllers/blocs

Be suspicious of a single:

```text
AppProvider
AppController
MainBloc
GlobalStore
```

that manages:

```text
auth
profile
payments
theme
notifications
navigation
products
settings
```

Split by meaningful ownership when complexity demands it.

---

# 100. Avoid microscopic providers/controllers/blocs

The opposite problem is:

```text
PasswordVisibilityBloc
CheckboxBloc
TabIndexBloc
ButtonLoadingBloc
```

Do not make every mutable value its own architecture unit.

---

# 101. Keep forms straightforward

Use Flutter's form primitives where suitable:

```text
Form
GlobalKey<FormState>
TextFormField
validator
```

Do not build custom form engines unless the application genuinely requires complex dynamic forms.

---

# 102. Do not duplicate validation across layers unnecessarily

User-input constraints may exist in:

- UI for immediate feedback
- server for authoritative validation

That is legitimate.

But do not create five identical Dart validators across widgets, controllers, services, repositories, and models.

Own validation intentionally.

---

# 103. Client validation is not security

Backend validation remains authoritative.

Do not remove server-facing error handling because the Flutter form already validates input.

---

# 104. Keep validation domain-specific

Bad:

```dart
bool validateString(String? value)
```

Prefer:

```dart
String? validateEmail(String? value)
```

when email semantics actually matter.

But do not create a validation utility class containing one-line wrappers around obvious checks.

---

# 105. Avoid Regex obsession

For normal product requirements, implement the validation actually required by the product.

Do not write enormous regex expressions to prove an email address is theoretically RFC-perfect unless required.

---

# 106. Keep theme values in the theme/design system

Avoid random repeated UI values:

```dart
Color(0xFF...)
TextStyle(...)
BorderRadius.circular(...)
```

throughout a mature app with an established design system.

Reuse real design tokens.

---

# 107. Do not create design tokens for every number

Bad:

```text
spacing1
spacing2
spacing3
spacing4
spacing5
radius1
radius2
```

without a coherent system.

A design system should represent actual reusable visual decisions, not rename literals arbitrarily.

---

# 108. Avoid giant `AppConstants`

Be suspicious of:

```dart
class AppConstants {
  static const ...
}
```

containing:

```text
API URLs
colors
padding
route names
storage keys
error messages
regex
animation durations
business limits
```

Organize constants by ownership.

Do not create a universal dumping ground.

---

# 109. Avoid giant `utils` folders

Audit:

```text
utils/
helpers/
common/
shared/
core/
misc/
```

Do not let them become a graveyard of unrelated one-use functions.

Put domain behavior near the domain that owns it.

---

# 110. Do not create utility classes for stateless functions

Bad:

```dart
class StringUtils {
  static String capitalize(String value) {
    ...
  }
}
```

Prefer a top-level function or an appropriate extension when the abstraction genuinely improves readability.

---

# 111. Avoid extension-method abuse

Do not create:

```dart
context.showSnackbar()
context.pushPage()
context.theme
context.width
context.height
context.isMobile
context.textTheme
```

for every framework call.

Extensions are useful when they establish a coherent project vocabulary.

They are not automatically cleaner than direct Flutter APIs.

---

# 112. Do not hide important behavior behind extensions

This:

```dart
context.doEverything();
```

is worse than explicit behavior.

Call-site brevity is not the same as clarity.

---

# 113. Avoid excessive generic widgets

Be suspicious of:

```dart
AppCard<T>
GenericList<T>
BaseScreen<T>
CommonPage<T>
ReusableWidget<T>
DynamicForm<T>
```

when concrete components would be clearer.

Generics should solve actual reusable type relationships.

---

# 114. Do not make every screen inherit a base screen

Bad:

```text
BaseScreen
AuthenticatedScreen
ScrollableScreen
LoadingScreen
ResponsiveScreen
```

followed by complicated inheritance.

Flutter composition is generally preferable.

Use inheritance when a true subtype relationship exists.

---

# 115. Prefer composition over inheritance

Flutter's widget model is built around composition.

Do not reproduce Android/Java inheritance-heavy architecture inside Flutter.

---

# 116. Avoid mixins without shared behavioral semantics

Do not create mixins merely to move methods out of a file.

A mixin should represent behavior that genuinely belongs to multiple types.

---

# 117. Do not split files purely by line count

A 250-line coherent widget can be easier to understand than eight tiny files requiring constant navigation.

Split based on meaningful component or responsibility boundaries.

---

# 118. Do not keep giant unrelated files either

If a file contains multiple independent screens, models, services, and unrelated widgets, split it.

Cohesion matters more than arbitrary file-size rules.

---

# 119. Prefer feature-oriented organization when it helps navigation

For larger apps, structures such as:

```text
features/
  auth/
  payments/
  profile/
```

can keep ownership clear.

But do not reorganize an existing codebase solely to impose a fashionable folder layout.

---

# 120. Follow existing project conventions unless they are actively harmful

Consistency has value.

Do not introduce a different architecture, naming convention, router, serializer, state library, or networking package during an unrelated change.

---

# 121. Avoid package addiction

Before adding a dependency, ask:

1. Is this difficult to implement correctly ourselves?
2. Is the package maintained?
3. Does the app already have a package solving this?
4. Is the feature substantial enough to justify dependency cost?
5. Is the package replacing three lines of standard Dart?

Do not add packages reflexively.

---

# 122. Do not reimplement mature platform functionality carelessly

The inverse also matters.

For:

- cryptography
- secure storage
- complex image handling
- database engines
- authentication protocols
- native platform integrations

use established solutions where appropriate.

Anti-dependency purity is also slop.

---

# 123. Do not add packages just for tiny helpers

Avoid dependencies whose only purpose is effectively:

```dart
list.firstOrNull
```

or:

```dart
capitalize(value)
```

unless already transitively/strategically justified.

---

# 124. Respect platform differences where they are real

Flutter is cross-platform, not platform-identical.

Preserve legitimate handling for:

```text
Android permissions
iOS permissions
web APIs
filesystem differences
notification behavior
background execution
platform-specific UI behavior
```

Do not delete platform checks merely because they look repetitive.

---

# 125. Do not scatter `Platform.isAndroid` everywhere

If substantial platform behavior differs, centralize that real distinction at an appropriate boundary.

Do not duplicate platform branching across dozens of widgets.

---

# 126. Handle permissions at actual feature boundaries

Permissions are real runtime uncertainty.

Do not assume permissions because Dart types compile.

Handle:

```text
denied
permanently denied
restricted
granted
limited
```

according to the plugin/platform's actual semantics.

---

# 127. Preserve security checks

Never simplify away:

- authentication
- authorization
- certificate/security requirements
- secure token handling
- sensitive data controls
- permission checks
- input validation at external boundaries

Complexity reduction must preserve security.

---

# 128. Avoid fake abstraction around plugins

Bad:

```text
LocationPluginWrapper
LocationPluginService
LocationRepository
LocationManager
LocationUseCase
```

when every layer forwards to:

```dart
Geolocator.getCurrentPosition();
```

Add abstraction when it helps testing, platform switching, policy, caching, or domain semantics.

---

# 129. Do not leak plugin-specific types unnecessarily

At the same time, if your entire domain begins passing around plugin-specific objects such as:

```dart
Position
XFile
Placemark
RemoteMessage
```

ask whether your application needs a domain representation.

Introduce one when separation has actual value.

---

# 130. Do not create domain models merely to avoid plugin types

If a plugin type already exactly represents what the application needs and coupling is acceptable, another identical wrapper may provide no benefit.

Use judgment.

---

# 131. Keep Firebase logic at sensible boundaries

Do not scatter:

```text
FirebaseAuth.instance
FirebaseFirestore.instance
FirebaseMessaging.instance
```

through every widget.

Own integration logic coherently.

But do not construct twelve abstraction layers around Firebase merely because it is external infrastructure.

---

# 132. Do not trust Firebase/backend input merely because it is your backend

Remote data is still boundary data.

Parse expected shapes and preserve legitimate null/error handling.

---

# 133. Keep notification handling explicit

Push notifications involve genuine external uncertainty.

Handle:

- app foreground/background/terminated state
- missing payload fields where contract permits
- navigation availability
- permission state
- token refresh
- platform differences

Do not simplify these away as "defensive code."

---

# 134. Do not convert malformed notification payloads into empty strings

Bad:

```dart
final route = message.data['route'] ?? '';
```

followed by attempting navigation.

If `route` is required, reject or ignore malformed payloads intentionally.

---

# 135. Avoid magic navigation from arbitrary notification maps

Parse notification payloads into a known structure before executing application behavior.

---

# 136. Keep geolocation logic domain-aware

Do not hide meaningful concepts behind generic helpers.

For example:

```dart
isWithinAttendanceRadius(
  currentPosition,
  sessionLocation,
  allowedRadius,
)
```

represents a real business concept.

This is better than:

```dart
calculateStuff(...)
```

Meaningful domain helpers are not slop.

---

# 137. Do not duplicate coordinates in arbitrary structures

Prefer:

```dart
Location(
  latitude: ...,
  longitude: ...,
)
```

when location is an actual domain concept.

Avoid passing:

```text
lat1
lng1
lat2
lng2
```

through numerous layers when a domain object improves clarity.

---

# 138. Avoid unnecessary wrapper models around simple parameter groups

Do not create a new class merely because a method has two obvious arguments.

Use a model when the values form a meaningful concept or travel together widely.

---

# 139. Keep method signatures narrow

Bad:

```dart
Future<void> markAttendance(
  AttendanceSession session,
  User user,
  Organization organization,
)
```

when only:

```text
sessionId
latitude
longitude
```

are needed.

Pass the data the function actually uses.

---

# 140. Do not pass entire models through every layer for convenience

Narrow contracts clarify dependencies.

A function updating a user avatar may need:

```dart
userId
file
```

not the full:

```dart
User
AppState
ProfileState
```

---

# 141. Avoid Boolean parameter soup

Bad:

```dart
buildButton(
  true,
  false,
  true,
  false,
)
```

Prefer named parameters:

```dart
buildButton(
  enabled: true,
  loading: false,
)
```

When behavior has mutually exclusive modes, consider a proper enum or type.

---

# 142. Avoid unnecessary enums

Do not convert every string into an enum.

Use enums or sealed/literal-like domain types when there is a meaningful closed set.

---

# 143. Prefer exhaustive state representations for genuine closed sets

For:

```text
pending
approved
rejected
```

an enum may improve correctness.

Do not leave meaningful closed state as arbitrary strings if invalid values would create bugs.

---

# 144. Do not create enum wrapper extensions unless useful

Bad:

```dart
extension StatusX on Status {
  bool get isPending => this == Status.pending;
  bool get isApproved => this == Status.approved;
}
```

if every property is used once.

Direct comparison may be clearer.

---

# 145. Avoid unnecessary typedefs

Question:

```dart
typedef UserId = String;
typedef Email = String;
typedef Json = Map<String, dynamic>;
```

when the alias adds no semantic or type-safety value.

Keep aliases when they materially improve an API or callback signature.

---

# 146. Do not overuse records just because Dart supports them

Records are useful for lightweight grouped values.

Do not replace meaningful domain models with cryptic:

```dart
(String, int, bool)
```

when field semantics matter throughout the application.

Named records can be appropriate for local return values.

---

# 147. Use sealed classes when they solve state modeling

Sealed classes are excellent for real finite states.

They are not mandatory for every repository response.

---

# 148. Use pattern matching where it improves clarity

Prefer clear exhaustive handling where applicable.

Do not introduce clever nested pattern expressions that make simple business logic harder to read.

---

# 149. Avoid clever Dart

Readable:

```dart
if (user.isAdmin) {
  return const AdminPage();
}

return const HomePage();
```

may be preferable to an overly clever expression.

Code is read more often than written.

---

# 150. Avoid nested ternaries

Bad:

```dart
final text = loading
    ? 'Loading'
    : error != null
        ? 'Failed'
        : data != null
            ? 'Loaded'
            : 'Empty';
```

Prefer `if`, `switch`, or a clearly modeled state.

---

# 151. Prefer early returns

Bad:

```dart
if (user != null) {
  if (user.isActive) {
    if (user.canTransfer) {
      // main logic
    }
  }
}
```

Prefer:

```dart
if (user == null) return;
if (!user.isActive) return;
if (!user.canTransfer) return;

// main logic
```

Keep the happy path obvious.

---

# 152. Remove useless intermediate variables

Bad:

```dart
final rawName = user.name;
final trimmedName = rawName.trim();
final name = trimmedName;
```

Prefer:

```dart
final name = user.name.trim();
```

Keep variables that communicate meaningful concepts.

---

# 153. Remove obvious comments

Bad:

```dart
// Navigate to home
Navigator.of(context).push(...);
```

Bad:

```dart
// Set loading to true
isLoading = true;
```

Keep comments for:

- business rules
- lifecycle quirks
- platform quirks
- workarounds
- external constraints
- counterintuitive behavior

Explain why.

---

# 154. Avoid comment-generated section noise

Be suspicious of:

```dart
// ====================
// USER METHODS
// ====================
```

throughout small classes.

File structure and naming should usually communicate organization.

---

# 155. Avoid meaningless method names

Names like:

```text
handleData
processData
manageState
doAction
performOperation
executeTask
```

often hide unclear responsibilities.

Use domain-specific verbs.

---

# 156. Avoid unnecessary private-method explosion

Be suspicious of:

```text
_buildHeader
_buildBody
_buildFooter
_buildButton
_buildSpacer
_getUser
_parseUser
_processUser
_handleUser
```

inside one class when each contains two trivial lines.

Extract meaningful behavior, not every statement.

---

# 157. Do not inline everything either

A 1,000-line `build` method is not simplicity.

Keep extraction proportional to conceptual boundaries.

---

# 158. Avoid enormous constructors

If a widget takes:

```text
18 booleans
12 callbacks
20 styling parameters
```

ask whether it has too many responsibilities.

But do not immediately solve it with generic configuration-object abstractions.

First inspect the component boundary.

---

# 159. Avoid widget configuration objects without need

Bad:

```dart
ButtonConfig(
  text: ...,
  color: ...,
  onPressed: ...,
  radius: ...,
)
```

passed into:

```dart
AppButton(config: config)
```

when named widget constructor parameters are clearer.

---

# 160. Do not build a custom design framework inside Flutter

Be wary of recreating:

```text
CSS
DOM
flexbox wrappers
HTML-like components
custom layout DSL
custom styling engine
```

over Flutter's widget system without a compelling product requirement.

Use Flutter.

---

# 161. Avoid pointless custom wrappers around Material widgets

Bad:

```text
AppScaffold
AppSafeArea
AppPadding
AppCenter
AppSizedBox
AppText
AppIcon
```

if they merely forward every parameter.

Wrapper widgets should encode real product conventions.

---

# 162. Keep meaningful design-system components

This can be valuable:

```text
PrimaryButton
AccountCard
TransactionTile
AppTextField
BottomSheetShell
```

when they enforce consistent product behavior and visual rules.

The issue is not reuse.

The issue is abstraction without semantics.

---

# 163. Do not make reusable components impossibly generic

If `AppButton` has 45 parameters to support every conceivable button, the abstraction may be worse than several focused components.

Prefer coherent variants.

---

# 164. Avoid styling arguments that violate the design system

If a component represents a fixed design primitive, do not expose every underlying Flutter styling option merely for flexibility.

An abstraction should constrain where constraint has value.

---

# 165. Avoid unnecessary Keys

Do not add:

```dart
ValueKey(...)
UniqueKey()
GlobalKey(...)
```

everywhere.

Keys solve widget identity problems.

Use them when identity actually matters.

---

# 166. Be especially careful with GlobalKey

GlobalKey has legitimate uses, such as:

```text
FormState
NavigatorState
cross-subtree state access in rare cases
```

Do not use it as routine state management.

---

# 167. Do not use `UniqueKey()` to force rebuilds casually

If you need:

```dart
UniqueKey()
```

to make a widget behave correctly, investigate state ownership and identity first.

---

# 168. Avoid `Future.delayed` UI hacks

Be suspicious of:

```dart
Future.delayed(
  const Duration(milliseconds: 100),
  () {
    ...
  },
);
```

used to "wait for the UI."

Understand whether the actual requirement is:

```text
post-frame callback
animation completion
navigation completion
state update
async operation
```

Use the correct lifecycle mechanism.

---

# 169. Avoid post-frame callbacks as universal fixes

This:

```dart
WidgetsBinding.instance.addPostFrameCallback(...)
```

is appropriate for certain operations requiring completed layout/rendering.

It should not become a workaround for poor state flow.

---

# 170. Do not blindly use `mounted` + post frame + delay combinations

Code like:

```dart
Future.delayed(..., () {
  if (mounted) {
    WidgetsBinding.instance.addPostFrameCallback(...);
  }
});
```

deserves investigation.

Understand the lifecycle problem instead of stacking timing workarounds.

---

# 171. Avoid polling when reactive events exist

If an SDK exposes a stream/callback for state changes, do not repeatedly run timers just to rediscover state.

Use the event mechanism.

But do not replace simple occasional refresh behavior with a complex reactive architecture without need.

---

# 172. Dispose Timers

Any repeating Timer owned by a widget/service must have a clear lifecycle.

This is real resource management.

---

# 173. Keep animations proportional

Do not add:

```text
AnimationController
TweenSequence
CurvedAnimation
AnimatedBuilder
multiple controllers
```

for a simple appearance transition that:

```dart
AnimatedOpacity
AnimatedContainer
AnimatedSwitcher
```

can handle clearly.

Use explicit controllers for actual animation choreography.

---

# 174. Avoid animation for animation's sake

Product polish matters.

But excessive motion increases UI complexity and can hurt usability.

Implement the design requirement, not a demo reel.

---

# 175. Respect accessibility

Do not simplify away:

- semantics
- accessible labels
- contrast requirements
- touch target sizing
- text scaling
- keyboard navigation where applicable
- reduced-motion considerations where relevant

These are product requirements, not defensive clutter.

---

# 176. Do not disable text scaling globally because layouts break

Fix layouts.

Accessibility settings are legitimate runtime conditions.

---

# 177. Avoid hard-coded user-facing strings when localization exists

If the application uses localization, follow it.

Do not bypass it to save a few lines.

Conversely, do not install localization infrastructure for an app that explicitly has no localization requirement merely because it is "best practice."

---

# 178. Keep logging meaningful

Bad:

```dart
debugPrint('entered login');
debugPrint('calling api');
debugPrint('api returned');
debugPrint('setting loading false');
```

Log useful operational information.

Do not narrate every function.

---

# 179. Do not print sensitive values

Never log:

```text
passwords
access tokens
refresh tokens
PINs
full financial credentials
sensitive personal information
```

Simplicity does not override data protection.

---

# 180. Avoid logging and rethrowing at every layer

Bad:

```dart
catch (error) {
  logger.error(error);
  rethrow;
}
```

when the next layer logs the same error.

Choose responsible logging boundaries.

---

# 181. Remove debugging code after the issue is resolved

Audit:

```dart
print(...)
debugPrint(...)
TODO temporary
Future.delayed(...)
hardcoded IDs
mock booleans
```

before completing production work.

---

# 182. Avoid giant try/catch blocks

Do not wrap an entire screen's workflow in one catch merely because several operations can fail.

Handle failures at the level where recovery or translation is meaningful.

---

# 183. Preserve cancellation and lifecycle behavior

For long-running requests, subscriptions, uploads, location monitoring, or streams, preserve legitimate cancellation behavior.

Do not simplify away lifecycle correctness.

---

# 184. Do not use flags to patch race conditions blindly

Be suspicious of:

```dart
bool isProcessing = false;
bool requestStarted = false;
bool alreadyHandled = false;
```

added one after another.

Sometimes these flags represent legitimate state.

Sometimes they are symptoms of unclear ownership or concurrency.

Investigate before adding another flag.

---

# 185. Prevent duplicate actions where they matter

For payment, submission, check-in, order creation, etc., preventing duplicate user actions is legitimate.

Examples:

```text
disable submit while request is in flight
idempotency at the backend
operation state
```

Do not remove these protections as redundant UI state.

---

# 186. UI duplicate prevention is not backend idempotency

A disabled button alone does not guarantee a financial or transactional operation occurs once.

Preserve server-side protection where required.

---

# 187. Avoid Boolean loading flags shared across unrelated operations

Bad:

```dart
bool isLoading;
```

for:

```text
fetch profile
upload avatar
save profile
delete account
```

One operation can incorrectly block another.

Model independent operation state where necessary.

---

# 188. Do not create a state class for every operation by default

Again, proportion matters.

A screen with one request can remain simple.

A complex screen with several concurrent operations may deserve structured state.

---

# 189. Avoid massive `copyWith` calls for tiny updates

If state models become:

```dart
state = state.copyWith(
  a: state.a,
  b: state.b,
  c: state.c,
  d: value,
  ...
);
```

inspect whether state ownership is too broad.

Modern generated immutable models may reduce syntax, but they do not fix bad state boundaries.

---

# 190. Do not adopt Freezed merely to avoid writing constructors

Freezed can provide substantial value for:

- immutable models
- unions/sealed state
- equality
- serialization integration

Do not introduce it solely because manually writing a five-field data class feels tedious.

---

# 191. Avoid unnecessary `Equatable`-style machinery when Dart/project conventions already solve equality

Use the approach already established.

Do not stack multiple equality/code-generation solutions.

---

# 192. Do not generate code that nobody needs

Code generation has maintenance cost.

Use it when it removes meaningful repetitive work or enables useful semantics.

Do not create builders, generators, schemas, and generated layers for trivial applications.

---

# 193. Keep tests focused on behavior

Do not test framework implementation details.

Prefer testing:

```text
given state/input
→ expected behavior/output/UI
```

over tests tightly coupled to private implementation.

---

# 194. Do not mock everything

A unit test with fifteen mocks can indicate that the subject has too many dependencies or the test boundary is wrong.

Mock real boundaries where useful.

Do not mock plain value objects or trivial pure functions unnecessarily.

---

# 195. Do not introduce interfaces solely for mocking

Bad:

```dart
abstract class IUserService {}

class UserService implements IUserService {}
```

with exactly one implementation and no architectural reason other than "tests need mocks."

Dart testing approaches can often work without interface-for-every-class architecture.

Use abstractions when they represent real substitution boundaries.

---

# 196. Preserve testability without architecture theater

Code should be testable.

That does not mean every function must travel through:

```text
interface
repository
use case
controller
adapter
factory
```

Dependency boundaries should correspond to real external effects or meaningful domain separation.

---

# 197. Avoid golden tests for every tiny component

Golden tests are useful for important visual regression surfaces.

Do not create huge maintenance burden for trivial text/spacing components without reason.

---

# 198. Do not chase 100% coverage blindly

Coverage is an indicator, not the objective.

Prioritize:

- business rules
- state transitions
- parsing
- error handling
- payment/transaction logic
- critical user flows
- regressions

---

# 199. Keep platform channels behind meaningful boundaries

Native Android/iOS integration is a real external boundary.

Handle errors and contract mismatches there.

Do not let raw method-channel data flow through the application as arbitrary maps.

---

# 200. Type method-channel contracts where practical

Desired:

```text
native result
→ boundary parsing
→ Dart type
→ application
```

Not:

```text
dynamic
→ dynamic
→ Map
→ widget
```

---

# 201. Avoid defensive conversions

Search for:

```dart
value.toString()
int.tryParse(value.toString())
bool.parse(value.toString())
'$value'
```

when the type is already known.

Bad:

```dart
final id = user.id.toString();
```

when `id` is already `String`.

Trust the type.

---

# 202. Do not convert arbitrary values to make them fit

Bad:

```dart
final email = value.toString();
```

if `value` should already be a valid email string.

Reject malformed boundary data rather than converting nonsense into apparently valid application values.

---

# 203. Keep meaningful normalization

This is fine:

```dart
final email =
    input.trim().toLowerCase();
```

when the domain requires it.

The problem is not normalization.

The problem is accepting arbitrary values and silently coercing them.

---

# 204. Avoid generic conversion utilities

Be suspicious of:

```text
toStringSafe
toIntSafe
toDoubleSafe
parseBool
dynamicToString
convertValue
normalizeValue
```

Ask what type the value should actually be.

---

# 205. Fix types at the earliest sensible point

Whenever you see:

```text
dynamic
Map<String, dynamic>
safeX
parseX
convertX
normalizeX
extractX
```

trace the value upstream.

Ask:

1. Where did this value enter the application?
2. Is that an external boundary?
3. Can it be parsed there?
4. Can downstream code receive a precise type?
5. Can the helper disappear afterward?

---

# 206. Preserve genuine runtime checks

Do not remove checks protecting against:

- malformed API data
- connectivity failures
- user input
- nullable backend fields
- missing database records
- authentication expiry
- permission state
- filesystem failures
- plugin/platform failures
- notification payloads
- lifecycle disposal
- JSON decode failures
- security requirements
- external SDK behavior
- web/native differences

The distinction is:

> Defend against external and lifecycle uncertainty, not against your own correctly typed Dart code.

---

# 207. Do not make cleanup increase complexity

A refactor is suspicious if it transforms:

```dart
final user = response.data as User;
```

at a trusted integration point into:

```dart
final raw = response.data;

if (raw == null) {
  return null;
}

if (raw is! Object) {
  return null;
}

if (raw is User) {
  return raw;
}

return null;
```

without providing meaningful correctness.

Likewise, replacing:

```dart
Text(user.name)
```

with:

```dart
Text(
  SafeValueParser.stringFrom(
    UserFieldExtractor.extract(
      user,
      'name',
    ),
  ),
)
```

is not an improvement.

---

# 208. Avoid AI-style helper proliferation

Treat patterns like these with suspicion:

```dart
String _getSafeString(dynamic value)
```

```dart
bool _isValidResponse(dynamic response)
```

```dart
Map<String, dynamic> _ensureMap(dynamic data)
```

```dart
T? _safeCast<T>(dynamic value)
```

```dart
String _extractName(User user)
```

```dart
Widget _buildSizedBox()
```

They are not automatically wrong.

But AI agents frequently introduce them to avoid understanding the actual type or domain.

---

# 209. Avoid architecture added during bug fixes

If the task is:

> Fix duplicate form submission

do not automatically introduce:

```text
new state-management package
repository layer
use-case layer
new model hierarchy
new router
dependency injection
```

Fix the bug at the appropriate level.

Keep change scope disciplined.

---

# 210. Do not refactor unrelated code opportunistically

During a focused task, avoid rewriting adjacent working code merely because you prefer a different style.

Large unrelated diffs:

- increase regression risk
- make review harder
- hide the actual fix

Refactor when it materially supports the task or is explicitly requested.

---

# 211. Preserve existing behavior

Do not accidentally change:

- navigation behavior
- API contracts
- JSON formats
- local persistence format
- route names
- authentication logic
- notification payloads
- analytics events
- platform-specific behavior
- form validation rules
- business calculations
- permission flows

This is complexity reduction, not silent product redesign.

---

# 212. Preserve legitimate nullability

Backend values can genuinely be nullable.

Do not make fields non-null merely because anti-slop favors precise types.

The model should reflect the actual contract.

If `middleName` can be null:

```dart
final String? middleName;
```

is correct.

---

# 213. Preserve legitimate abstraction

Do not remove abstraction that provides:

- test substitution
- multiple implementations
- caching policy
- offline/online switching
- cross-platform implementation
- domain isolation
- authorization policy
- complex orchestration
- reusable design-system semantics

The goal is not fewer files at all costs.

The goal is fewer meaningless concepts.

---

# 214. Preserve legitimate repositories

A repository with real responsibility can remain.

Example:

```text
TransactionRepository
→ remote banking API
→ encrypted local cache
→ pagination
→ synchronization
→ domain mapping
```

That is meaningfully different from a pass-through wrapper.

---

# 215. Preserve legitimate controllers/state managers

If a feature has:

```text
multiple asynchronous operations
cross-screen state
complex transitions
retries
pagination
real-time updates
offline behavior
```

dedicated state management can substantially improve correctness.

Do not simplify complex state into a pile of `setState` booleans.

---

# 216. Avoid dogmatic simplicity

"Simpler" does not mean:

- put everything in one widget
- remove all models
- remove all state management
- remove all repositories
- remove validation
- remove tests
- remove error handling
- ignore architecture
- avoid packages
- avoid abstractions entirely

It means:

> Use complexity only where the problem earns it.

---

# 217. Flutter architecture should be explainable

For every layer, you should be able to answer:

> What responsibility exists here that would be worse if this layer disappeared?

If the answer is:

> That's how Clean Architecture is structured.

that is not enough.

---

# 218. Every abstraction pays rent

An abstraction should provide at least one meaningful benefit:

- domain semantics
- reuse
- substitution
- policy
- isolation
- lifecycle ownership
- readability
- testability
- framework boundary
- external integration boundary

Otherwise, consider deleting it.

---

# 219. Prefer boring Flutter

Good Flutter code is often boring:

```dart
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.user,
    super.key,
  });

  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(user.name),
            Text(user.email),
          ],
        ),
      ),
    );
  }
}
```

It does not need:

```text
ProfilePageController
ProfilePageState
ProfileViewModel
ProfilePresenter
ProfileCoordinator
ProfilePageFactory
ProfilePageConfig
ProfilePageMapper
```

unless those concepts solve actual problems.

---

# 220. Prefer boring Dart

Good:

```dart
Future<User> loadUser(String id) {
  return userRepository.getUser(id);
}
```

Good:

```dart
final activeUsers =
    users.where((user) => user.isActive).toList();
```

Do not transform straightforward Dart into custom mini-frameworks.

---

# 221. Do not abstract standard Dart APIs

Avoid unnecessary wrappers around:

```text
List.where
List.map
List.firstWhere
Future.wait
jsonDecode
jsonEncode
DateTime
Duration
Uri
RegExp
Stream
Map
Set
```

unless the wrapper adds meaningful domain behavior.

---

# 222. Do not abstract Flutter APIs merely to make them shorter

Direct:

```dart
Theme.of(context)
Navigator.of(context)
MediaQuery.sizeOf(context)
ScaffoldMessenger.of(context)
```

is understandable Flutter.

A wrapper is not automatically better.

---

# 223. Use domain helpers when they communicate business meaning

Good:

```dart
bool canUpgradeAccount(
  Account account,
) {
  return account.kycCompleted &&
      account.currentTier < AccountTier.three;
}
```

A meaningful business rule deserves a name.

Anti-slop should not inline domain concepts into unreadable boolean expressions.

---

# 224. Separate UI logic from business rules where meaningful

This:

```dart
final canTransfer =
    account.balance >= amount &&
    account.status == AccountStatus.active &&
    !account.isFrozen;
```

may belong in domain/application logic if used broadly or representing an important invariant.

Do not bury significant product rules deep inside widgets.

---

# 225. Do not create a domain layer for trivial formatting

This:

```dart
Text(
  DateFormat.yMMMd().format(transaction.date),
)
```

does not necessarily need a `TransactionDateFormattingUseCase`.

Use judgment.

---

# 226. Keep formatting close to presentation unless it is domain behavior

Currency/date/display formatting is often presentation logic.

Financial calculations and business rules are not merely display formatting.

Distinguish them.

---

# 227. Be careful with money

Do not introduce floating-point errors into financial logic.

Do not simplify financial representations without understanding the backend/API contract.

Money is an example where domain correctness outweighs superficial simplicity.

---

# 228. Keep IDs precise

If IDs are strings, type them as strings.

Do not repeatedly:

```dart
id.toString()
```

Do not parse UUIDs as integers.

Do not normalize identifiers unless the contract requires it.

---

# 229. Avoid copying backend architecture into Flutter

A Flutter application does not necessarily need the same:

```text
Controller
Service
Repository
Entity
DTO
Mapper
```

structure as a backend.

Frontend architecture solves different lifecycle, rendering, interaction, and state problems.

---

# 230. Avoid web-development habits that fight Flutter

Do not simulate:

```text
DOM selectors
CSS utility APIs
global event buses
manual element lifecycle
HTML-style wrappers
```

where Flutter already provides better primitives.

Write Flutter as Flutter.

---

# 231. Avoid Android-view habits that fight Flutter

Do not create deep inheritance hierarchies or treat widgets as mutable views.

Understand Flutter's declarative model.

---

# 232. Widgets describe UI; they are not the UI instance

Do not fear widget object recreation.

Do not cache ordinary widgets in fields merely because they are constructed repeatedly.

State and render objects have different lifecycle semantics.

---

# 233. Do not store widgets in state unnecessarily

Bad:

```dart
Widget currentPage =
    const HomePage();
```

when an index or route/state representation would be clearer.

Store application state.

Derive UI from it.

---

# 234. Avoid storing derived UI state

Bad:

```dart
bool showEmptyState;
bool showLoadingState;
bool showContent;
```

when these derive naturally from one underlying status.

Make invalid UI combinations impossible where complexity justifies it.

---

# 235. Do not manipulate UI imperatively unless required

Prefer:

```text
state changes
→ build describes new UI
```

over trying to manually update individual UI pieces.

That is Flutter's model.

---

# 236. Avoid unnecessary callback forwarding

Bad:

```text
Page
→ WidgetA
→ WidgetB
→ WidgetC
→ Button
```

passing ten callbacks unchanged.

If callback drilling becomes substantial, reconsider ownership.

But do not add global state to avoid passing one callback through two widgets.

---

# 237. Callback drilling is not automatically bad

Passing:

```dart
VoidCallback onPressed
```

through a couple of components is often simpler than adding shared state infrastructure.

---

# 238. Keep callback signatures narrow

Bad:

```dart
void Function(
  User,
  BuildContext,
  bool,
  int,
  String?,
)
```

Consider whether the child actually needs that much context.

---

# 239. Avoid closures that merely forward arguments

Bad:

```dart
onPressed: () {
  handlePressed();
},
```

Prefer:

```dart
onPressed: handlePressed,
```

where semantics remain identical.

---

# 240. Do not optimize every closure away

Inline closures are normal Flutter.

Do not create named functions merely because closures allocate objects.

Optimize measured issues.

---

# 241. Avoid unnecessary async callbacks

Bad:

```dart
onPressed: () async {
  save();
},
```

when nothing is awaited.

Use:

```dart
onPressed: save,
```

if signatures permit.

---

# 242. Do not ignore returned Futures unintentionally

When an asynchronous operation must be awaited for sequencing or error handling, await it.

When deliberately fire-and-forget, make that intent explicit according to project conventions.

---

# 243. Avoid silent fire-and-forget for critical operations

Payments, saves, uploads, authentication, and destructive actions usually need explicit completion/error handling.

---

# 244. Keep pagination state coherent

Real pagination often requires:

```text
items
next cursor/page
loading-more state
has-more state
error state
```

Do not oversimplify it into one `isLoading`.

But do not build a generic pagination framework if one feature has twenty records.

---

# 245. Keep search/debounce logic meaningful

Debouncing user search input is legitimate.

Do not implement:

```text
Timer
StreamController
Rx debounce
custom scheduler
```

all at once.

Pick one appropriate mechanism.

---

# 246. Cancel stale searches where necessary

For network-backed search, responses may return out of order.

This is genuine asynchronous uncertainty.

Handle it if it can affect correctness.

Do not ignore race conditions in the name of simplicity.

---

# 247. Do not add race-condition infrastructure where no race exists

A synchronous local list filter does not need request tokens, cancellation objects, or mutexes.

Again: complexity should follow the actual problem.

---

# 248. Avoid unnecessary mutexes/locks in normal Flutter state

Dart's event loop already defines execution semantics.

Introduce synchronization primitives only when genuine concurrency/resource coordination requires them.

---

# 249. Keep background work explicit

Background services, isolates, scheduled work, and push handlers have platform lifecycle constraints.

Do not treat them like ordinary foreground Dart functions.

Preserve required entry points and initialization.

---

# 250. Avoid hidden singleton state

Global mutable singletons make state ownership hard to understand.

Use them deliberately for truly application-global infrastructure where lifecycle is clear.

Do not make every service a singleton by default.

---

# 251. Avoid static mutable state

Be suspicious of:

```dart
static User? currentUser;
static bool isLoggedIn;
static List<Item> cache = [];
```

unless global process-wide ownership is genuinely intended.

Prefer explicit state ownership.

---

# 252. Constants are different from mutable globals

This is fine:

```dart
static const maxUploadSize =
    10 * 1024 * 1024;
```

Do not confuse immutable configuration with mutable global state.

---

# 253. Avoid excessive singleton wrappers around SDK singletons

If an SDK already exposes a stable singleton, creating:

```text
FirebaseServiceSingletonProviderFactory
```

may not provide value.

Abstract it when application semantics/testing justify it.

---

# 254. Do not write code for hypothetical future requirements

Avoid:

```text
maybe we'll support five APIs later
maybe we'll replace Firebase
maybe we'll add desktop
maybe we'll need multiple databases
```

as justification for current complexity.

Design for reasonable change, not imaginary product roadmaps.

---

# 255. Avoid premature generalization

If two screens have vaguely similar cards, do not immediately produce a generic card engine.

Wait until the shared concept is clear.

---

# 256. Small duplication is often cheaper than the wrong abstraction

Two explicit implementations can be easier to maintain than a generic widget with twelve optional parameters and five callbacks.

Abstract proven repetition.

---

# 257. Remove dead abstractions after refactoring

If a type improvement makes these unnecessary:

```text
safeString
parseData
UserMapper
ResponseWrapper
BaseRepository
CommonService
WidgetFactory
```

delete them.

Do not leave obsolete compatibility machinery behind without a real caller.

---

# 258. Remove dead state

If a refactor makes:

```dart
bool initialized;
bool loaded;
bool firstLoad;
```

obsolete, remove them.

Do not preserve unused state "just in case."

---

# 259. Remove dead dependencies

If code no longer uses a package, remove it from:

```yaml
pubspec.yaml
```

when safe and within task scope.

Do not leave dependencies indefinitely because removing them feels risky.

---

# 260. Avoid dependency changes during unrelated tasks

Conversely, do not upgrade half the Flutter ecosystem while fixing a button unless required.

Dependency upgrades can introduce unrelated regressions.

---

# 261. Follow analyzer/lints intelligently

Fix meaningful analyzer warnings.

Do not mechanically restructure good code merely to satisfy stylistic rules that conflict with project conventions.

Project lint configuration is part of the codebase contract.

---

# 262. Do not suppress analyzer errors casually

Be suspicious of:

```dart
// ignore:
```

and:

```dart
// ignore_for_file:
```

Understand why the analyzer complains.

Suppress when the exception is deliberate and documented.

---

# 263. Avoid `as dynamic` and analyzer escape hatches

Do not use:

```dart
as dynamic
```

to make the compiler stop complaining.

Fix the type mismatch where practical.

---

# 264. Do not fight generated code

If generated files are managed by:

```text
build_runner
json_serializable
freezed
```

modify the source declaration, not generated output.

---

# 265. Keep code generation commands out of application runtime logic

Build tooling belongs to build/development workflows.

Do not make production code depend on generation-time assumptions that are not guaranteed.

---

# 266. Preserve package/API version semantics

When calling Flutter/package APIs, use the APIs that correspond to the project's actual dependency versions.

Do not blindly copy newer documentation into an older project.

---

# 267. Do not invent plugin APIs

When modifying plugin-specific functionality, inspect the installed package version and current code usage.

Do not guess method names or lifecycle behavior.

---

# 268. Understand the codebase before introducing architecture

Before editing:

1. Identify current state-management approach.
2. Identify networking approach.
3. Identify routing approach.
4. Identify serialization approach.
5. Identify dependency-injection approach, if any.
6. Identify feature/folder organization.
7. Identify external boundaries.
8. Understand actual domain types.
9. Understand widget/state lifecycle involved.
10. Determine whether existing abstractions already solve the problem.

Do not add a new pattern before understanding the existing one.

---

# 269. Inspect call sites before changing shared code

Before changing:

```text
AppButton
ApiClient
UserRepository
AppTheme
Router
shared model
state controller
```

inspect its consumers.

A seemingly harmless simplification can break unrelated flows.

---

# 270. Search before creating

Before creating:

```text
new helper
new component
new model
new formatter
new service
new repository
new state class
new extension
new constant
```

check whether an equivalent concept already exists.

Avoid duplicate architecture.

---

# 271. Prefer editing an existing abstraction over creating a competing one

If the app already has:

```dart
AppTextField
```

do not create:

```dart
CustomInputField
```

for a tiny visual difference unless the semantics genuinely differ.

---

# 272. Do not force reuse where concepts differ

Two components that look similar today may represent different product concepts.

Visual similarity alone does not guarantee they should share one generic implementation.

---

# 273. Mandatory before-change review

Before modifying Flutter/Dart code:

1. Identify trusted and untrusted boundaries.
2. Understand the concrete Dart types.
3. Identify who owns state.
4. Identify who owns disposable resources.
5. Understand relevant widget lifecycle.
6. Check existing state-management conventions.
7. Check existing networking and serialization conventions.
8. Check whether broad/null/dynamic types are accidental.
9. Look upstream before creating converters or validators.
10. Determine the smallest change that correctly solves the task.
11. Preserve security, lifecycle, and platform-specific checks.
12. Avoid introducing new packages or architectural layers without need.

---

# 274. Mandatory after-change review

Before finishing any Flutter change, inspect the diff.

For every added:

```text
class
widget
helper
model
mapper
repository
service
provider
bloc
controller
extension
dependency
nullable field
dynamic value
fallback
runtime check
try/catch
loading flag
GlobalKey
post-frame callback
Future.delayed
```

ask:

1. Does this solve a state that can genuinely occur?
2. Is this compensating for bad typing upstream?
3. Is the state owned at the right level?
4. Could Flutter/Dart already express this directly?
5. Did I create a one-use abstraction?
6. Did I add a layer that only forwards calls?
7. Did I silently convert invalid data into an empty value?
8. Did I make the widget tree harder to trace?
9. Did I introduce unnecessary state management?
10. Did I create unnecessary nullable state?
11. Did I introduce a lifecycle bug?
12. Did I introduce a rebuild/network-call bug?
13. Did I preserve platform behavior?
14. Did I preserve security behavior?
15. Did total complexity increase?
16. Can newly added code be deleted while preserving correctness?

If yes, simplify before completing the task.

---

# 275. AI-generated Flutter code review checklist

Treat these patterns as particularly suspicious in AI-generated code:

```dart
dynamic value
```

```dart
Map<String, dynamic> data
```

deep inside application logic.

```dart
value?.foo?.bar ?? ''
```

when the fields are supposed to be required.

```dart
String safeString(dynamic value)
```

```dart
T? safeCast<T>(dynamic value)
```

```dart
class SomeRepository {
  return service.sameMethod();
}
```

```dart
class SomeUseCase {
  return repository.sameMethod();
}
```

```dart
class SomeProvider extends ChangeNotifier
```

for one local Boolean.

```dart
Widget _buildText(...)
```

used once.

```dart
FutureBuilder(
  future: apiCall(),
)
```

creating requests during rebuilds.

```dart
Future.delayed(...)
```

to fix lifecycle timing.

```dart
WidgetsBinding.instance
    .addPostFrameCallback(...)
```

used as a generic initialization mechanism.

```dart
GlobalKey(...)
```

used as state management.

```dart
try {
  ...
} catch (_) {
  return null;
}
```

```dart
isLoading
hasLoaded
isInitialized
isProcessing
isReady
```

all describing overlapping state.

```dart
Container(
  child: Padding(
    child: Container(
      child: ...
    ),
  ),
)
```

They are not automatically wrong.

They deserve scrutiny.

---

# 276. Desired Flutter style

Prefer:

```dart
class AccountCard extends StatelessWidget {
  const AccountCard({
    required this.account,
    super.key,
  });

  final Account account;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(account.name),
            const SizedBox(height: 8),
            Text(account.formattedBalance),
          ],
        ),
      ),
    );
  }
}
```

over:

```dart
class AccountCard extends StatelessWidget {
  const AccountCard({
    required this.data,
    super.key,
  });

  final Map<String, dynamic>? data;

  String _safeString(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return value;
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final safeData =
        data ?? <String, dynamic>{};

    final accountName =
        _safeString(
          safeData['name'],
        );

    final balance =
        _safeString(
          safeData['balance'],
        );

    return AccountCardWrapper(
      config: AccountCardConfig(
        title: accountName,
        subtitle: balance,
      ),
    );
  }
}
```

---

# 277. Desired API flow

Prefer:

```dart
Future<User> getUser() async {
  final response =
      await dio.get('/user');

  return User.fromJson(
    response.data as Map<String, dynamic>,
  );
}
```

then:

```dart
final user =
    await repository.getUser();

print(user.name);
```

over:

```text
HTTP response
→ dynamic
→ safeMap()
→ API response wrapper
→ DTO
→ mapper
→ entity
→ safe user extractor
→ nullable user
→ fallback user
→ widget
```

unless each transformation has a genuine semantic purpose.

---

# 278. Desired state flow

For simple local state:

```dart
class PasswordField
    extends StatefulWidget {
  const PasswordField({
    super.key,
  });

  @override
  State<PasswordField> createState() =>
      _PasswordFieldState();
}

class _PasswordFieldState
    extends State<PasswordField> {
  bool obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              obscureText =
                  !obscureText;
            });
          },
          icon: Icon(
            obscureText
                ? Icons.visibility
                : Icons.visibility_off,
          ),
        ),
      ),
    );
  }
}
```

Do not turn this into:

```text
PasswordVisibilityEvent
→ PasswordVisibilityBloc
→ PasswordVisibilityState
→ BlocProvider
→ BlocBuilder
→ widget
```

without a real reason.

---

# 279. Desired complex-state flow

For genuinely complex feature state, structured state management is appropriate:

```text
external event/user action
→ controller/bloc/notifier
→ repository/domain operation
→ explicit state transition
→ widgets render state
```

Do not force complex multi-screen state into one giant StatefulWidget merely to avoid architecture.

---

# 280. Root-cause rule

Whenever you see:

```text
dynamic
nullable-everything
safeX
parseX
extractX
convertX
normalizeX
BaseX
Manager
Coordinator
Repository
Service
UseCase
Provider
Controller
Bloc
GlobalKey
Future.delayed
postFrameCallback
```

do not automatically delete it.

Trace why it exists.

Ask:

1. What problem is this solving?
2. Is that problem real?
3. Where does the uncertainty originate?
4. Is this the correct layer to handle it?
5. Can Dart's type system express the invariant?
6. Can state ownership eliminate the workaround?
7. Can lifecycle ownership eliminate the workaround?
8. Can a direct Flutter primitive solve it?
9. Does the abstraction carry real semantics?
10. Would deleting it make the system easier to understand without reducing correctness?

Fix the earliest sensible cause.

---

# 281. Final Flutter anti-slop rule

Do not transform:

```text
typed model
→ state
→ widget
```

into:

```text
dynamic response
→ defensive parser
→ generic map
→ DTO
→ mapper
→ entity
→ repository wrapper
→ use-case wrapper
→ provider wrapper
→ safe extractor
→ fallback
→ generic reusable widget
→ actual UI
```

without genuine requirements supporting those layers.

The desired external-data flow is:

```text
untrusted external input
→ validate/parse once
→ precise Dart type
→ meaningful application state
→ direct Flutter UI
```

The desired internal flow is:

```text
typed value
→ business logic
→ state
→ widget
```

The desired architecture is:

```text
only as complex as the product actually requires
```

The overriding principles are:

> **Make external input safe at the edge. Keep internal Dart strongly typed.**

> **Keep state as close as practical to where it belongs.**

> **Use Flutter's primitives before inventing abstractions around them.**

> **Do not confuse more architecture with better architecture.**

> **Every layer, helper, model, package, and state object must earn its existence.**

> **Prefer boring, explicit, idiomatic Flutter over clever or AI-generated ceremony.**

> **Protect genuine lifecycle, platform, security, and external-data uncertainty. Remove uncertainty invented by your own code.**