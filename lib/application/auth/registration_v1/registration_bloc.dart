import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domainv1/repositories/auth_repository.dart';
import '../../../domainv1/models/sign_up_data.dart';
import '../../../domainv1/services/auth_service.dart';
import 'registration_event.dart';
import 'registration_state.dart';

/*class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final AuthService _authService;
  final AuthRepository _authRepository;

  RegistrationBloc({
    required AuthService authService,
    required AuthRepository authRepository,
  })  : _authService = authService,
        _authRepository = authRepository,
        super(const RegistrationState()) {
    on<StepChanged>(_onStepChanged);
    on<PersonalInfoSubmitted>(_onPersonalInfoSubmitted);
    on<EmailPasswordSubmitted>(_onEmailPasswordSubmitted);
    on<ColegiaturaSubmitted>(_onColegiaturaSubmitted);
    on<SpecialtySubmitted>(_onSpecialtySubmitted);
    on<LocationSubmitted>(_onLocationSubmitted);
    on<FinalRegistrationSubmitted>(_onFinalRegistrationSubmitted);
    on<EmailExistenceChecked>(_onEmailExistenceChecked);
    on<CNPVerificationRequested>(_onCNPVerificationRequested);
    on<RegistrationReset>(_onRegistrationReset);
  }

  void _onStepChanged(StepChanged event, Emitter<RegistrationState> emit) {
    emit(state.copyWith(currentStep: event.step));
  }

  void _onPersonalInfoSubmitted(
      PersonalInfoSubmitted event,
      Emitter<RegistrationState> emit,
      ) {
    emit(state.copyWith(
      firstName: event.firstName,
      lastName: event.lastName,
      photo: event.photo,
      isPersonalInfoValid: _validatePersonalInfo(event.firstName, event.lastName),
    ));
  }

  Future<void> _onEmailPasswordSubmitted(
      EmailPasswordSubmitted event,
      Emitter<RegistrationState> emit,
      ) async {
    emit(state.copyWith(
      email: event.email,
      password: event.password,
      confirmPassword: event.confirmPassword,
      isEmailPasswordValid: _validateEmailPassword(
        event.email,
        event.password,
        event.confirmPassword,
      ),
    ));

    // Verificar si el email ya existe
    if (_validateEmail(event.email)) {
      add(EmailExistenceChecked(event.email));
    }
  }

  Future<void> _onEmailExistenceChecked(
      EmailExistenceChecked event,
      Emitter<RegistrationState> emit,
      ) async {
    try {
      emit(state.copyWith(emailCheckInProgress: true));

      final emailExists = await _authRepository.checkEmailExists(event.email);

      emit(state.copyWith(
        emailExists: emailExists,
        emailCheckInProgress: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        emailCheckInProgress: false,
        errorMessage: 'Error al verificar el email: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCNPVerificationRequested(
      CNPVerificationRequested event,
      Emitter<RegistrationState> emit,
      ) async {
    try {
      emit(state.copyWith(cnpVerificationInProgress: true));

      //final isCnpValid = await _authRepository.verifyCNP(event.cnp);

      emit(state.copyWith(
        cnp: event.cnp,
        //isCnpValid: isCnpValid,
        cnpVerificationInProgress: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        cnpVerificationInProgress: false,
        isCnpValid: false,
        errorMessage: 'Error al verificar el CNP: ${e.toString()}',
      ));
    }
  }

  void _onColegiaturaSubmitted(
      ColegiaturaSubmitted event,
      Emitter<RegistrationState> emit,
      ) {
    emit(state.copyWith(
      cnp: event.cnp,
      colegio: event.colegio,
      isColegiaturaValid: _validateColegiatura(event.cnp, event.colegio),
    ));
  }

  void _onSpecialtySubmitted(
      SpecialtySubmitted event,
      Emitter<RegistrationState> emit,
      ) {
    emit(state.copyWith(
      specialty: event.specialty,
      subSpecialty: event.subSpecialty,
      isSpecialtyValid: _validateSpecialty(event.specialty, event.subSpecialty),
    ));
  }

  void _onLocationSubmitted(
      LocationSubmitted event,
      Emitter<RegistrationState> emit,
      ) {
    emit(state.copyWith(
      department: event.department,
      province: event.province,
      district: event.district,
      isLocationValid: _validateLocation(event.department, event.province, event.district),
    ));
  }

  Future<void> _onFinalRegistrationSubmitted(
      FinalRegistrationSubmitted event,
      Emitter<RegistrationState> emit,
      ) async {
    if (!_canSubmitRegistration()) {
      emit(state.copyWith(
        errorMessage: 'Por favor, complete todos los campos requeridos',
      ));
      return;
    }

    try {
      emit(state.copyWith(status: RegistrationStatus.loading));

      /*final signUpData = SignUpData(
        firstName: state.firstName,
        lastName: state.lastName,
        email: state.email,
        password: state.password,
        cnpCode: state.cnp,
        cnpPhotos: state.cnpPhotos,
        specialty: state.specialty,
        subSpecialty: state.subSpecialty,
        department: state.department,
        province: state.province,
        district: state.district,
        photo: state.photo,
      );*/

      //final result = await _authService.signUp(signUpData);

      /*if (result.isSuccess) {
        emit(state.copyWith(
          status: RegistrationStatus.success,
          isRegistrationComplete: true,
        ));
      } else {
        emit(state.copyWith(
          status: RegistrationStatus.failure,
          errorMessage: result.errorMessage ?? 'Error desconocido durante el registro',
        ));
      }*/
    } catch (e) {
      emit(state.copyWith(
        status: RegistrationStatus.failure,
        errorMessage: 'Error durante el registro: ${e.toString()}',
      ));
    }
  }

  void _onRegistrationReset(
      RegistrationReset event,
      Emitter<RegistrationState> emit,
      ) {
    emit(const RegistrationState());
  }

  // Métodos de validación
  bool _validatePersonalInfo(String firstName, String lastName) {
    return firstName.trim().isNotEmpty &&
        lastName.trim().isNotEmpty &&
        firstName.trim().length >= 2 &&
        lastName.trim().length >= 2;
  }

  bool _validateEmailPassword(String email, String password, String confirmPassword) {
    return _validateEmail(email) &&
        _validatePassword(password) &&
        password == confirmPassword;
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    // Al menos 8 caracteres, una mayúscula, una minúscula y un número
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  bool _validateColegiatura(String cnp, String colegio) {
    return cnp.trim().isNotEmpty &&
        colegio.trim().isNotEmpty &&
        cnp.length >= 4;
  }

  bool _validateSpecialty(String specialty, String subSpecialty) {
    return specialty.trim().isNotEmpty && subSpecialty.trim().isNotEmpty;
  }

  bool _validateLocation(String department, String province, String district) {
    return department.trim().isNotEmpty &&
        province.trim().isNotEmpty &&
        district.trim().isNotEmpty;
  }

  bool _canSubmitRegistration() {
    return state.isPersonalInfoValid &&
        state.isEmailPasswordValid &&
        !state.emailExists &&
        state.isColegiaturaValid &&
        state.isCnpValid &&
        state.isSpecialtyValid &&
        state.isLocationValid;
  }
}*/