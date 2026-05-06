## Informe rápido del estado del proyecto P2

### Hecho

| Parte                                                         | Estado        |
| ------------------------------------------------------------- | ------------- |
| Integración general del P2                                    | Hecha         |
| Caché de datos de 2 vías, 4 conjuntos y bloques de 4 palabras | Hecha         |
| Separación de dirección en tag, conjunto, palabra y byte      | Hecha         |
| Bus semisincrónico con `Frame`, `TRDY`, `DevSel`, `last_word` | Hecho         |
| Árbitro de bus                                                | Hecho         |
| Memoria principal lenta `MD`                                  | Hecha         |
| Memoria Scratch no cacheable                                  | Hecha         |
| `IO_Master` escribiendo en Scratch                            | Hecho         |
| Lecturas con hit en caché                                     | Hechas        |
| Escrituras con hit en caché                                   | Hechas        |
| Read miss con carga de bloque                                 | Hecho         |
| Write miss con write-around                                   | Hecho         |
| Registro interno de error                                     | Hecho         |
| Señal de `Data_abort`                                         | Hecha         |
| Contadores `m`, `r`, `w`, `cb`                                | Implementados |
| Tests unitarios de UC                                         | Hechos        |
| Test de latencias                                             | Hecho         |
| Test de abort integrado                                       | Hecho         |
| Test de lecturas básico                                       | Hecho         |

---

### A medias / necesita revisión

| Parte                              | Qué falta revisar                                                                                      |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Copy-back de bloques sucios        | Está implementado, pero hay un posible fallo al limpiar el bit `dirty` tras copiar el bloque a memoria |
| Contador `w`                       | Hay que confirmar si debe contar también los write miss con write-around                               |
| Contadores en integración completa | Están probados en UC, pero falta validarlos mejor con la caché completa                                |
| Errores de memoria                 | Funcionan en UC, pero faltan más pruebas integradas                                                    |
| `Addr_Error_Reg`                   | Revisar si guarda exactamente la dirección original en accesos desalineados                            |
| Comentarios del código             | Algunos comentarios antiguos no coinciden con la política actual copy-back/write-around                |
| Instrumentación de debug           | Conviene limpiar o justificar los `report` antes de entregar                                           |

---

### Falta por hacer

| Tarea                                                                                 | Prioridad   |
| ------------------------------------------------------------------------------------- | ----------- |
| Corregir limpieza de dirty bit tras copy-back                                         | Alta        |
| Crear test integrado de reemplazo sucio real                                          | Alta        |
| Crear test integrado de write-around                                                  | Alta        |
| Crear test integrado de Scratch desde programa MIPS                                   | Media       |
| Probar errores integrados: desalineado, dirección inválida, write a registro readonly | Media       |
| Validar contadores finales en un programa con lecturas, escrituras y copy-back        | Alta        |
| Medir speedup frente a memoria sin caché/scratch                                      | Alta        |
| Preparar informe final                                                                | Alta        |
| Dibujar grafo de estados de la UC                                                     | Alta        |
| Hacer tabla de estados/señales de control                                             | Alta        |
| Incluir fórmula de tiempo medio de acceso/CPI                                         | Alta        |
| Añadir tabla de tests y resultados                                                    | Alta        |
| Incluir horas por integrante y autoevaluación                                         | Obligatorio |

---

### Riesgo principal

El mayor riesgo técnico es este:

**Después de hacer copy-back de un bloque sucio, puede que el bit `dirty` no se esté limpiando correctamente.**

Eso puede provocar que un bloque nuevo entre en caché marcado como sucio aunque no se haya escrito sobre él. Resultado: copy-backs extra y contador `cb` incorrecto.

---

### Estado global

| Área                    | Valoración   |
| ----------------------- | ------------ |
| Código base             | 80-85% hecho |
| Funcionalidad principal | 75-80% hecha |
| Validación              | 55-65% hecha |
| Informe                 | 20-30% hecho |
| Entregable final        | 65-70% listo |

---

### Resumen final

El proyecto **no está empezado ni a medias bajas**: está bastante avanzado.
La caché, bus, Scratch, MD, IO_Master, UC y contadores están implementados.

Lo que queda es sobre todo:

1. **cerrar bugs finos**, especialmente dirty/copy-back;
2. **hacer tests integrados más completos**;
3. **medir latencias/speedup**;
4. **redactar el informe final**.

Con esos puntos cerrados, el proyecto debería quedar bastante sólido para entregar.
