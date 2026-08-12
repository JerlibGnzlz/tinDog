# Google Sign-In (Android)

Flujo: app obtiene `idToken` de Google → `POST /auth/google` → Nest verifica el token → JWT propio de tinDog.

## 1. Google Cloud / Firebase Console

Proyecto Firebase: `tindog-dev-eb3a1`  
Package Android: `com.tindog.tindog_app`

1. Abrí [Firebase Console](https://console.firebase.google.com/) → proyecto → **Authentication** → Sign-in method → habilitar **Google** (opcional si solo usás Google Sign-In nativo; igual conviene).
2. En [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials (mismo proyecto):
   - Creá / verificá un **OAuth client ID tipo Web** → este es el `GOOGLE_SERVER_CLIENT_ID`.
   - Creá / verificá un **OAuth client ID tipo Android** con:
     - Package: `com.tindog.tindog_app`
     - **SHA-1 debug** (este entorno):

```
56:46:F7:AE:10:42:F8:3E:F0:CC:3F:70:37:54:7F:BF:DE:BC:3E:30
```

SHA-256 debug:

```
7F:69:7D:DD:B1:FD:C9:3C:50:3E:0F:0A:B9:BB:D3:C2:1D:D5:CB:D6:47:D0:82:71:CC:DA:28:E9:B9:3B:29:0A
```

3. Descargá de nuevo `google-services.json` y reemplazá  
   `tindog-app/android/app/google-services.json`  
   (debe tener `oauth_client` no vacío).

## 2. API (Nest)

En `.env.development` (no commitear):

```env
GOOGLE_CLIENT_IDS="WEB_CLIENT_ID.apps.googleusercontent.com,ANDROID_CLIENT_ID.apps.googleusercontent.com"
```

Reiniciá `npm run start:dev`.

Endpoint:

```http
POST /auth/google
{ "idToken": "..." }
→ { "accessToken": "...", "needsPetOnboarding": true }
```

- Crea usuario si no existe (`password_hash` null, guarda `google_sub`).
- El nombre de Google se guarda en **Datos personales** (vos), no como mascota.
- Si falta nombre de mascota → la app abre onboarding `/profile/pet`.
- Si el email ya existe, vincula Google a esa cuenta.
- Login email/password en cuenta solo-Google → mensaje para usar Google.

## 3. App Flutter

En `dart_defines/android_dev.json` (y device):

```json
{
  "API_BASE_URL": "http://10.0.2.2:3000",
  "STREAM_API_KEY": "...",
  "GOOGLE_SERVER_CLIENT_ID": "WEB_CLIENT_ID.apps.googleusercontent.com"
}
```

Full restart (plugin nativo):

```bash
flutter run -d <device> --dart-define-from-file=dart_defines/android_dev.json
```

## 4. Emulador vs celular

Google Sign-In **falla en muchos AVD** si no tienen **Play Store** (Play Services).

- Creá un emulador con el ícono de Play Store, iniciá sesión con un Gmail en Ajustes → Cuentas.
- O probá en el **celular físico** (más fiable).

## 5. Probar

1. Welcome → **Continuar con Google**
2. Elegí cuenta → deberías entrar a `/home`
3. Cerrar sesión y repetir (misma cuenta, sin crear duplicado)

## iOS

Pendiente (Client ID iOS + URL scheme). El botón en iOS sigue mostrando “Próximamente”.
