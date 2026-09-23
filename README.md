# Soporte-Admin-TIC
Aplicación para técnicos que presten soporte remoto. 

Este proyecto toma a RustDesk (1.4.9) como base, añadiendo funcionalidades para el preste de servicios de soporte remoto.

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




## Instalación Paso a Paso (Linux) (En Desarrollo)
