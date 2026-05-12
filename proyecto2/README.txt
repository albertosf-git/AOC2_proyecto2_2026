PROYECTO 2

Estado
Esta carpeta contiene el trabajo consolidado del Proyecto 2 integrado ya dentro de `proyecto2/`. La base funcional viene del P1, y aqui quedan reunidos el codigo VHDL, los testbenches, la documentacion tecnica y los informes de validacion.

Estructura
- `src/`
  Codigo VHDL del proyecto, incluida la UC actualizada y todos los testbenches relevantes.
- `docs/`
  PDFs del enunciado, esquemas y documentos de apoyo del P1 y del P2.
- `notas/`
  Informes tecnicos, cobertura de tests, contraste de contadores, hoja de ruta e indice de uso.
- `tools/`
  Scripts auxiliares para regenerar bundles de GTKWave y abrir secuencias de capturas.

Ficheros clave
- `src/Completar_UC_MC_2026.vhd`
- `src/MC_datos_CB_2026.vhd`
- `src/IO_MD_subsystem_2026.vhd`
- `src/testbench_AOC2_SoC_2026.vhd`
- `src/tb_uc_mc_cb.vhd`
- `src/tb_uc_mc_event_counts.vhd`
- `src/tb_latency_p2.vhd`
- `src/tb_p2_abort_monitor.vhd`
- `src/tb_io_md_hierarchy_paths.vhd`
- `src/tb_uc_mc_unaligned.vhd`
- `notas/INFORME_UC_P2.txt`
- `notas/INFORME_TESTS_FORMALES_P2.txt`
- `notas/TABLA_COBERTURA_TESTS_P2.txt`
- `notas/CONTRASTE_CONTADORES_TEST_LECTURAS_P2.txt`
- `notas/GUIA_GTKWAVE_CAPTURAS_P2.txt`
- `tools/generate_p2_capture_bundle.sh`
- `tools/run_p2_capture_sequence.sh`
- `notas/INDICE_VALIDACION_Y_USO.txt`

Que esta ya hecho
- UC de cache funcional base.
- Tests unitarios de la UC.
- Test integrado del flujo de abort.
- Tests formales de latencias.
- Test formal de pulsos de eventos de contadores.
- Test integrado dirigido de rutas clave de la jerarquia IO/MD.
- Test unitario dirigido del camino `unaligned` de la UC.
- Contraste del programa largo con `Test_lecturas_P2.pdf` en la fase normal del bucle.
- Flujo reproducible para generar y abrir las capturas GTKWave de la memoria final.

Flujo recomendado de uso
1. Leer `docs/AOC2_2026_P2.pdf`.
2. Revisar `notas/INDICE_VALIDACION_Y_USO.txt`.
3. Entrar en `proyecto2/src`.
4. Limpiar antes de empezar una sesion nueva:
   `./build.sh clean`
5. Compilar y ejecutar un test cada vez.

Regla importante
- No lances varias compilaciones de `ghdl` en paralelo dentro de `src/`, porque todas comparten `WORK/` y pueden corromper la libreria temporal.

Comandos utiles
- Simulacion integrada:
  `./build.sh testbench`
  `./testbench --stop-time=5us`

- UC unitaria:
  `./build.sh tb_uc_mc_cb`
  `./tb_uc_mc_cb --stop-time=2us`

- Pulsos de contadores:
  `./build.sh tb_uc_mc_event_counts`
  `./tb_uc_mc_event_counts --stop-time=1us`

- Latencias:
  `./build.sh tb_latency_p2`
  `./tb_latency_p2 --stop-time=2us`

- Abort integrado:
  `./build.sh tb_p2_abort_monitor`
  `./tb_p2_abort_monitor --stop-time=12us`

- Rutas integradas de jerarquia IO/MD:
  `./build.sh tb_io_md_hierarchy_paths`
  `./tb_io_md_hierarchy_paths --stop-time=5us`

- Camino `unaligned` de la UC:
  `./build.sh tb_uc_mc_unaligned`
  `./tb_uc_mc_unaligned --stop-time=1us`

- Bundle GTKWave para las 11 capturas:
  `./tools/generate_p2_capture_bundle.sh`
  `./tools/run_p2_capture_sequence.sh`

Notas importantes
- `src/MC_datos_CB_2026.vhd` incluye instrumentacion de depuracion para emitir trazas `MC_COUNTERS` durante simulacion integrada. Sirve para contrastar contadores y no cambia la logica funcional de la cache.
- `src/WORK/` y los ejecutables generados son artefactos temporales. Se regeneran con cada compilacion.
- La pieza central del proyecto sigue siendo la UC de la cache y su justificacion en memoria.

Lectura recomendada
1. `docs/AOC2_2026_P2.pdf`
2. `notas/BASE_P2_COHESION.txt`
3. `notas/INFORME_UC_P2.txt`
4. `notas/INFORME_TESTS_FORMALES_P2.txt`
5. `notas/TABLA_COBERTURA_TESTS_P2.txt`
6. `notas/CONTRASTE_CONTADORES_TEST_LECTURAS_P2.txt`
