# Probar Brote en Android (APK)

Cómo generar un APK de prueba e instalarlo en un móvil Android, sin pasar por Google Play.

## Lo que se instala una sola vez en el PC

| Pieza | Para qué | Dónde se configura |
|---|---|---|
| **JDK 17** (por ejemplo, Eclipse Temurin 17) | Firmar el APK | Godot, Editor > Configuración del editor > Exportar > Android > `java_sdk_path` |
| **Android SDK**: `platform-tools`, `build-tools` y una plataforma (`platforms;android-35`) | `adb` y `apksigner` | `android_sdk_path` (por defecto `%LOCALAPPDATA%\Android\Sdk`) |
| **Plantillas de exportación de Godot 4.7.2** | La base del APK (`android_debug.apk`, `android_release.apk`) | Godot, Editor > Administrar plantillas de exportación |

El SDK se puede instalar con Android Studio o solo con las *command-line tools*. Con estas últimas:

```
sdkmanager --sdk_root=%LOCALAPPDATA%\Android\Sdk "platform-tools" "build-tools;35.0.0" "platforms;android-35"
sdkmanager --sdk_root=%LOCALAPPDATA%\Android\Sdk --licenses
```

Las licencias del SDK las tiene que aceptar la persona que lo instala.

No hace falta Gradle: el preset usa las plantillas ya compiladas (`gradle_build/use_gradle_build=false`).

## Generar el APK

Desde la raíz del proyecto:

```
godot --headless --path . --export-debug Android build/android/brote.apk
```

Sale firmado con la clave de depuración (`%APPDATA%\Godot\keystores\debug.keystore`). Si no existe, se crea con `keytool` (viene con el JDK):

```
keytool -genkeypair -v -keystore debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
```

Para Google Play hará falta una clave propia de publicación y un AAB; eso queda para la Etapa 6 (pago único).

## Instalarlo en el móvil

- **Con cable:** activar *Opciones de desarrollador* y *Depuración USB* en el móvil y ejecutar `adb install -r build/android/brote.apk`.
- **Sin cable:** pasar el `.apk` al móvil (correo, Drive, mensajería), abrirlo y permitir *instalar apps de origen desconocido* para esa app cuando lo pida.

Para enviarlo a otras personas basta con el mismo archivo `.apk`. Cada versión nueva debe subir `version/code` en `export_presets.cfg` si se quiere instalar encima de la anterior sin desinstalar.

## Qué hace distinto en Android

- **Orientación fija en vertical** (`display/window/handheld/orientation=1` en `project.godot`). En la web y en el escritorio no cambia nada.
- **Botón Atrás:** en la partida cierra los ajustes, quita la pausa, deselecciona o abre la pausa; en el menú cierra los ajustes o sale del juego (`config/quit_on_go_back=false` y `NOTIFICATION_WM_GO_BACK_REQUEST`).
- **Escala de la interfaz:** si Android no informa de la escala de pantalla, `Pantalla.escala_de_pantalla` la deduce de los puntos por pulgada (160 ppp = escala 1).
- **Pantalla completa** (`screen/immersive_mode`).
- La partida se guarda en el almacenamiento privado de la app y se borra al desinstalarla.
