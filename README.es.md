# SP Football Life 2026 (PES 2021) en Linux

**Juega PES 2021 con el parche SP Football Life 2026 en Linux.** Un solo script, sin sudo, mando funcionando, las dos actualizaciones aplicadas.

**Léelo en otros idiomas:** [English](README.md) · [Português do Brasil](README.pt-BR.md)

Probado en sistemas basados en Ubuntu y hecho para funcionar también en **Bazzite, SteamOS y Steam Deck**, donde no puedes instalar nada a nivel de sistema.

Conseguí que SP Football Life 2026 corriera en Linux y se juega genial, así que apunté todo lo que hice.

Si conoces este juego como PES 2021, eFootball PES 2021 Season Update, o simplemente Football Life, estás en el lugar correcto. SP Football Life es la versión independiente de SmokePatch construida sobre PES 2021, y esta guía cubre cómo ejecutarlo en Linux con Proton.

PES 2021 ya no se vende. La única razón por la que este juego sigue vivo es el equipo de SmokePatch, que sigue publicando plantillas, equipaciones y estadios actualizados cada temporada. Todo el crédito por el juego y los parches es suyo. Este repositorio es solo la parte de Linux.

Si juegas en Windows no necesitas nada de esto. Descarga el juego de la página oficial e instálalo. Esto es para quien está en Linux y quiere jugar sin pelearse con Wine una tarde entera.

## ¿De verdad funciona?

Sí. 1080p completo, mando funcionando, Sider cargando todos los mods, las dos actualizaciones aplicadas y el juego reportando la versión 2.2.0. Jugué un partido completo antes de escribir esto.

![Menú principal](screenshots/main-menu.png)

Esta es la máquina en la que probé:

| | |
|---|---|
| Sistema | Zorin OS 18.1 (base Ubuntu 24.04) |
| Kernel | 7.0.0-28-generic |
| Escritorio | GNOME en X11 |
| CPU | AMD Ryzen 9 3900X, 24 hilos |
| RAM | 62 GB |
| GPU | NVIDIA RTX 4070 Ti, driver 580.173.02 |
| Vulkan | 1.4.312 |
| Proton | GE-Proton11-3 |
| Mando | Xbox por USB |

### Informes de la comunidad

| | |
|---|---|
| Sistema | Ubuntu 26.04.1 LTS |
| Kernel | 7.0.0-38-generic |
| Escritorio | GNOME en Wayland |
| CPU | Intel Xeon E5-2698 v4, 40 hilos |
| RAM | 30 GB |
| GPU | NVIDIA RTX 3060, driver 595.99.02 |
| Proton | GE-Proton11-3 |
| Mando | Xbox Wireless Controller por Bluetooth |

Informe de [@carlosdanielmirandadelima-blip](https://github.com/carlosdanielmirandadelima-blip): instalación hecha con el script, juego en la versión 2.2.0, partidas jugadas en una sesión Wayland sin ningún ajuste. Dos detalles de este informe:

- El juego solo detecta mandos al arrancar. Conecta el mando antes de abrir el juego, si no se queda mudo aunque el sistema ya lo vea.
- El instalador usó `C:\Program Files (x86)\SP Football Life 2026` por defecto. Mover la carpeta del juego a `C:\Games\SPFL26` y dejar un enlace simbólico en la ruta antigua (el script enlaza ambas de todos modos) mantuvo contentos al launcher y a las dos actualizaciones.

Debería funcionar en cualquier distro con un driver Vulkan operativo. Todo se instala dentro de tu carpeta personal, así que también funciona en sistemas inmutables como Bazzite y SteamOS. Sin sudo en ninguna parte.

## Qué necesitas descargar

Consigue todo desde la página oficial de SmokePatch. No lo descargues de espejos aleatorios:

**https://www.pessmokepatch.com/2025/10/spfl26.html**

Necesitas tres cosas:

1. **El juego base** (`SPFL26_setup.exe` más la carpeta `Data` y el archivo `.D01`)
2. **Actualización 2.0** (`SPFL26_200.exe`)
3. **Actualización 2.2** (`SPFL26_220.exe`)

Las actualizaciones importan. La descarga base es la versión 1.0 y sin ellas te faltan un montón de correcciones de plantillas y traspasos. Instala la 2.0 primero, luego la 2.2. El archivo de la 2.2 dice "for v2" porque espera que la 2.0 ya esté puesta.

### Consejo: usa JDownloader

Los enlaces están repartidos entre servidores con tiempos de espera, y el juego base son unos 29 GB divididos en partes. JDownloader se encarga de la cola, los tiempos y los reintentos por sí mismo. Copia los enlaces y déjalo correr durante la noche.

```bash
flatpak install flathub org.jdownloader.JDownloader
```

Mantén todas las partes en la misma carpeta. El instalador necesita la carpeta `Data` junto a `SPFL26_setup.exe`.

## Instalación rápida

Clona este repositorio y apunta el script a tu carpeta de descargas:

```bash
git clone https://github.com/agentkyo/spfl26-pes2021-linux.git
cd spfl26-pes2021-linux
./install.sh --source ~/Downloads
```

¿Quieres ver qué haría sin tocar nada?

```bash
./install.sh --check --source ~/Downloads
```

El script revisa tu sistema primero y te dice qué falta antes de descargar un solo byte. Mira el espacio en disco, tu driver Vulkan, si Steam está por ahí, y si ya tienes GE-Proton o una instalación vieja ahí parada.

```
==> Checking your system
  distro : Zorin OS 18.1
  kernel : 7.0.0-28-generic
  session: x11

  [ ok ] running as user, no root needed
  [ ok ] curl, tar, python3 and find are available
  [ ok ] 116 GB free in $HOME
  [ ok ] GPU: NVIDIA Corporation AD104 [GeForce RTX 4070 Ti]
  [ ok ] Vulkan driver: 580.173.02
  [ ok ] i386 multiarch enabled (needed by the 32 bit installers)
  [ ok ] Steam data found at /home/user/.steam/root
  [ ok ] GE-Proton11-3 already installed
  [ ok ] patch 2.0: /home/user/Downloads/SPFL26_200/SPFL26_200.exe
  [ ok ] patch 2.2: /home/user/Downloads/SPFL26_220/SPFL26_220.exe

  [ ok ] discovery passed
```

Luego descarga GE-Proton11-3, construye el prefijo, ejecuta el instalador del juego, aplica las dos actualizaciones y deja un acceso directo en tu escritorio.

Van a aparecer tres ventanas durante la instalación y tienes que pasar por ellas. Esa parte no se puede automatizar, los instaladores de SmokePatch son solo gráficos.

### Lo único que no puedes equivocar

Cada instalador pregunta dónde poner los archivos. Los tres, el juego base y las dos actualizaciones, necesitan **exactamente la misma carpeta**. Cuál carpeta es cosa tuya, mientras sea la misma las tres veces.

Dos rutas funcionan:

```
C:\Games\SPFL26
C:\Program Files (x86)\SP Football Life 2026
```

La segunda es la que sugiere el instalador base, así que dejar el valor por defecto está bien. El script revisa los dos sitios después y los enlaza entre sí, así el lanzador encuentra el juego de cualquier forma.

Lo que rompe la instalación es mezclarlas. Las actualizaciones parchean archivos que ya están ahí, así que apuntarlas a una carpeta vacía no te da nada y tampoco ningún error. Si un instalador se ofrece a crear una carpeta que ya debería existir, di **No** y corrige la ruta, porque ese aviso significa que estás en el sitio equivocado.

No uses una ruta en `Z:\`. `Z:` mapea todo tu sistema de archivos de Linux y Sider se pone raro con eso.

### Orden de instalación

1. Juego base
2. Actualización 2.0
3. Actualización 2.2

Revisa `dataSP/version.txt` dentro de la carpeta del juego después de cada una. Debería decir `1.0.0`, luego `2.0.0`, luego `2.2.0`.

Si alguna ventana dice "no responde", pulsa Esperar. El propio instalador lo avisa en pantalla, deja de responder al gestor de ventanas mientras copia. Dale tiempo. Si se queda en el mismo archivo y el mismo porcentaje varios minutos, entonces sí está atascado. Ciérralo y ejecuta ese instalador otra vez.

## El acceso directo

El script crea uno, **SP Football Life 2026**, en tu escritorio y en el menú de aplicaciones.

Antes creaba un segundo para `Settings.exe`, la aplicación que ajusta resolución y modo de pantalla. Esa aplicación no funciona bajo Proton, así que el acceso directo desapareció. Los detalles están abajo.

![Accesos directos](screenshots/shortcuts.png)

### Settings.exe no funciona, y el juego va bien sin él

`Settings.exe` es una aplicación .NET que quiere .NET Framework 4.8. Proton trae Wine Mono en su lugar, que se le parece pero no lo suficiente aquí. Carga y luego muere con un page fault dentro de `Settings_b.dll`:

```
mscoree:parse_supported_runtime sku="NETFramework,Version=v4.8" not implemented
wine: Unhandled page fault on read access to 00000004
err:mscoree:expect_no_runtimes Process exited with a Mono runtime loaded
```

El mismo fallo en todas las máquinas probadas, en los mismos offsets, así que no es cosa del driver ni del hardware. Y tampoco hay una segunda herramienta de configuración en el juego, solo `Settings.exe` y su DLL.

El juego corre con un valor por defecto razonable y los partidos completos se juegan sin abrirlo nunca. Por eso se quitó el acceso directo: un lanzador que solo falla es peor que ningún lanzador.

El script todavía escribe `~/Games/spfl26-settings.sh` por si quieres intentarlo. Instalar .NET Framework 4.8 en el prefijo con winetricks quizá lo arregle. Eso no se probó aquí, y es una dependencia pesada para un selector de resolución, así que queda como idea y no como paso. Si lo consigues, un PR será bienvenido.

## Mando

Esta es la parte que más tiempo me costó, así que léela.

**Cierra Steam antes de jugar.** Steam Input toma control exclusivo de tu mando. Cuando lo hace, el juego sigue viendo el mando en la lista de dispositivos pero nunca recibe una sola pulsación. Parece que el mando está roto. No lo está, Steam se está comiendo la entrada.

El lanzador te avisa si Steam está abierto. Si tu mando deja de funcionar de la nada, eso es lo primero que hay que mirar.

Si quieres mantener Steam abierto, ve a Configuración, Mando, y desactiva ahí el soporte de mando Xbox.

## Si algo se rompe

Estos son los errores que me encontré y lo que los arregló.

**El script dice `FL_2026.exe not found` mientras el instalador sigue copiando**

`SPFL26_setup.exe` es un bootstrapper. Descomprime el instalador real, lo lanza, y sale enseguida. Cualquier cosa que espere a ese primer proceso cree que la instalación terminó a los pocos segundos y busca un juego que no ha copiado ni un archivo.

Espera al prefijo en vez de al proceso:

```bash
WINEPREFIX="$PREFIX/pfx" wineserver -w
```

Eso vuelve cuando todo dentro del prefijo ha terminado, bootstrapper e instalador. El script hace esto ahora, así que si ves este error estás en una copia antigua.

**El script elige la GPU equivocada en un portátil**

Tomar el primer adaptador de vídeo de `lspci` te da el chip integrado en cualquier portátil híbrido, porque ese es el orden en que lo reporta el bus. Filtra primero por una tarjeta dedicada y recurre al primer adaptador solo cuando hay una sola:

```bash
lspci | grep -iE 'vga|3d|display' | grep -iE 'nvidia|amd/ati|radeon' | head -1
```

**`Unable to create interface ISteamUser`**

Este es el grande. El juego trae su propio emulador de la API de Steam, y Proton inyecta `lsteamclient` para puentear las llamadas de Steam al cliente nativo de Linux. Ese puente atrapa la llamada antes de que el emulador del juego pueda responder. El arreglo es decirle a Proton que se aparte:

```
WINEDLLOVERRIDES="lsteamclient=d"
```

El lanzador ya lo pone. Si ejecutas el juego de otra manera, lo necesitas también.

**Pantalla negra, ventilador girando, no pasa nada**

La misma causa que la anterior, solo que más callada. En Wine a secas no sale ningún error, el juego simplemente se queda en una ventana negra quemando 500% de CPU para siempre. Si ves esto, te falta el override `lsteamclient=d`.

**`Failed to load System.Private.CoreLib.dll` / error `0x8007046C`**

`FL 2026 start.exe` es una aplicación .NET de archivo único y Wine 8 no puede mapear sus ensamblados incrustados. El error `0x8007046C` es `ERROR_MAPPED_ALIGNMENT`. Usa Wine 10 o más nuevo, o GE-Proton11 como hace esta guía. Las versiones más viejas de Proton van a fallar aquí.

**El juego se congela cuando uso un escritorio virtual**

No uses el escritorio virtual de Wine para esquivar problemas de pantalla completa. Rompe Vulkan (desaparece `VK_KHR_surface`) y el juego se cuelga en vez de solo portarse mal.

**Una ventana negra de consola se queda en bucle tras una actualización**

Al final de las actualizaciones corre un script llamado `OneDrive.bat`. En Windows mueve tu partida guardada entre la carpeta Documentos normal y la de OneDrive. Aquí no hay OneDrive, así que pregunta "¿archivo o directorio?" una y otra vez y nunca para.

Simplemente cierra esa ventana. La actualización ya terminó y tu partida está bien. Si cerrarla no hace nada:

```bash
pkill -x cmd.exe
pkill -x xcopy.exe
```

**Una actualización se queda en el mismo porcentaje para siempre**

Comprueba si de verdad está atascada antes de matarla. Mira el número de archivos y el tamaño de la carpeta, no la barra de progreso:

```bash
GAME=~/Games/spfl26/drive_c/Games/SPFL26
find "$GAME" -type f | wc -l && du -sh "$GAME"
```

Ejecuta eso dos veces, con treinta segundos de diferencia. Si los dos números se mueven, está funcionando y solo tienes que esperar. Si ninguno se mueve durante unos minutos, está atascada. Ciérrala y ejecuta esa actualización otra vez.

No lo compruebes con `find -newermt`. Los instaladores conservan las marcas de tiempo originales de los archivos que escriben, así que una comprobación por tiempo no muestra nada aunque esté copiando. Esa me engañó un buen rato.

Tampoco apuntes una actualización a una carpeta que sea enlace simbólico. Probé a enlazar `C:\Program Files (x86)\SP Football Life 2026` a la carpeta real del juego para ahorrarme escribir la ruta, y la actualización 2.0 se colgaba al 38 por ciento todas las veces. Apuntarla a la carpeta real terminó sin problema.

El script enlaza las dos rutas para que el lanzador funcione de cualquier forma, lo que significa que una de ellas también es un enlace simbólico en tu máquina. Por eso imprime la carpeta real en pantalla antes de que se abra cada ventana de actualización. Escribe la ruta que te imprime, no la otra.

## Dónde va todo

```
~/Games/
├── spfl26-proton/                 prefijo y datos de compatibilidad de Proton
├── spfl26-play.sh                 lanzador del juego
└── spfl26-settings.sh             lanzador de ajustes, mira la nota de arriba
```

Nada se escribe fuera de tu carpeta personal. Para desinstalar, borra `~/Games/spfl26*` y el archivo `.desktop`.

## Créditos

**[SmokePatch](https://www.pessmokepatch.com/)** hizo SP Football Life y cada actualización. Lo hacen gratis, temporada tras temporada, para un juego que la distribuidora abandonó. Ve a darles las gracias en su sitio.

**Sider**, de juce, es lo que carga todos los mods dentro del juego.

**[GloriousEggroll](https://github.com/GloriousEggroll/proton-ge-custom)** por GE-Proton.

Yo solo resolví la parte de Linux y la escribí. Invítale un café al equipo de SmokePatch, no a mí.

## Contribuyendo

¿Lo hiciste funcionar en otra distro? Abre un issue y cuenta tus especificaciones y qué tuviste que cambiar. Los reportes desde Bazzite y SteamOS son especialmente bienvenidos.
