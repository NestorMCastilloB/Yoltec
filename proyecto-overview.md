# Estructura de archivos
.
├── backend
│   ├── app
│   │   ├── Console
│   │   │   └── Commands
│   │   │       ├── AutoCancelarCitasPasadas.php
│   │   │       ├── EntrenarIA.php
│   │   │       └── NotificarCitasProximas.php
│   │   ├── Http
│   │   │   ├── Controllers
│   │   │   │   ├── AdminController.php
│   │   │   │   ├── AuthController.php
│   │   │   │   ├── BitacoraController.php
│   │   │   │   ├── CalendarioAdminController.php
│   │   │   │   ├── CitaController.php
│   │   │   │   ├── ConsultaController.php
│   │   │   │   ├── Controller.php
│   │   │   │   ├── EstadisticasController.php
│   │   │   │   ├── IAPriorityController.php
│   │   │   │   ├── IASymptomController.php
│   │   │   │   ├── PasswordResetController.php
│   │   │   │   ├── PerfilController.php
│   │   │   │   ├── PerfilMedicoController.php
│   │   │   │   ├── PreEvaluacionIAController.php
│   │   │   │   └── RecetaController.php
│   │   │   └── Middleware
│   │   │       ├── EnsureIsAdmin.php
│   │   │       └── SecurityHeaders.php
│   │   ├── IA
│   │   │   ├── Data
│   │   │   │   └── MedicalDataset.php
│   │   │   ├── Models
│   │   │   │   ├── NaiveBayesClassifier.php
│   │   │   │   └── PriorityClassifier.php
│   │   │   └── Services
│   │   │       └── IAService.php
│   │   ├── Mail
│   │   │   ├── CitaProximaMail.php
│   │   │   ├── PasswordResetMail.php
│   │   │   └── TwoFactorCodeMail.php
│   │   ├── Models
│   │   │   ├── AuditLog.php
│   │   │   ├── Bitacora.php
│   │   │   ├── Cita.php
│   │   │   ├── Consulta.php
│   │   │   ├── DiaEspecial.php
│   │   │   ├── PasswordResetToken.php
│   │   │   ├── PreEvaluacionIA.php
│   │   │   ├── Receta.php
│   │   │   ├── TrustedDevice.php
│   │   │   ├── TwoFactorCode.php
│   │   │   └── User.php
│   │   ├── Providers
│   │   │   └── AppServiceProvider.php
│   │   └── Services
│   │       └── FcmService.php
│   ├── artisan
│   ├── bootstrap
│   │   ├── app.php
│   │   └── providers.php
│   ├── composer.json
│   ├── composer.lock
│   ├── config
│   │   ├── app.php
│   │   ├── auth.php
│   │   ├── cache.php
│   │   ├── clinic.php
│   │   ├── cors.php
│   │   ├── database.php
│   │   ├── filesystems.php
│   │   ├── logging.php
│   │   ├── mail.php
│   │   ├── queue.php
│   │   ├── sanctum.php
│   │   ├── services.php
│   │   └── session.php
│   ├── database
│   │   ├── factories
│   │   │   └── UserFactory.php
│   │   ├── migrations
│   │   │   ├── 0001_01_01_000000_create_users_table.php
│   │   │   ├── 2025_11_12_200331_create_citas_table.php
│   │   │   ├── 2025_11_12_200344_create_bitacoras_table.php
│   │   │   ├── 2025_11_12_200351_create_recetas_table.php
│   │   │   ├── 2025_11_13_073400_create_personal_access_tokens_table.php
│   │   │   ├── 2025_11_13_161436_create_sessions_table.php
│   │   │   ├── 2025_12_02_205354_create_cache_table.php
│   │   │   ├── 2026_03_03_000001_create_two_factor_codes_table.php
│   │   │   ├── 2026_03_03_000002_create_audit_logs_table.php
│   │   │   ├── 2026_03_16_000002_create_pre_evaluaciones_ia_table.php
│   │   │   ├── 2026_04_09_123522_create_trusted_devices_table.php
│   │   │   ├── 2026_04_16_073212_add_es_admin_to_users_table.php
│   │   │   ├── 2026_04_16_074338_create_password_reset_tokens_table.php
│   │   │   ├── 2026_04_16_075501_create_dias_especiales_table.php
│   │   │   ├── 2026_04_16_185914_add_fcm_token_to_users_table.php
│   │   │   ├── 2026_04_16_190433_create_consultas_table.php
│   │   │   ├── 2026_04_16_190952_add_perfil_medico_to_users_table.php
│   │   │   ├── 2026_04_16_191506_add_foto_perfil_to_users_table.php
│   │   │   ├── 2026_04_18_200246_add_soft_deletes_to_citas_table.php
│   │   │   ├── 2026_04_27_100000_add_security_constraints.php
│   │   │   ├── 2026_04_28_099999_widen_nip_column.php
│   │   │   ├── 2026_04_28_100000_add_foreign_keys_to_citas_table.php
│   │   │   ├── 2026_04_28_100001_hash_existing_nips.php
│   │   │   └── 2026_04_29_000001_change_foto_perfil_to_text.php
│   │   └── seeders
│   │       ├── AdminUserSeeder.php
│   │       ├── DatabaseSeeder.php
│   │       └── DemoDataSeeder.php
│   ├── docker-entrypoint.sh
│   ├── Dockerfile
│   ├── package.json
│   ├── phpunit.xml
│   ├── public
│   │   ├── favicon.ico
│   │   ├── index.php
│   │   └── robots.txt
│   ├── README.md
│   ├── resources
│   │   ├── css
│   │   │   └── app.css
│   │   ├── js
│   │   │   ├── app.js
│   │   │   └── bootstrap.js
│   │   └── views
│   │       ├── emails
│   │       │   ├── cita-proxima.blade.php
│   │       │   ├── password-reset.blade.php
│   │       │   └── two-factor-code.blade.php
│   │       └── welcome.blade.php
│   ├── routes
│   │   ├── api.php
│   │   ├── console.php
│   │   └── web.php
│   ├── storage
│   │   ├── app
│   │   │   ├── private
│   │   │   └── public
│   │   └── framework
│   │       └── testing
│   ├── tests
│   │   ├── Feature
│   │   │   └── ExampleTest.php
│   │   ├── TestCase.php
│   │   └── Unit
│   │       └── ExampleTest.php
│   └── vite.config.js
├── docker-compose.yml
├── docs
│   ├── contexto_claude_project.md
│   ├── diagrama_arquitectura.mmd
│   ├── diagrama_arquitectura.png
│   ├── diagrama_dominio.mmd
│   ├── diagrama_dominio.png
│   ├── entregable_sistema.md
│   ├── explicacion-ia.md
│   ├── informe-pentesting.md
│   ├── jira-plan-sprints.md
│   ├── MANUAL_TECNICO.md
│   ├── MANUAL_USUARIO.md
│   ├── monografia_seguridad_u3.md
│   ├── onboarding-colaborador.md
│   ├── plan-trabajo-comercial.md
│   ├── pruebas-formales.md
│   ├── script-demo.md
│   └── setup_windows.md
├── frontend
│   ├── angular.json
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json
│   ├── package-lock.json
│   ├── proxy.conf.json
│   ├── public
│   │   ├── favicon.ico
│   │   ├── fonts
│   │   │   ├── Inter-Bold.woff2
│   │   │   ├── Inter-Medium.woff2
│   │   │   ├── Inter-Regular.woff2
│   │   │   └── Inter-SemiBold.woff2
│   │   └── logo.jpeg
│   ├── README.md
│   ├── src
│   │   ├── app
│   │   │   ├── app.component.css
│   │   │   ├── app.component.html
│   │   │   ├── app.component.ts
│   │   │   ├── app.config.ts
│   │   │   ├── app.routes.ts
│   │   │   ├── app.ts
│   │   │   ├── components
│   │   │   │   ├── admin
│   │   │   │   │   ├── admin-dashboard
│   │   │   │   │   │   ├── admin-dashboard.component.css
│   │   │   │   │   │   ├── admin-dashboard.component.html
│   │   │   │   │   │   └── admin-dashboard.component.ts
│   │   │   │   │   └── admin-login
│   │   │   │   │       ├── admin-login.component.css
│   │   │   │   │       ├── admin-login.component.html
│   │   │   │   │       └── admin-login.component.ts
│   │   │   │   ├── doctor
│   │   │   │   │   ├── components-doctor
│   │   │   │   │   │   ├── doctor-bitacoras
│   │   │   │   │   │   │   ├── doctor-bitacoras.component.css
│   │   │   │   │   │   │   ├── doctor-bitacoras.component.html
│   │   │   │   │   │   │   └── doctor-bitacoras.component.ts
│   │   │   │   │   │   ├── doctor-citas
│   │   │   │   │   │   │   ├── doctor-citas.component.css
│   │   │   │   │   │   │   ├── doctor-citas.component.html
│   │   │   │   │   │   │   └── doctor-citas.component.ts
│   │   │   │   │   │   ├── doctor-estadisticas
│   │   │   │   │   │   │   ├── doctor-estadisticas.component.css
│   │   │   │   │   │   │   ├── doctor-estadisticas.component.html
│   │   │   │   │   │   │   └── doctor-estadisticas.component.ts
│   │   │   │   │   │   ├── doctor-ficha-paciente
│   │   │   │   │   │   │   ├── doctor-ficha-paciente.component.css
│   │   │   │   │   │   │   ├── doctor-ficha-paciente.component.html
│   │   │   │   │   │   │   └── doctor-ficha-paciente.component.ts
│   │   │   │   │   │   ├── doctor-header
│   │   │   │   │   │   │   ├── doctor-header.component.css
│   │   │   │   │   │   │   ├── doctor-header.component.html
│   │   │   │   │   │   │   └── doctor-header.component.ts
│   │   │   │   │   │   ├── doctor-ia-prioridad
│   │   │   │   │   │   │   ├── doctor-ia-prioridad.component.css
│   │   │   │   │   │   │   ├── doctor-ia-prioridad.component.html
│   │   │   │   │   │   │   └── doctor-ia-prioridad.component.ts
│   │   │   │   │   │   ├── doctor-inicio
│   │   │   │   │   │   │   ├── doctor-inicio.component.css
│   │   │   │   │   │   │   ├── doctor-inicio.component.html
│   │   │   │   │   │   │   └── doctor-inicio.component.ts
│   │   │   │   │   │   ├── doctor-pre-evaluaciones
│   │   │   │   │   │   │   ├── doctor-pre-evaluaciones.component.css
│   │   │   │   │   │   │   ├── doctor-pre-evaluaciones.component.html
│   │   │   │   │   │   │   └── doctor-pre-evaluaciones.component.ts
│   │   │   │   │   │   └── doctor-recetas
│   │   │   │   │   │       ├── doctor-recetas.component.css
│   │   │   │   │   │       ├── doctor-recetas.component.html
│   │   │   │   │   │       └── doctor-recetas.component.ts
│   │   │   │   │   └── doctor-dashboard
│   │   │   │   │       ├── doctor-dashboard.component.css
│   │   │   │   │       ├── doctor-dashboard.component.html
│   │   │   │   │       └── doctor-dashboard.component.ts
│   │   │   │   ├── login
│   │   │   │   │   ├── forgot-password
│   │   │   │   │   │   ├── forgot-password.component.css
│   │   │   │   │   │   ├── forgot-password.component.html
│   │   │   │   │   │   └── forgot-password.component.ts
│   │   │   │   │   ├── login
│   │   │   │   │   │   ├── login.component.css
│   │   │   │   │   │   ├── login.component.html
│   │   │   │   │   │   └── login.component.ts
│   │   │   │   │   ├── reset-password
│   │   │   │   │   │   ├── reset-password.component.css
│   │   │   │   │   │   ├── reset-password.component.html
│   │   │   │   │   │   └── reset-password.component.ts
│   │   │   │   │   ├── splash-screen
│   │   │   │   │   │   ├── splash-screen.component.css
│   │   │   │   │   │   ├── splash-screen.component.html
│   │   │   │   │   │   └── splash-screen.component.ts
│   │   │   │   │   └── verify-2fa
│   │   │   │   │       ├── verify-2fa.component.css
│   │   │   │   │       ├── verify-2fa.component.html
│   │   │   │   │       └── verify-2fa.component.ts
│   │   │   │   ├── shared
│   │   │   │   └── student
│   │   │   │       └── student-dashboard
│   │   │   │           ├── components
│   │   │   │           │   ├── sd-bitacora
│   │   │   │           │   │   ├── sd-bitacora.component.html
│   │   │   │           │   │   └── sd-bitacora.component.ts
│   │   │   │           │   ├── sd-citas
│   │   │   │           │   │   ├── sd-citas.component.html
│   │   │   │           │   │   └── sd-citas.component.ts
│   │   │   │           │   ├── sd-historial
│   │   │   │           │   │   ├── sd-historial.component.html
│   │   │   │           │   │   └── sd-historial.component.ts
│   │   │   │           │   ├── sd-inicio
│   │   │   │           │   │   ├── sd-inicio.component.html
│   │   │   │           │   │   └── sd-inicio.component.ts
│   │   │   │           │   ├── sd-perfil
│   │   │   │           │   │   ├── sd-perfil.component.html
│   │   │   │           │   │   └── sd-perfil.component.ts
│   │   │   │           │   └── sd-recetas
│   │   │   │           │       ├── sd-recetas.component.html
│   │   │   │           │       └── sd-recetas.component.ts
│   │   │   │           ├── student-dashboard.component.css
│   │   │   │           ├── student-dashboard.component.html
│   │   │   │           └── student-dashboard.component.ts
│   │   │   ├── guards
│   │   │   │   └── auth.guard.ts
│   │   │   ├── interceptors
│   │   │   │   └── auth.interceptor.ts
│   │   │   └── services
│   │   │       ├── admin.service.ts
│   │   │       ├── api-config.ts
│   │   │       ├── auth.service.ts
│   │   │       ├── bitacora.service.ts
│   │   │       ├── calendario-admin.service.ts
│   │   │       ├── cita.service.ts
│   │   │       ├── consulta.service.ts
│   │   │       ├── estadisticas.service.ts
│   │   │       ├── ia-priority.service.ts
│   │   │       ├── perfil-medico.service.ts
│   │   │       ├── pre-evaluacion-ia.service.ts
│   │   │       ├── receta.service.ts
│   │   │       ├── theme.service.ts
│   │   │       └── user.service.ts
│   │   ├── environments
│   │   │   ├── environment.prod.ts
│   │   │   └── environment.ts
│   │   ├── index.html
│   │   ├── main.ts
│   │   └── styles.css
│   ├── tsconfig.app.json
│   ├── tsconfig.json
│   ├── tsconfig.spec.json
│   └── vercel.json
├── IA
│   ├── app.py
│   ├── Dockerfile
│   ├── enfermedades_config.json
│   ├── feature_names.json
│   ├── pre_evaluacion_ia.py
│   ├── requirements.txt
│   ├── train_model_light.py
│   └── train_model.py
├── mobile
│   ├── analysis_options.yaml
│   ├── android
│   │   ├── app
│   │   │   ├── build.gradle.kts
│   │   │   └── src
│   │   │       ├── debug
│   │   │       │   └── AndroidManifest.xml
│   │   │       ├── main
│   │   │       │   ├── AndroidManifest.xml
│   │   │       │   ├── java
│   │   │       │   │   └── io
│   │   │       │   │       └── flutter
│   │   │       │   │           └── plugins
│   │   │       │   ├── kotlin
│   │   │       │   │   └── com
│   │   │       │   │       └── yoltec
│   │   │       │   │           └── app
│   │   │       │   │               └── MainActivity.kt
│   │   │       │   └── res
│   │   │       │       ├── drawable
│   │   │       │       │   └── launch_background.xml
│   │   │       │       ├── drawable-v21
│   │   │       │       │   └── launch_background.xml
│   │   │       │       ├── mipmap-hdpi
│   │   │       │       │   └── ic_launcher.png
│   │   │       │       ├── mipmap-mdpi
│   │   │       │       │   └── ic_launcher.png
│   │   │       │       ├── mipmap-xhdpi
│   │   │       │       │   └── ic_launcher.png
│   │   │       │       ├── mipmap-xxhdpi
│   │   │       │       │   └── ic_launcher.png
│   │   │       │       ├── mipmap-xxxhdpi
│   │   │       │       │   └── ic_launcher.png
│   │   │       │       ├── values
│   │   │       │       │   └── styles.xml
│   │   │       │       ├── values-night
│   │   │       │       │   └── styles.xml
│   │   │       │       └── xml
│   │   │       │           └── network_security_config.xml
│   │   │       └── profile
│   │   │           └── AndroidManifest.xml
│   │   ├── build.gradle.kts
│   │   ├── gradle
│   │   │   └── wrapper
│   │   │       └── gradle-wrapper.properties
│   │   ├── gradle.properties
│   │   └── settings.gradle.kts
│   ├── lib
│   │   ├── ia
│   │   │   └── sistema_experto.dart
│   │   ├── main.dart
│   │   ├── models
│   │   │   ├── bitacora.dart
│   │   │   ├── cita.dart
│   │   │   ├── receta.dart
│   │   │   └── user.dart
│   │   ├── screens
│   │   │   ├── auth_wrapper.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── ia_assistant_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── pre_evaluacion_screen.dart
│   │   │   ├── splash_screen.dart
│   │   │   ├── student
│   │   │   │   ├── bitacora_tab.dart
│   │   │   │   ├── citas_tab.dart
│   │   │   │   ├── inicio_tab.dart
│   │   │   │   ├── perfil_tab.dart
│   │   │   │   ├── recetas_tab.dart
│   │   │   │   ├── student_home_screen.dart
│   │   │   │   └── student_widgets.dart
│   │   │   └── two_factor_screen.dart
│   │   ├── services
│   │   │   ├── api_service.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── bitacora_service.dart
│   │   │   ├── cita_service.dart
│   │   │   ├── notification_service.dart
│   │   │   ├── offline_cache_service.dart
│   │   │   ├── pre_evaluacion_service.dart
│   │   │   ├── receta_service.dart
│   │   │   └── theme_service.dart
│   │   ├── utils
│   │   │   └── app_theme.dart
│   │   └── widgets
│   │       ├── custom_button.dart
│   │       └── custom_text_field.dart
│   ├── linux
│   │   ├── CMakeLists.txt
│   │   ├── flutter
│   │   │   ├── CMakeLists.txt
│   │   │   ├── generated_plugin_registrant.cc
│   │   │   ├── generated_plugin_registrant.h
│   │   │   └── generated_plugins.cmake
│   │   └── runner
│   │       ├── CMakeLists.txt
│   │       ├── main.cc
│   │       ├── my_application.cc
│   │       └── my_application.h
│   ├── pubspec.lock
│   ├── pubspec.yaml
│   ├── README.md
│   ├── test
│   │   └── widget_test.dart
│   └── web
│       ├── favicon.png
│       ├── icons
│       │   ├── Icon-192.png
│       │   ├── Icon-512.png
│       │   ├── Icon-maskable-192.png
│       │   └── Icon-maskable-512.png
│       ├── index.html
│       └── manifest.json
├── proyecto-overview.md
├── README.md
├── releases
│   └── README.md
└── start.sh

124 directories, 320 files

