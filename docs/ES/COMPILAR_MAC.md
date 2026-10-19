## Compilación Paso a Paso (MacOS)
### MacOS utilizado Ventura 13, Intel

Guía basada en un proceso realizado de compilación en macOS Ventura 13 (Intel), a partir de la **guía oficial** [<img src="/.img/external-link.png" alt="External Link" title="Abrir en una nueva pestaña" width="18" heigth="18">](https://rustdesk.com/docs/en/dev/build/osx/), con los ajustes necesarios para que funcione en este entorno.

> **Nota:** los pasos de la sección [1. Entorno del sistema](#1-entorno-del-sistema-una-sola-vez) se instalan **una sola vez** por máquina. Si vas a compilar un segundo cliente (otro fork/carpeta del mismo repo), puedes saltar directo a la [sección 2](#2-por-cada-proyectocarpeta).

---

### 1. Entorno del sistema (una sola vez)

### 1.1 Xcode Command Line Tools
Para ello, se utiliza:
```bash
xcode-select --install 
```

### 1.2 Homebrew
Para esto puede seguir las instrucciones de la página oficial de **Homebrew** [<img src="/.img/external-link.png" alt="External Link" title="Abrir en una nueva pestaña" width="18" heigth="18">](https://brew.sh/)
<br> O directamente con esta instrucción, obtenida de esta misma:
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
git clone https://github.com/rustdesk/rustdesk.git /c/rustdesk
cd /c/rustdesk
git checkout 91c9fccbb0f7bfe5f11644d5fbdec9b23fa10540
git submodule update --init --recursive
cd libs/hbb_common
git checkout 29cf7cbe4d38ce36020749f713fb066299f02431
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
Esto para evitar instalar paquetes en el sistema o globalmente, evitando problemas de sistema.
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

### 2.8 Compilar
```sh
python3 ./build.py --flutter
```
Puede tardar 15–40 min. Es normal ver muchos `warning:` (nullability de headers de Swift/Xcode, "Run script build phase" sin outputs) — no son errores, no bloquean el build.

### 2.9 Firmar (ad-hoc)
Sin esto, macOS bloquea la app al abrir con `Library Validation failed: ... has no Team ID`:
```sh
codesign --force --deep --sign - "flutter/build/macos/Build/Products/Release/<NombreApp>.app"
```

### 2.10 Ejecutar
```sh
open "flutter/build/macos/Build/Products/Release/<NombreApp>.app"
```
o con doble click en la aplicación.

---

#### Notas finales

- Si algo falla de forma rara tras cambios de código, antes de investigar a fondo prueba una limpieza:
  ```sh
  # Flutter
  cd flutter && fvm flutter clean && fvm flutter pub get && cd macos && pod install && cd ../..
  # Rust (más lento, recompila todo)
  cargo clean
  ```
