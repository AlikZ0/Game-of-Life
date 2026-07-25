/// Pure domain representation of an authenticated user. Maps from the API
/// `User` (Prisma) but is decoupled from transport DTOs.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.provider,
    required this.emailVerified,
    required this.hasCharacter,
  });

  final String id;
  final String email;
  final String provider; // EMAIL | GOOGLE | APPLE
  final bool emailVerified;

  /// Whether the user has completed character creation. Drives the onboarding
  /// redirect in the router.
  final bool hasCharacter;
}
