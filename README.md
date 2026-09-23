Still accomodating details, this is *not* the final README
# Índice
1.[Información](https://github.com/bryanmoraga-ticonsultores/Soporte-Admin-TIC#Informacion)<br>
2.[Compilar Rustdesk (Sin Modificar) en Windows](https://github.com/bryanmoraga-ticonsultores/Soporte-Admin-TIC#Instalación-Paso-a-Paso-Windows)<br>

# Información
## Soporte-Admin-TIC
Aplicación para técnicos que presten soporte remoto. 

Este proyecto toma a [`RustDesk`](https://github.com/rustdesk/rustdesk) (1.4.9) como base, añadiendo funcionalidades para el preste de servicios de soporte remoto. <br>Específicamente:<br>

- RustDesk: commit <`91c9fccbb0f7bfe5f11644d5fbdec9b23fa10540`> <br>
```bash
91c9fccbb (HEAD -> master, origin/master, origin/HEAD) chore(deps): security bumps in Cargo.lock (RUSTSEC-2026 fixes) (#16143)
nightly-177-g91c9fccbb
```
- hbb_common: commit <`29cf7cbe4d38ce36020749f713fb066299f02431`> <br>
```bash
libs/hbb_common (driver-390-g29cf7cb)
```

Para esto se necesitaría seguir las instrucciones del propio repositorio de rustdesk, que mencionaré aquí en caso de que cambien, para compilar la aplicación usando Flutter (No Sciter):

Para efectos prácticos se utilizará la herramienta [`Git Bash`](https://git-scm.com/install/windows) para el cliente de Windows.

Las herramientas base para compilar el programa, obviando la anterior mencionada, serán:

----
Herramienta | Versión | Notas
----|----|----|
Visual Studio Community | 2022 (v. 17), workload "Desarrollo para escritorio con C++" | Necesario para MSVC |
Rust(`rustup-innit.exe`) | toolchain `1.75` | El CI de RustDesk fija esta versión para la app |
LLVM | `15.0.6` | Para `bindgen`/`rust-bindgen` |
Flutter SDK | `3.24.5`(canal stable) | **NO** usar `master`/`beta`, RustDesk depende de una verión exacta |
Python 3 | cualquier reciente | Para ejecutar `build.py` |
vcpkg | commit fijo | Maneja las librerías nativas (libvpx, opus, ffmpeg, etc.)
----

Más abajo estarán seccionados los pasos a realizar para Windows y Mac (Linux en proceso)

## Instalación Paso a Paso (Windows)

### Preparación

Primero, habilitar rutas largas en Powershell como administrador, para prevenir problemas con el nombre de algunas carpetas.

```ps1
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" \
  -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
```
> Esto permite rutas de archivos superiores a 260 caracteres, que es el límite tradicional.

### Paso 1 - Visual Studio Community
----

Ahora si, como paso inicial, instalar Visual Studio 2022. <br> Tiene su truco encontrar versiones antiguas, pero aquí dejaré el enlace de `aka.ms`, dominio que utiliza microsoft.

> [!Caution]
> Descargo de responsabilidad: <br>
> El enlace es provisto del repositorio oficial de microsoft, no alojo ni reclamo autoría del programa/software. <br>
> No es mi responsabilidad el caso de que el enlace cese su funcionalidad.

https://aka.ms/vs/17/release/vs_community.exe

Durante la instalación, selecciona el workload **"Desarrollo para el escritorio con C++"**, en la sección **Móviles y de Escritorio**.

![](/.img/vscomm_1.png)

Luego, en la sección de la derecha, los únicos que son realmente necesarios son:
- `Herramientas de compilación de C++ de MSVC...`
- `Herramientas de CMake en C++ para Windows`
- `SDK de Windows 11` (o el equivalente para windows 10)


![](/.img/vscomm_2.png)

> **NO** marcar el administrador de paquetes vcpkg integrado.

### Paso 2 - Rust
----

Luego, instalar [Rust](https://rust-lang.org/es/tools/install/) compatible con tu arquitectura de sistema. Puedes revisar esto último desde el propio Git Bash:

```bash
echo $PROCESSOR_ARCHITECTURE
```
Los valores son:
- `AMD64` &rarr; arquitectura **x64**
- `x86` &rarr; arquitectura **32 BITS**
- `ARM64` &rarr; arquitectura **ARM64**

Ejecuta el archivo descargado (`rustup-innit.exe`), y prosigue con la instalación de Rust por defecto (presionando *Enter* cuando te lo pida).

![](/.img/rustup_1.png)

Cuando se complete, en Git Bash se debe hacer esto:

```bash
source ~/.bashrc # O también `exec bash`. Esto recarga la terminal si no has cerrado la anterior
rustup install 1.75
rustup default 1.75
```

### Paso 3 - LLVM
----

Ahora hay que descargar LLVM 15.0.6. Puede ser encontrado en su [Github](https://github.com/llvm/llvm-project/releases/tag/llvmorg-15.0.6), en la sección de `Assets`, el archivo del mismo nombre correspondiente a la arquitectura de la computadora.

Luego ejecute el instalador, y siga con la instalación. 

> [!Caution]
> Cuando aparezca la opción, seleccionar "Añadir LLVM al PATH del sistema para todos los usuarios". <br>
> De esta manera, la consola podrá identificar el programa automáticamente. De otra forma habría que añadirlo al PATH de forma manual. <br>
> Siendo ese el caso: En el buscador de Windows; Editar las varables de entorno del sistema &rarr; Variables de Entorno &rarr; Variables del Sistema &rarr; Nueva... &rarr; <br> Nombre: LIBCLANG_PATH <br> Valor: <ruta_llvm>/bin <br>
> &rarr; Aceptar &rarr; Aceptar &rarr; Aplicar &rarr; Aceptar <br>
> Por defecto, la ruta de LLVM es 'C:/Program Files/LLVM/bin'

### Paso 4 - Flutter SDK
----

Ahora, el turno del SDK de Flutter

Para efectos prácticos, el SDK de Flutter quedará en `C:/src`

```bash
git clone https://github.com/flutter/flutter.git -b 3.24.5 C:/src/flutter
```

Ahora, esto se debe agregar al PATH:

>Editar las varables de entorno del sistema &darr;<br> Variables de Entorno &darr;<br> Variables del Sistema &darr;<br> Path &darr;<br> Editar... &darr;<br> Nuevo &darr;<br> Escribir (o pegar) `C:\src\flutter\bin` &darr;<br> Aceptar &darr;<br> Aceptar &darr;<br> Aplicar &darr;<br> Aceptar <br>

Cuando finalice, recargue la terminal de Git Bash (`source ~/.bashrc` o `exec bash`) para que el terminal "lea" el PATH nuevamente. Luego:

```bash
flutter doctor -v
flutter config --enable-windows-desktop
```

### Paso 5 - Python
----

Ahora, Python:<br> El repositorio oficial es https://www.python.org/downloads/windows/ <br>
Lo ideal es que sea una versión estable, y para esta guía se utilizó la versión `3.11.9` <br>
En el propio instalador, marque la opción de añadir al PATH del sistema.

<img src="https://static.allthings.how/content/images/2025/08/image-1389-1.png" width=900>

> Fuente de la imagen: [All Things How](https://allthings.how/add-python-to-path-on-windows-11/)

Cuando finalice, seguimos con `vcpkg`.

### Paso 6 - VCPKG
----
Para instalar vcpkg, y los componentes necesarios, ingrese en el terminal:

```bash 
git clone https://github.com/microsoft/vcpkg C:/vcpkg
cd /c/vcpkg
git checkout 120deac3062162151622ca4860575a33844ba10b
./bootstrap-vcpkg.bat
```
>Esto descargará e instalará la versión específica requerida por RustDesk

Y agregar a las variables del sistema
> Editar las varables de entorno del sistema &darr;<br> Variables de Entorno &darr;<br> Variables del Sistema &darr;<br> Nueva... &darr;<br> Nombre: VCPKG_ROOT <br> Valor: C:/vcpkg
> &darr;<br> Aceptar &darr;<br> Aceptar &darr;<br> Aplicar &darr;<br> Aceptar <br>

Luego, de vuelta a la terminal:

```bash
export VCPKG_DEFAULT_HOST_TRIPLET=x64-windows-static
export VCPKG_VISUAL_STUDIO_PATH="C:/Program Files/Microsoft Visual Studio/2022/Community"

/c/vcpkg/vcpkg install \
  libvpx:x64-windows-static \
  libyuv:x64-windows-static \
  opus:x64-windows-static \
  aom:x64-windows-static \
  --triplet x64-windows-static
```
> Esto tarará de unos 20 a 40 minutos, dependiendo del sistema, la primera vez.

### Paso 7 - RustDesk
----

Ahora ya tenemos lo necesario, por lo que clonaremos RustDesk:
```bash
git clone --recurse-submodules https://github.com/rustdesk/rustdesk /c/rustdesk
cd /c/rustdesk
git checkout 1.4.9
```

**Sólo para este paso** utilizaremos Rust en su versión estable, y no una predefinida, ya que es posible que la versión que definimos anteriormente puede fallar al descargar esta librería:
```bash
rustup install stable
rustup run stable cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid
# Lo devolvemos a la versión requerida
rustup default 1.75 
```

Ahora, generamos el *bridge*, o puente, entre Flutter y Rust:
```bash
cd /c/rustdesk/flutter
export PATH="$PATH:/c/src/flutter/bin"
flutter pub get

~/.cargo/bin/flutter_rust_bridge_codegen \
  --rust-input ../src/flutter_ffi.rs \
  --dart-output ./lib/generated_bridge.dart \
  --llvm-path "C:/Program Files/LLVM/bin"
cd ..
```

Cuando termine, obtenemos el motor Flutter personalizado de RustDesk:

```bash
cd /c/rustdesk
flutter precache --windows

curl -L -o windows-x64-release.zip \
  https://github.com/rustdesk/engine/releases/download/main/windows-x64-release.zip

unzip windows-x64-release.zip -d windows-x64-release

cp -rf windows-x64-release/* \
  "/c/src/flutter/bin/cache/artifacts/engine/windows-x64-release/"
``` 

Y ya para compilar:
```bash
cd /c/rustdesk
export VCPKG_ROOT=/c/vcpkg
export PATH="$PATH:/c/src/flutter/bin"

# Build debug (para desarrollo)
cargo build --features flutter --lib
cd flutter && flutter run -d windows

# Build release (para ditribución/producción):
cd /c/rustdesk
python build.py --flutter
```

#### Notas importantes
---
- Cierra y reabre Git Bash después de cambiar variables de entorno del sistema, o recarga el terminal (`source ~/.bashrc` o `exec bash`)
- `VCPKG_ROOT` debe estar visible antes de compilar — si no, el build falla con error de `magnum-opus`
- `flutter` debe estar en el PATH — si no, el build falla al intentar `flutter build windows`
- Las librerías de vcpkg se reutilizan entre builds — no necesitas repetir el paso 4
- Si cambias `.rs` → recompila con `cargo build --features flutter --lib`
- Si cambias `.dart` o assets → solo presiona `r` en `flutter run` o corre `build.py` de nuevo


## Instalación Paso a Paso (Mac)
### MacOS utilizado Ventura 13, Intel

Guía basada en un proceso real de compilación en macOS Ventura 13 (Intel), a partir de la [guía oficial](https://rustdesk.com/docs/en/dev/build/osx/), con los ajustes necesarios para que funcione en este entorno.

> **Nota:** los pasos de la sección [1. Entorno del sistema](#1-entorno-del-sistema-una-sola-vez) se instalan **una sola vez** por máquina. Si vas a compilar un segundo cliente (otro fork/carpeta del mismo repo), puedes saltar directo a la [sección 2](#2-por-cada-proyectocarpeta).

---

### 1. Entorno del sistema (una sola vez)

### 1.1 Xcode Command Line Tools
```sh
xcode-select --install
```

### 1.2 Homebrew
```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
En Mac Intel, Homebrew queda en `/usr/local` y normalmente ya entra al PATH solo. En Apple Silicon habría que agregar `/opt/homebrew/bin` al PATH manualmente.

### 1.3 Xcode completo (no solo las Command Line Tools)
En Ventura 13, el App Store solo ofrece la última versión de Xcode (que pide una versión de macOS más nueva). Hay que bajar una versión compatible (15.0–15.2) desde el portal de Apple Developer:

1. Crea/usa una cuenta Apple Developer **gratuita** en https://developer.apple.com/account
2. Descarga Xcode 15.2 desde https://developer.apple.com/download/all/
3. Extrae el `.xip` (tarda varios minutos) y mueve `Xcode.app` a `/Applications`
4. Actívalo:
```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

> No es necesario descargar los runtimes de Simulator de iOS (~7GB) si solo vas a compilar la app de macOS.

### 1.4 Herramientas base vía Homebrew
```sh
brew install python3 create-dmg nasm cmake gcc wget ninja pkg-config rustup
```

Si `rustup` falla al compilar por un error de red tipo `HTTP2 framing layer` al bajar `terminal_size` desde crates.io, instala Rust directo con el instalador oficial en su lugar:
```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

Si Homebrew sí logra instalar `rustup`, queda *keg-only* (no symlinkeado por defecto). Agrégalo al PATH:
```sh
echo 'export PATH="/usr/local/opt/rustup/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 1.5 Rust
```sh
rustup install stable
rustup default 1.75.0
rustup component add rustfmt
```

Agrega también el cargo bin al PATH (necesario si `rustup` vino de Homebrew):
```sh
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 1.6 vcpkg
> ⚠️ **No uses el tag `2023.04.15`** que sugiere la guía oficial — su versión de `aom` es incompatible con el `nasm` moderno que instala Homebrew (error: `Unsupported nasm: multipass optimization not supported`). Usa la rama `master`:

```sh
git clone https://github.com/microsoft/vcpkg ~/Desktop/vcpkg
cd ~/Desktop/vcpkg
./bootstrap-vcpkg.sh -disableMetrics
./vcpkg install libvpx libyuv opus aom
```

Agrega `VCPKG_ROOT` de forma **permanente** (su ausencia rompe la compilación de `magnum-opus` con `Couldn't find VCPKG_ROOT`):
```sh
echo 'export VCPKG_ROOT=$HOME/Desktop/vcpkg' >> ~/.zshrc
source ~/.zshrc
```

### 1.7 FVM (Flutter Version Management)
No lo instales vía Homebrew — la fórmula `dart-sdk` moderna requiere macOS 14+ y falla en Ventura 13. Usa el instalador oficial:
```sh
curl -fsSL https://fvm.app/install.sh | bash
echo 'export PATH="$HOME/fvm/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 1.8 CocoaPods (con Ruby de Homebrew)
El Ruby del sistema en macOS suele tener certificados SSL desactualizados, causando `certificate verify failed` al conectar a `cdn.cocoapods.org`.

```sh
brew install ruby
echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

brew install openssl ca-certificates
echo 'export SSL_CERT_FILE=$(brew --prefix ca-certificates)/share/ca-certificates/cacert.pem' >> ~/.zshrc
source ~/.zshrc

gem install cocoapods
```

---

## 2. Por cada proyecto/carpeta

Repite esta sección por cada clon del repo (por ejemplo, si compilas varios builds personalizados desde carpetas distintas en el mismo Mac).

### 2.1 Clonar el repo
```sh
cd ~/Desktop
git clone --recurse-submodules https://github.com/rustdesk/rustdesk <nombre-carpeta>
cd <nombre-carpeta>
```

### 2.2 Fijar la versión de Flutter con FVM
> ⚠️ La versión importa: **≥3.19.0** por la dependencia `xterm`, **≥3.5.0 de Dart** (viene con Flutter ≥3.24) por `extended_text`, pero **<3.47** porque el Dart SDK de versiones más nuevas ya no corre en macOS 13. La que funcionó fue **3.24.5**.

```sh
cd flutter
fvm install 3.24.5
fvm use 3.24.5
fvm global 3.24.5
fvm flutter --version   # debe mostrar 3.24.5 / Dart 3.5.4
```

### 2.3 Dependencias de Flutter
```sh
fvm flutter pub get
fvm flutter precache --macos
```

### 2.4 Venv para el paquete Python (portable)
```sh
cd ../libs/portable
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
cd ../..
```

### 2.5 Instalar el puente Rust↔Flutter
```sh
cargo +stable install flutter_rust_bridge_codegen --version "1.80.1" --features "uuid"
```
> Se usa `+stable` porque el toolchain 1.75.0 (el que usa el resto del build) no soporta la feature `edition2024` que requiere una dependencia transitiva de este paquete.

### 2.6 Generar el bridge
```sh
flutter_rust_bridge_codegen \
  --rust-input ./src/flutter_ffi.rs \
  --dart-output ./flutter/lib/generated_bridge.dart \
  --c-output ./flutter/macos/Runner/bridge_generated.h \
  --class-name Rustdesk
```
> ⚠️ **Siempre pasa `--class-name Rustdesk` explícitamente.** Sin este flag, el nombre de clase por defecto puede derivarse de metadatos del proyecto (pubspec, Cargo.toml, etc.) y generar algo distinto a `RustdeskImpl` — que es lo que el código Dart (`native_model.dart`, `platform_model.dart`) espera literalmente. Si no coincide, verás una cascada larga de errores de tipos que no tiene relación aparente con el problema real.

### 2.7 Pods de macOS
```sh
cd flutter/macos
pod install
cd ../..
```

### 2.8 (Opcional) Personalizar nombre y bundle ID
Antes de compilar, si quieres que la app tenga su propio nombre/identidad (útil si vas a tener varios builds instalados a la vez en el mismo Mac):

**`flutter/macos/Runner/Configs/AppInfo.xcconfig`**
```
PRODUCT_NAME = <TuNombreDeApp>
PRODUCT_BUNDLE_IDENTIFIER = <tu.identificador.unico>
```

**`flutter/macos/Runner.xcodeproj/project.pbxproj`** — hay 3 ocurrencias hardcodeadas que sobreescriben al `.xcconfig` si no se cambian:
```sh
sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = com.carriez.rustdesk;/PRODUCT_BUNDLE_IDENTIFIER = <tu.nuevo.identificador>;/g' flutter/macos/Runner.xcodeproj/project.pbxproj
```

**`libs/hbb_common/src/config.rs`** (opcional, para que los textos de la UI usen tu nombre en vez de "RustDesk"):
```rust
pub static ref APP_NAME: RwLock<String> = RwLock::new("<TuNombreDeApp>".to_owned());
```

### 2.9 Compilar
```sh
python3 ./build.py --flutter
```
Puede tardar 15–40 min. Es normal ver muchos `warning:` (nullability de headers de Swift/Xcode, "Run script build phase" sin outputs) — no son errores, no bloquean el build.

Si compilaste con un nombre de app personalizado (paso 2.8), asegúrate de que tu `build.py` resuelva el nombre real del `.app` en vez de asumir `RustDesk.app` — por ejemplo, leyendo `PRODUCT_NAME` desde `AppInfo.xcconfig`.

### 2.10 Firmar (ad-hoc)
Sin esto, macOS bloquea la app al abrir con `Library Validation failed: ... has no Team ID`:
```sh
codesign --force --deep --sign - "flutter/build/macos/Build/Products/Release/<NombreApp>.app"
```

### 2.11 Ejecutar
```sh
open "flutter/build/macos/Build/Products/Release/<NombreApp>.app"
```

---

#### Notas finales

- **Cada carpeta/clon genera su propio ID de RustDesk** de forma automática, siempre que tenga su propio `PRODUCT_BUNDLE_IDENTIFIER` — no hay conflicto por compilar y correr varios builds en el mismo Mac apuntando al mismo servidor de relay.
- Para compilar un **segundo cliente** reutilizando el mismo entorno, repite solo la sección 2 en una carpeta nueva — no hace falta reinstalar Homebrew, Xcode, vcpkg, Rust, FVM ni CocoaPods.
- Si algo falla de forma rara tras cambios de código, antes de investigar a fondo prueba una limpieza:
  ```sh
  # Flutter
  cd flutter && fvm flutter clean && fvm flutter pub get && cd macos && pod install && cd ../..
  # Rust (más lento, recompila todo)
  cargo clean
  ```

## Instalación Paso a Paso (Linux) (En Desarrollo)
