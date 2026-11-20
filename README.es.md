# QuestLore — El hilo de la misión

QuestLore explica por qué tu personaje está haciendo su misión activa en **WoW: Forever**. Incluye 5.259 resúmenes en inglés y español latinoamericano y añade traducciones provisionales al francés, alemán, portugués de Brasil y ruso.

La versión **0.18.0-beta11** añade ruso, acorta el aviso de actualización y permite leer las últimas cinco versiones desde las opciones. Alemán sigue disponible.

## Idiomas

En **Opciones → AddOns → QuestLore** puedes elegir el idioma del resumen. El modo automático mantiene español LA para clientes españoles e inglés para el resto; los idiomas beta se eligen manualmente mientras continúa su revisión. Los idiomas base son inglés y español latinoamericano; la revisión de los nombres originales de esMX sigue en curso. Un cliente español de España usa por ahora el banco latinoamericano.

Los resúmenes nuevos en francés, alemán, portugués de Brasil y ruso se traducen desde el inglés y conservan los nombres propios en inglés dentro del resumen. El título mostrado se obtiene del cliente en el idioma del juego, independientemente del idioma elegido para el resumen. Son traducciones automáticas provisionales con comprobaciones y correcciones parciales; no se presentan como textos originales oficiales de esos idiomas. El aviso de las opciones explica esta diferencia.

## Leer texto completo

El botón **Leer texto completo** aparece para la misión actual mientras esté activa en tu diario. Abre la descripción y los objetivos originales en una ventana con scroll, sin recortar el contenido.

Si falta un resumen, Lore muestra una vista previa literal del original con **…**. Al pulsarla se abre el texto completo. La vista previa no se guarda en el historial.

El texto completo usa el **idioma del cliente del juego**, aunque hayas elegido otro idioma para el resumen. No se añade al historial ni se conserva después de cerrar el lector o abandonar la misión. El historial guarda únicamente resúmenes narrativos e introducciones.

## Ventana y opciones

La enciclopedia incluye **2,163 entidades y 15,141 artículos** en los siete idiomas del addon. Las fichas en francés, alemán, portugués de Brasil y ruso son traducciones provisionales del inglés y conservan sus nombres propios, títulos y alias. Los nombres reconocidos en los resúmenes, el historial y las introducciones aparecen en amarillo, sin subrayado. Al pulsarlos se abre su ficha en el idioma del relato, con vínculos a otras entradas relacionadas y sin cambiar la misión activa. El lector se puede mover, redimensionar y desplazar; no tiene un índice para navegar libremente.

Las fichas emplean nombres de las fuentes originales de cada idioma y evitan revelar identidades ocultas o desenlaces posteriores. Los nombres sin una identificación revisada permanecen como texto normal. Consulta la [cobertura y las fuentes](docs/ENCYCLOPEDIA.md).

Puedes activar **Mostrar fondo** y ajustar **Transparencia del fondo** entre 0 % (opaco) y 100 % (transparente). Se aplica al instante sin atenuar el texto y funciona tanto adjunto al rastreador como separado. Las preferencias se guardan por personaje; el fondo está desactivado inicialmente.

La interfaz está disponible en español latinoamericano, inglés, francés, alemán, portugués de Brasil y ruso. En las opciones puedes elegir su idioma por separado del de los resúmenes. El modo automático de la interfaz usa el idioma del juego cuando está disponible y, en caso contrario, inglés. Ambas preferencias se guardan por personaje; cambiar los menús no cambia el idioma de los relatos ni el texto original del juego.

Lore se adjunta al final del rastreador cuando está disponible la integración de ForeverCore. Puedes separarlo desde las opciones, moverlo arrastrando la cabecera y cambiar el tamaño desde la esquina inferior derecha. Si la caja separada es más ancha que alta, muestra el título centrado en la cabecera y el resumen justificado.

El tamaño del texto admite 12–24, con 14 inicial. La cabecera solo contiene minimizar/restaurar. El botón está siempre visible cuando Lore está adjunto; separado aparece al pasar el mouse. La rueda permite leer los textos largos y la barra desaparece si el contenido cabe.

El historial está en **Opciones → AddOns → QuestLore → Historial** y conserva hasta 200 resúmenes únicos por personaje. Revisarlo no cambia la misión mostrada en Lore.

La integración opcional con Polestar sigue su misión activa aceptada. Se puede activar o desactivar desde las opciones. Al comenzar con un personaje de nivel uno sin misiones, una introducción combina raza y clase.

## Instalación

Extrae la carpeta **QuestLore** del ZIP dentro de `_forever_/Interface/AddOns/`. Si actualizas una instalación existente, usa `/reload`. El addon apunta a la interfaz 16001.

`/lore` muestra la ventana; `/lore reset` restaura su posición. El addon funciona localmente y no traduce mediante servicios de Internet durante la partida.

La recopilación manual de originales con **QuestLoreProbe** es una herramienta separada de investigación y no se distribuye a los usuarios normales del addon.

Consulta [la documentación principal en inglés](README.md) y [los detalles de idiomas y almacenamiento](docs/LANGUAGES.md).

La integración opcional con RestedXP sigue la misión aceptada de su flecha o un paso con una única misión identificable. Se configura por personaje; Polestar tiene prioridad si ambas integraciones están activadas. Questie funciona mediante la selección y el enfoque habituales de misiones. Consulta [los detalles y límites](docs/RESTEDXP.md).

La misión activa que selecciones en el diario o pongas en foco en el rastreador tiene prioridad sobre Polestar y RestedXP. Cuando ya no haya una misión válida con ese foco, se vuelve a utilizar la guía.

La opción **Mostrar botón de texto completo** permite ocultar la acción en Lore y el historial. Está activada por defecto y se guarda por personaje. Las vistas previas del texto original siguen siendo pulsables.

Colaborador: [dawiss](https://github.com/dawiss) aportó los resúmenes de misiones, las introducciones y la traducción inicial de la interfaz al polaco. Completamos su integración, las opciones nuevas y la enciclopedia.

Tras actualizar, un aviso discreto bajo Lore abre **Opciones → AddOns → QuestLore → Novedades**. Leer o cerrar el aviso se guarda por personaje. Las notas de la versión instalada siempre se pueden consultar en las opciones; también puedes desactivar los avisos. No hay comprobaciones de versiones en línea ni entre jugadores.
