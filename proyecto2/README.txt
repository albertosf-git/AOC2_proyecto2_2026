P2_BASE_PARA_COPIAR

Esta carpeta esta preparada para copiarse fuera y empezar a trabajar sobre el Proyecto 2.

Estructura
- src/
  Contiene el proyecto VHDL listo para compilar.
- docs/
  Contiene la documentacion relevante del P1 y P2.
- notas/
  Contiene el resumen de cohesion de la base y la hoja de ruta de desarrollo.

Punto de partida tecnico
- El MIPS y la parte funcional del Proyecto 1 ya estan integrados.
- El subsistema de memoria ya es el del Proyecto 2.
- La pieza principal pendiente de implementar es:
  src/Completar_UC_MC_2026.vhd

Uso recomendado
1. Entra en src/
2. Compila:
   ./build.sh testbench
3. Ejecuta una simulacion corta:
   ./testbench --stop-time=800ns

Ficheros clave
- src/Completar_UC_MC_2026.vhd
- src/MC_datos_CB_2026.vhd
- src/IO_MD_subsystem_2026.vhd
- src/RAM_I_test_subsanacion.vhd
- docs/AOC2_2026_P2.pdf
- docs/Esquema_MC_2026.pptx.pdf
- docs/Test_lecturas_P2.pdf
- notas/HOJA_DE_RUTA_P2.txt

Observaciones
- Esta copia no incluye binarios, objetos ni carpetas WORK generadas.
- Esta pensada como base limpia para llevar fuera del repositorio y continuar el desarrollo.
