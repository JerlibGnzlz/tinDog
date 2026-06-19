/// Textos legales mínimos para MVP tinDog (revisar con asesoría legal antes de prod).
abstract final class LegalDocuments {
  static const lastUpdated = 'Junio 2026';

  static const privacyTitle = 'Política de privacidad';
  static const privacyBody = '''
Última actualización: $lastUpdated

tinDog (“nosotros”) respeta tu privacidad. Esta política describe qué datos recopilamos y cómo los usamos en la app tinDog.

1. Datos que recopilamos
• Email y contraseña (contraseña almacenada solo de forma cifrada en nuestros servidores).
• Datos de perfil: nombre, bio, ubicación y foto de tu mascota que decidas cargar.
• Datos técnicos básicos: identificadores de sesión (JWT) y logs de error necesarios para operar el servicio.

2. Para qué usamos tus datos
• Crear y administrar tu cuenta.
• Mostrar tu perfil dentro de la app.
• Mejorar seguridad, prevenir abusos y dar soporte.

3. Con quién los compartimos
• Proveedores de infraestructura (hosting de base de datos, almacenamiento de imágenes) solo para prestar el servicio.
• No vendemos tus datos personales.

4. Conservación y seguridad
• Conservamos los datos mientras mantengas tu cuenta activa.
• Aplicamos medidas razonables: contraseñas hasheadas, conexiones seguras y acceso restringido.

5. Tus derechos
• Podés acceder, corregir o solicitar la eliminación de tus datos contactándonos.
• Podés cerrar sesión desde la app en cualquier momento.

6. Contacto
• Para consultas sobre privacidad: privacidad@tindog.app

Este texto es informativo para el MVP y puede actualizarse conforme evolucione el producto.
''';

  static const cookiesTitle = 'Política de cookies';
  static const cookiesBody = '''
Última actualización: $lastUpdated

tinDog utiliza almacenamiento local y tecnologías similares en tu dispositivo para:

• Mantener tu sesión iniciada de forma segura.
• Recordar preferencias básicas de la app.
• Medir errores técnicos y mejorar estabilidad.

En la app móvil no usamos cookies de navegador como un sitio web, pero el principio es el mismo: guardar información necesaria en tu dispositivo para que la app funcione.

Podés eliminar estos datos cerrando sesión o desinstalando la aplicación.

Para más información sobre el tratamiento de datos personales, consultá nuestra Política de privacidad.

Contacto: privacidad@tindog.app
''';

  static const termsTitle = 'Términos y condiciones';
  static const termsBody = '''
Última actualización: $lastUpdated

Al usar tinDog aceptás estos términos. Si no estás de acuerdo, no uses la app.

1. Servicio
tinDog es una plataforma para conectar dueños de mascotas. El servicio se ofrece en evolución (MVP) y puede cambiar.

2. Tu cuenta
• Debés ser mayor de 18 años o contar con autorización de un adulto responsable.
• Sos responsable de la veracidad de la información que publicás.
• Mantené tu contraseña en secreto.

3. Uso permitido
• Tratá a otros usuarios con respeto.
• No publiques contenido ilegal, ofensivo o que viole derechos de terceros.
• No intentes acceder a cuentas ajenas ni interferir con el servicio.

4. Contenido
• Conservás los derechos sobre las fotos y datos que subís.
• Nos otorgás una licencia limitada para mostrar ese contenido dentro de la app con el fin de prestar el servicio.

5. Limitación de responsabilidad
tinDog se proporciona “tal cual”. No garantizamos matches ni resultados específicos. No somos responsables por encuentros o acuerdos entre usuarios fuera de la plataforma.

6. Cambios
Podemos actualizar estos términos. Te informaremos en la app cuando sea relevante.

7. Contacto
• Consultas legales: legal@tindog.app

Este documento es una base mínima para el MVP y no sustituye asesoramiento legal profesional.
''';
}
