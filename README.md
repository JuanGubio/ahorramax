# AhorraMax

AhorraMax es una aplicación financiera inteligente que utiliza inteligencia artificial para ayudar a los usuarios a ahorrar dinero de manera efectiva. La app combina seguimiento de gastos, metas de ahorro, recomendaciones personalizadas con IA y un chat inteligente para encontrar ofertas locales.

## 🚀 Cómo ejecutar el proyecto

### Requisitos previos

- **Flutter SDK** (versión 3.4.0 o superior)
- **Dart SDK** (incluido con Flutter)
- **Node.js** (versión 18 o superior)
- **npm** (gestor de paquetes recomendado)
- **Firebase CLI** (opcional, para configuración de Firebase)

### Configuración inicial

1. **Clona el repositorio:**
   ```bash
   git clone <url-del-repositorio>
   cd ahorramax
   ```

2. **Configura Firebase:**
   - Crea un proyecto en [Firebase Console](https://console.firebase.google.com/)
   - Habilita Authentication, Firestore y Storage
   - Descarga el archivo `google-services.json` y colócalo en `android/app/`
   - Configura las variables de entorno para la API de Google AI

### Ejecutar la aplicación móvil (Flutter)

1. **Instala dependencias:**
   ```bash
   flutter pub get
   ```

2. **Configura Firebase (opcional):**
   ```bash
   flutterfire configure
   ```

3. **Ejecuta en dispositivo/emulador:**
   ```bash
   flutter run
   ```

### Ejecutar la aplicación web (Next.js)

1. **Instala dependencias:**
   ```bash
   npm install
   ```

2. **Ejecuta en modo desarrollo:**
   ```bash
   npm run dev
   ```

3. **Accede a la aplicación:**
   - Abre [http://localhost:3000](http://localhost:3000) en tu navegador

## 🛠 Tecnologías utilizadas

### Aplicación móvil (Flutter)
- **Framework:** Flutter 3.4.0+
- **Lenguaje:** Dart
- **Backend:** Firebase (Authentication, Firestore, Storage, Functions)
- **IA:** Google Generative AI (Gemini)
- **Autenticación:** Firebase Auth + Google Sign-In
- **UI/UX:** Material Design 3, Google Fonts
- **Gráficos:** FL Chart
- **Calendario:** Table Calendar
- **Audio:** Audioplayers
- **Voz:** Speech to Text
- **Almacenamiento seguro:** Flutter Secure Storage
- **Ubicación:** Geolocator
- **Imágenes:** Image Picker, Image Cropper
- **Compartir:** Share Plus
- **Códigos QR:** QR Flutter
- **URL Launcher:** Para abrir enlaces externos

### Aplicación web (Next.js)
- **Framework:** Next.js 16.0.0
- **Lenguaje:** TypeScript
- **UI:** React 19, Tailwind CSS
- **Componentes:** Radix UI (Accordion, Dialog, etc.)
- **Formularios:** React Hook Form + Zod
- **Gráficos:** Recharts
- **Iconos:** Lucide React
- **Tema:** Next Themes
- **Animaciones:** Tailwind Animate
- **Analytics:** Vercel Analytics

### Backend y servicios
- **Base de datos:** Cloud Firestore
- **Autenticación:** Firebase Authentication
- **Almacenamiento:** Firebase Storage
- **Funciones serverless:** Firebase Functions
- **IA:** Google Generative AI API
- **Reglas de seguridad:** Firebase Security Rules

## 📱 Funcionalidad de la aplicación

### Características principales

#### 🤖 Recomendaciones con IA
- Análisis inteligente de patrones de gasto
- Sugerencias personalizadas para ahorrar dinero
- Recomendaciones basadas en ubicación geográfica
- Integración con Gemini AI para insights avanzados

#### 💬 Chat IA Inteligente
- Asistente virtual para consultas sobre finanzas
- Información sobre ofertas y descuentos en Ecuador
- Respuestas personalizadas basadas en el perfil del usuario
- Soporte en español

#### 📊 Seguimiento de gastos
- Registro manual de ingresos y gastos
- Categorización automática de transacciones
- Visualización con gráficos interactivos
- Calendario de gastos para mejor organización

#### 🎯 Metas de ahorro
- Definición de objetivos financieros
- Seguimiento del progreso en tiempo real
- Planes personalizados generados por IA
- Notificaciones motivacionales

#### 🔥 Sistema de rachas (Streaks)
- Seguimiento de hábitos de ahorro
- Recompensas por consistencia
- Gamificación para mantener la motivación
- Estadísticas de rendimiento

#### 🔒 Seguridad y privacidad
- Autenticación segura con Firebase
- Encriptación de datos sensibles
- Almacenamiento seguro de información financiera
- Cumplimiento con estándares de privacidad

### Flujo de usuario

1. **Registro/Inicio de sesión:** Usuario crea cuenta con email/Google
2. **Configuración inicial:** IA crea perfil automático con datos básicos
3. **Registro de gastos:** Usuario ingresa transacciones manualmente
4. **Análisis IA:** Gemini analiza patrones y genera recomendaciones
5. **Metas y seguimiento:** Usuario define objetivos y recibe planes
6. **Chat interactivo:** Consultas sobre ofertas y consejos financieros
7. **Dashboard:** Vista general del progreso financiero

### Arquitectura

La aplicación sigue una arquitectura híbrida:

- **Móvil:** Flutter con patrón Provider para state management
- **Web:** Next.js con App Router y componentes server/client
- **Backend:** Firebase como BaaS (Backend as a Service)
- **IA:** Integración directa con Google AI APIs
- **Base de datos:** NoSQL con Firestore para flexibilidad

### Estructura del proyecto

```
ahorramax/
├── android/                 # Configuración Android
├── ios/                     # Configuración iOS
├── lib/                     # Código Flutter
│   ├── models/             # Modelos de datos
│   ├── screens/            # Pantallas de la app
│   ├── services/           # Servicios (Firebase, IA, etc.)
│   └── widgets/            # Componentes reutilizables
├── app/                     # Aplicación web Next.js
│   ├── api/                # API routes
│   ├── components/         # Componentes React
│   ├── dashboard/          # Páginas del dashboard
│   └── login/              # Páginas de autenticación
├── components/             # Componentes compartidos
├── hooks/                  # Custom hooks
└── assets/                 # Recursos multimedia
```

## 📈 Próximas mejoras

- Integración con bancos para sincronización automática
- Análisis predictivo de gastos futuros
- Comunidad de usuarios para compartir tips
- Integración con wallets digitales
- Modo offline para registro básico

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 📞 Contacto

- Proyecto: [GitHub Repository]
- Email: [tu-email@ejemplo.com]

---

¡Gracias por usar AhorraMax! 💰✨
