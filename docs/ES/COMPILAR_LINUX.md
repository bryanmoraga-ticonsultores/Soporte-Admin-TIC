# Compilar RustDesk 1.4.9 (Flutter) en Omarchy / Arch Linux
 
Guía para compilar el cliente de RustDesk **sin personalizaciones** (nombre, ID y paquete originales) en Omarchy o cualquier Arch rolling, con los arreglos que fueron necesarios en la práctica.
 
> **Entorno donde se probó:** Omarchy (Arch), GCC 16.2.1, clang/llvm 23.1.3, Flutter 3.24.5 (Dart 3.5.4), `flutter_rust_bridge_codegen` 1.80.1, Rust stable (rustup), tag `1.4.9`, dependencias C en vcpkg.
>
> Al ser una distribución rolling, estas versiones cambiarán. Algunos arreglos de abajo pueden dejar de hacer falta, y pueden aparecer otros. Los pasos marcados con *(guía oficial)* salen de la documentación de RustDesk y no de los logs de esta compilación.
 
---

## 0. Resumen de lo que hay que saber antes
 
Son cuatro cosas que no están en la guía oficial y que rompieron la compilación en un Arch actual:
 
1. **Headers de clang para el codegen:** pasarlos con `--llvm-compiler-opts`, **nunca** con `CPATH` (rompe `openssl` y `ring`, ver sección 7).
2. **`CXXFLAGS="-include cstdint"`:** `webm-sys` no compila con GCC reciente sin él.
3. **`bindgen` 0.73 en `libs/scrap`:** con libclang 23, las versiones antiguas generan structs vacíos y fallan 64 errores. Es el único cambio al código fuente que hace falta.
---
## 1. Dependencias del sistema
 
```bash
sudo pacman -S --needed base-devel git cmake ninja nasm yasm pkgconf unzip zip curl \
  clang llvm gtk3 libxcb libxfixes alsa-lib libva pipewire xdotool pam \
  gst-plugins-base gst-plugins-good gst-plugin-pipewire libayatana-appindicator
```
 
(Lista alineada con el `depends` del `res/PKGBUILD` y la guía oficial; ajusta si `makepkg` pide algo más.)
 
## 2. Rust, Flutter y vcpkg
 
**Rust**
 
```bash
rustup default stable
```
 
**Flutter 3.24.5** (versión usada por RustDesk 1.4.x): instálalo en una carpeta propia y añade `flutter/bin` al `PATH`.
 
```bash
flutter --version   # debe indicar 3.24.5
```
 
**vcpkg** *(guía oficial)*: instálalo, exporta `VCPKG_ROOT` y compila las librerías de vídeo y audio. Ajusta la ruta a la tuya:
 
```bash
export VCPKG_ROOT=$HOME/develop/vcpkg      # ponlo en ~/.bashrc o ~/.zshrc
cd <carpeta-del-proyecto>
$VCPKG_ROOT/vcpkg install --x-install-root="$VCPKG_ROOT/installed"
```
 
Debe quedar `$VCPKG_ROOT/installed/x64-linux/lib` con `libvpx`, `libaom`, `libyuv` y `libopus`. `libs/scrap/build.rs` las busca ahí.
 
**flutter_rust_bridge_codegen 1.80.1** *(guía oficial)*:
 
```bash
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features "uuid"
cd flutter && flutter pub get && cd ..
```
 
---

## 3. Obtener el código
 
Clona **con submódulos**:
 
```bash
git clone --recurse-submodules https://github.com/rustdesk/rustdesk
cd rustdesk
git checkout 1.4.9
git submodule update --init --recursive    # repetir SIEMPRE tras cambiar de tag
ls libs/hbb_common/Cargo.toml              # debe existir
```
 
---
 
## 4. Ajuste único en el código fuente: bindgen
 
En `libs/scrap/Cargo.toml`, sube `bindgen` de 0.65 a 0.73:
 
```toml
[build-dependencies]
bindgen = "0.73"
```
 
Regenera el lockfile **una sola vez** (el build usa `--locked`, que no lo permite):
 
```bash
cargo update -p scrap
git diff --stat Cargo.lock     # solo deben cambiar bindgen/scrap y sus dependencias nuevas
```
 
Guarda `Cargo.lock` y `Cargo.toml` modificados en tu rama; si los revierte, el próximo build vuelve a fallar.
 
---
 
## 5. Variables de entorno
 
```bash
export VCPKG_ROOT=$HOME/develop/vcpkg
export CXXFLAGS="-include cstdint"
```
 
Y **comprueba que NO estén definidas** estas otras (si lo están, quítalas; ver sección 7):
 
```bash
env | grep -E "CPATH|C_INCLUDE_PATH|CPLUS_INCLUDE_PATH|BINDGEN_EXTRA_CLANG_ARGS"
unset CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH BINDGEN_EXTRA_CLANG_ARGS
```
 
---

## 6. Compilar
 
### 6.1 Generar el bridge Flutter ⇄ Rust
 
Averigua la versión de clang y usa **esa** en el flag:
 
```bash
ls /usr/lib/clang/                          # p. ej. 23
ls /usr/lib/clang/23/include/stdbool.h      # debe existir
 
~/.cargo/bin/flutter_rust_bridge_codegen \
  --rust-input ./src/flutter_ffi.rs \
  --dart-output ./flutter/lib/generated_bridge.dart \
  --llvm-compiler-opts="-I/usr/lib/clang/23/include"
```
 
Los avisos `Skipping unresolvable module ipc_auth / ipc_fs / inline / io` son inofensivos. Debe terminar con `Success!`.
 
### 6.2 Corregir el PKGBUILD
 
En `res/PKGBUILD`, si `depends` incluye `libappindicator-gtk3` (ya no existe en los repos), sustitúyelo:
 
```bash
sed -i 's/libappindicator-gtk3/libayatana-appindicator/' res/PKGBUILD
grep -n depends res/PKGBUILD
```
 
### 6.3 Compilar y empaquetar
 
```bash
./build.py --flutter 2>&1 | tee /tmp/build.log | tail -30
```
 
El log completo es enorme; para localizar el primer error real:
 
```bash
grep -n -E "^error|fatal error" /tmp/build.log | head -20
```
 
Éxito = la última línea relevante dice `==> Finished making: rustdesk 1.4.9-0`. Los mensajes `gdb-add-index: No debugging symbols` son inofensivos (se pueden silenciar con `options=(!strip !debug)` en el `PKGBUILD`).
 
El binario sin empaquetar queda en `flutter/build/linux/x64/release/bundle/rustdesk` y se puede probar directamente.
 
---
 
## 7. Solución de problemas
 
| Síntoma | Causa | Solución |
|---|---|---|
| `fatal error: 'stdbool.h' file not found` (ffigen) | libclang no encuentra sus headers internos | Instalar `clang` y pasar `--llvm-compiler-opts="-I/usr/lib/clang/<ver>/include"` |
| `failed to load manifest ... libs/hbb_common/Cargo.toml` | Falta el submódulo | `git submodule update --init --recursive` |
| `'uint32_t' does not name a type` en `webm-sys` / `mkvparser.cc` | GCC reciente ya no incluye `<cstdint>` implícitamente | `export CXXFLAGS="-include cstdint"` |
| ~64 errores `no field g_w ... available field is _address` en `scrap` (vpx/aom) | `bindgen` antiguo genera structs opacos con libclang 23 | Sección 4 (bindgen 0.73) y `cargo clean` |
| `openssl-sys` / `ring` fallan con `missing binary operator before token '('` y rutas `/usr/lib/clang/.../__stddef_size_t.h` | GCC está leyendo headers de clang por `CPATH` o similar | Sección 5: `unset CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH`; luego `cargo clean` |
| `Missing dependencies: libappindicator-gtk3` en `makepkg` | Paquete obsoleto en el `PKGBUILD` | Sección 6.2 |
 
**Regla general:** tras cambiar una variable de entorno que afecta a un `build.rs`, Cargo no recompila solo. Limpia cargo (`cargo clean`) antes de recompilar.
 
**Comprobar que bindgen generó bien los structs de `scrap`:**
 
```bash
grep -l "g_threads" target/release/build/scrap-*/out/vpx_ffi.rs
```
 
Si imprime una ruta, el struct tiene campos. Si no imprime nada, sigue vacío.
 
---

## 8. Instalar
 
En `res/` pueden quedar paquetes de compilaciones anteriores; elige el más reciente que **no** sea `-debug`:
 
```bash
cd res
command ls -lt *.pkg.tar.zst | head      # 'command' evita alias como eza
sudo pacman -U rustdesk-1.4.9-0-x86_64.pkg.tar.zst
```
 
Este paquete se llama `rustdesk`, igual que el oficial: **sustituye** a un RustDesk ya instalado desde pacman.
 
---

## 9. Anexo: convivir con otro RustDesk instalado

Si necesitas tener a la vez un RustDesk distinto instalado, no basta con cambiar `BINARY_NAME`, `APPLICATION_ID` y `APP_NAME`. Hay que renombrar también el paquete y todo lo que instala. Este procedimiento se probó en Arch/Omarchy con el nombre `soporte-remoto-admin`: compila, empaqueta, instala y el servicio funciona. Los puntos pendientes de verificar están marcados.

### 9.1 Nombres base

Elige un nombre en minúsculas y con guiones (aquí `soporte-remoto-admin`) y úsalo de forma idéntica en todo lo siguiente:

| Dónde | Qué cambiar |
|---|---|
| `libs/hbb_common/src/config.rs` | `APP_NAME` (ej. `"Soporte-Remoto-Admin"`) |
| `flutter/linux/CMakeLists.txt` | `BINARY_NAME` y `APPLICATION_ID` |
| `res/PKGBUILD` | `pkgname` y todas las rutas `/usr/share/<nombre>`, `/usr/bin/<nombre>`, iconos |
| `res/` | Renombrar los tres archivos y actualizar su contenido (ver 9.2) |
| `res/pacman_install` | Nombre del servicio y de los `.desktop` |
| `build.py` | El `mv` final de la rama de pacman (ver 9.3) |

**Importante:** el código Rust deriva el nombre del servicio de systemd con `get_app_name().to_lowercase()` (en `install_service`, `uninstall_service` y `check_if_stop_service`). Por eso el servicio debe llamarse exactamente igual que `APP_NAME` en minúsculas.

### 9.2 Archivos de `res/`

```bash
cd res
mv rustdesk.service      soporte-remoto-admin.service
mv rustdesk.desktop      soporte-remoto-admin.desktop
mv rustdesk-link.desktop soporte-remoto-admin-link.desktop
```

Dentro de cada archivo hay que cambiar:

- `.service`: `Description`, `ExecStart`, `ExecStop` (`pkill -f "<nombre> --"`) y `PIDFile`.
- `.desktop`: `Name`, `Exec`, `Icon`, `StartupWMClass`.
- `-link.desktop`: además `TryExec` y `MimeType` (`x-scheme-handler/<nombre>;`). *Pendiente de verificar:* no se comprobó que el esquema de URL derive de `APP_NAME`.

Atajo para reemplazar el nombre en todos los archivos (ejecutar después de los `mv`, y revisar con `grep -rn "rustdesk" .`):

```bash
sed -i 's/rustdesk/soporte-remoto-admin/g' PKGBUILD pacman_install *.service *.desktop
```

Cuidado: este `sed` reemplaza **todas** las apariciones de `rustdesk`. Si tu `PKGBUILD` referencia algo que deba conservar ese nombre, revísalo después.

### 9.3 `build.py`

Al final de la rama de pacman, el script renombra el paquete generado con el prefijo `rustdesk`. Si no se actualiza, falla con `mv: cannot stat 'rustdesk-...pkg.tar.zst'` **aunque el paquete ya se haya generado correctamente**.

```py
system2('mv soporte-remoto-admin-%s-0-x86_64.pkg.tar.zst soporte-remoto-admin-%s-manjaro-arch.pkg.tar.zst' % (
    version, version))
```

Alternativa que no depende del nombre (requiere `import glob`):

```py
for pkg in glob.glob('*-%s-0-x86_64.pkg.tar.zst' % version):
    os.rename(pkg, pkg.replace('-0-x86_64', '-manjaro-arch'))
```

### 9.4 Qué NO renombrar

- `librustdesk.so` y el crate `librustdesk`: el código Dart carga la librería con ese nombre.
- `name: flutter_hbb` en `pubspec.yaml`.

### 9.5 Cadenas en el código fuente

Revisar referencias literales a `rustdesk` en `src/platform/linux.rs`, `src/platform/gtk_sudo.rs` y `src/core_main.rs`:

```bash
grep -rniE '"[^"]*rustdesk[^"]*"' src/platform/linux.rs src/platform/gtk_sudo.rs src/core_main.rs
```

Si aparece un `pkill -f "rustdesk --"` o una ruta literal, reemplazarla por `get_app_name().to_lowercase()`. En el fork probado, los comandos `systemctl` ya usaban ese valor y las demás apariciones eran comentarios. Se pueden ignorar `daemon.plist` (macOS) y la ruta `libsciter-gtk.so` de `ui.rs` (solo interfaz Sciter, no se usa con `FLUTTER=1`).

### 9.6 Comprobar choques antes de instalar

```bash
comm -12 <(pacman -Qpl <nuevo>.pkg.tar.zst | awk '{print $2}' | sort) \
         <(pacman -Ql rustdesk | awk '{print $2}' | sort)
```

No debe devolver nada.

### 9.7 Instalación y servicio

```bash
sudo pacman -U soporte-remoto-admin-1.4.9-0-x86_64.pkg.tar.zst
systemctl status soporte-remoto-admin
```

**Problema encontrado:** tras instalar, el binario existía (`which soporte-remoto-admin`) pero `systemctl status` respondía `Unit ... could not be found`: el `post_install` de `pacman_install` no dejó el servicio en `/etc/systemd/system/`. No se llegó a determinar la causa (ver 9.8). Solución manual, que funcionó sin problemas:

```bash
sudo cp /usr/share/soporte-remoto-admin/files/soporte-remoto-admin.service /etc/systemd/system/
sudo cp /usr/share/soporte-remoto-admin/files/soporte-remoto-admin.desktop /usr/share/applications/
sudo cp /usr/share/soporte-remoto-admin/files/soporte-remoto-admin-link.desktop /usr/share/applications/
sudo systemctl daemon-reload
sudo systemctl enable --now soporte-remoto-admin
sudo update-desktop-database
```

### 9.8 Pendiente de verificar

- **Causa del fallo de `post_install`.** Para diagnosticarlo, ver el script que realmente se empaquetó: `bsdtar -xOf <paquete>.pkg.tar.zst .INSTALL`. Revisar si quedaron nombres viejos (`rustdesk`), si el archivo está vacío o si `pacman_install` no se encontró junto al `PKGBUILD`.
- **`StartupWMClass`.** Debe coincidir con el `app_id` real de la ventana. En Hyprland/Omarchy: `hyprctl clients | grep -i class`.
- **Esquema `x-scheme-handler/...`** del `-link.desktop` (ver 9.2).
