part of 'authentication_bloc.dart';

enum AuthenticationStatus { authenticated, unauthenticated, unknown }

@immutable
class AuthenticationState extends Equatable {
  final AuthenticationStatus status;
  final UserModel user;
  const AuthenticationState._(
      {this.status = AuthenticationStatus.unknown,
      this.user = UserModel.empty});
  const AuthenticationState.unknown() : this._();
  const AuthenticationState.authenticated(UserModel user)
      : this._(status: AuthenticationStatus.authenticated, user: user);

  const AuthenticationState.unauthenticated()
      : this._(status: AuthenticationStatus.unauthenticated);
  @override
  List<Object> get props => [status, user];
}
