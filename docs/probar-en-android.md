# Probar Brote en Android (APK)

Cómo generar un APK de prueba e instalarlo en un móvil Android, sin pasar por Google Play.

## Lo que se instala una sola vez en el PC

| Pieza | Para qué | Dónde se configura |
|---|---|---|
| **JDK 17** (por ejemplo, Eclipse Temurin 17) | Firmar el APK | Godot, Editor > Configuración del editor > Exportar > Android > `java_sdk_path` |
| **Android SDK**: `platform-tools`, `build-tools` y una plataforma (`platforms;android-35`) | `adb` y `apksigner` | `android_sdk_path` (por defecto `%LOCALAPPDATA%\Android\Sdk`) |
| **Plantillas de exportación de Godot 4.7.2** | La base del APK (`android_debug.apk`, `android_release.apk`) | Godot, Editor > Administrar plantillas de exportación |

**En el PC de desarrollo ya está instalado en `D:\Herramientas`:** `jdk-17`, `android-sdk` (platform-tools, build-tools 35.0.1, android-35), la clave de depuración en `claves\debug.keystore` y las plantillas en `godot-plantillas\4.7.2.stable`, enlazadas (unión de directorios) desde `%APPDATA%\Godot\export_templates\4.7.2.stable`. `instalar_sdk.bat` vuelve a instalar los paquetes del SDK. Las rutas están en la configuración del editor de Godot (`editor_settings-4.7.tres`; hay una copia de antes en `D:\Herramientas`).

Android exige además la compresión de texturas ETC2/ASTC: está activada en `project.godot` (`rendering/textures/vram_compression/import_etc2_astc`).

El SDK se puede instalar con Android Studio o solo con las *command-line tools*. Con estas últimas:

```
sdkmanager --sdk_root=%LOCALAPPDATA%\Android\Sdk "platform-tools" "build-tools;35.0.0" "platforms;android-35"
sdkmanager --sdk_root=%LOCALAPPDATA%\Android\Sdk --licenses
```

Las licencias del SDK las tiene que aceptar la persona que lo instala. Las herramientas nuevas de Google (`android sdk`, que sustituye a `sdkmanager`) muestran los términos al instalar y envían estadísticas de uso salvo que se use `--no-metrics`.

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
