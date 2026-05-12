#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DELIVERY_SRC="$PROJECT_DIR/ENTREGA/src"
BASE_SRC="$PROJECT_DIR/src"
BUNDLE_DIR="$PROJECT_DIR/gtkwave_bundle"
WORKDIR="$BUNDLE_DIR/workdir"
WAVES_DIR="$BUNDLE_DIR/waves"
GTKW_DIR="$BUNDLE_DIR/gtkw"
LOGS_DIR="$BUNDLE_DIR/logs"
MANIFEST="$BUNDLE_DIR/capture_manifest.tsv"
VALIDATION="$BUNDLE_DIR/VALIDACION_BUNDLE.txt"

overlay_files=(
  "ALU_2026.vhd"
  "Completar_UC_MC_2026.vhd"
  "INCOMPLETE_Mips_segmentado_IRQ_2026.vhd"
  "INCOMPLETE_UA_2026.vhd"
  "INCOMPLETE_UC_Mips_2026.vhd"
  "INCOMPLETE_UD_2026.vhd"
  "RAM_128_32_P2.vhd"
  "RAM_I_P2.vhd"
)

captures=(
  "01|Test_lecturas_P2_contadores|0|0|12000|1000|Evolucion de contadores en flujo largo"
  "02|Test_lecturas_P2_abort|0|0|12000|11100|Transicion a abort y lectura de Addr_Error_Reg"
  "03|write_around|2|1|3000|150|Write miss cacheable sin asignacion de bloque"
  "04|copy_back|3|1|4000|250|Reemplazo sucio y copy-back"
  "05|refetch_bloque_A|3|1|4000|650|Refetch del bloque A tras copy-back"
  "06|scratch|4|1|3000|100|Accesos a MD Scratch"
  "07|io_registers|5|1|3000|100|Lectura y escritura de registros de E/S"
  "08|readonly_internal_reg|6|1|3000|100|Escritura ilegal en registro interno"
  "09|no_devsel|7|1|3000|100|Direccion fuera de rango sin DevSel"
  "10|unaligned|8|1|2500|80|Acceso desalineado"
  "11|undef|9|1|2500|80|Rutina UNDEF"
)

die() {
  echo "ERROR: $*" >&2
  exit 1
}

activate_ram_variant() {
  local file="$1"
  local variant="$2"
  local tmp
  tmp="$(mktemp)"
  awk -v target="$variant" '
    function uncomment(s) {
      sub(/^[[:space:]]*-- ?/, "", s)
      return s
    }
    function comment(s, lead, rest) {
      if (s ~ /^[[:space:]]*--/) {
        return s
      }
      match(s, /^[[:space:]]*/)
      lead = substr(s, 1, RLENGTH)
      rest = substr(s, RLENGTH + 1)
      return lead "-- " rest
    }
    BEGIN {
      idx = -1
      in_block = 0
      chosen = 0
    }
    {
      if ($0 ~ /^[[:space:]]*(--[[:space:]]*)?signal RAM : RamType := \($/) {
        idx++
        in_block = 1
        chosen = (idx == target)
        if (chosen) {
          print uncomment($0)
        } else {
          print comment($0)
        }
        next
      }
      if (in_block) {
        if (chosen) {
          print uncomment($0)
        } else {
          print comment($0)
        }
        if ($0 ~ /^[[:space:]]*(--[[:space:]]*)?\);[[:space:]]*$/) {
          in_block = 0
        }
        next
      }
      print
    }
    END {
      if (idx < target) {
        exit 2
      }
    }
  ' "$file" > "$tmp" || die "No se pudo activar la variante $variant en $file"
  mv "$tmp" "$file"
}

prepare_workdir() {
  rm -rf "$WORKDIR"
  mkdir -p "$WORKDIR" "$WAVES_DIR" "$GTKW_DIR" "$LOGS_DIR"
  cp -a "$BASE_SRC"/. "$WORKDIR"/
  for f in "${overlay_files[@]}"; do
    cp "$DELIVERY_SRC/$f" "$WORKDIR/$f"
  done
}

restore_ram_templates() {
  cp "$DELIVERY_SRC/RAM_I_P2.vhd" "$WORKDIR/RAM_I_P2.vhd"
  cp "$DELIVERY_SRC/RAM_128_32_P2.vhd" "$WORKDIR/RAM_128_32_P2.vhd"
}

emit_vec() {
  local path="$1"
  local msb="${2:-31}"
  local lsb="${3:-0}"
  local i
  printf '#{%s[%d:%d]}' "$path" "$msb" "$lsb"
  for ((i=msb; i>=lsb; i--)); do
    printf ' %s[%d]' "$path" "$i"
  done
  printf '\n'
}

emit_gtkw_header() {
  local file="$1"
  local wave="$2"
  local timestart="$3"
  cat > "$file" <<EOF
[*]
[*] GTKWave Analyzer v3.3.121
[*]
[dumpfile] "$wave"
[savefile] "$file"
[timestart] $timestart
[size] 1600 900
[pos] -1 -1
*-25.000000 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
[treeopen] top.
[treeopen] top.testbench.
[treeopen] top.testbench.uut.
[treeopen] top.testbench.uut.io_mem.
[treeopen] top.testbench.uut.io_mem.mc.
[treeopen] top.testbench.uut.mips_core.
[treeopen] top.testbench.uut.mips_core.int_register_bank.
[sst_width] 340
[signals_width] 290
[sst_expanded] 1
[sst_vpaned_height] 300
EOF
}

append_common_signals() {
  local file="$1"
  {
    echo "@28"
    echo "top.testbench.clk"
    echo "top.testbench.reset"
    echo "top.testbench.uut.io_mem_ready"
    echo "top.testbench.uut.data_abort"
    echo "@22"
    emit_vec "top.testbench.uut.mips_addr"
    emit_vec "top.testbench.uut.mips_dout"
    emit_vec "top.testbench.uut.mips_din"
    emit_vec "top.testbench.io_output"
  } >> "$file"
}

make_gtkw_file() {
  local cap="$1"
  local slug="$2"
  local timestart="$3"
  local wave="$WAVES_DIR/capture_${cap}_${slug}.ghw"
  local file="$GTKW_DIR/capture_${cap}_${slug}.gtkw"

  emit_gtkw_header "$file" "$wave" "$timestart"
  append_common_signals "$file"

  case "$cap" in
    01)
      {
        echo "@200"
        echo "-"
        echo "-=== REGISTROS Y CONTADORES ==="
        echo "@22"
        emit_vec "top.testbench.uut.mips_core.int_register_bank.reg_file[2]"
        emit_vec "top.testbench.uut.mips_core.int_register_bank.reg_file[5]"
        emit_vec "top.testbench.uut.mips_core.int_register_bank.reg_file[6]"
        emit_vec "top.testbench.uut.io_mem.mc.m_count" 7 0
        emit_vec "top.testbench.uut.io_mem.mc.w_count" 7 0
        emit_vec "top.testbench.uut.io_mem.mc.r_count" 7 0
        emit_vec "top.testbench.uut.io_mem.mc.cb_count" 7 0
        echo "@28"
        echo "top.testbench.uut.io_mem.mc.mem_error"
      } >> "$file"
      ;;
    02)
      {
        echo "@200"
        echo "-"
        echo "-=== ABORT Y REGISTRO DE ERROR ==="
        echo "@28"
        echo "top.testbench.uut.io_mem.mc.mem_error"
        echo "top.testbench.uut.io_mem.mc.load_addr_error"
        echo "top.testbench.uut.io_mem.mc.internal_addr"
        echo "@22"
        emit_vec "top.testbench.uut.io_mem.mc.addr_error"
      } >> "$file"
      ;;
    03)
      {
        echo "@200"
        echo "-"
        echo "-=== WRITE-AROUND ==="
        echo "@28"
        echo "top.testbench.uut.io_mem.mc_bus_req"
        echo "top.testbench.uut.io_mem.mc_bus_grant"
        echo "top.testbench.uut.io_mem.bus_frame"
        echo "top.testbench.uut.io_mem.bus_devsel"
        echo "top.testbench.uut.io_mem.bus_trdy"
        echo "top.testbench.uut.io_mem.mc.mc_bus_write"
        echo "top.testbench.uut.io_mem.mc.mc_send_addr_ctrl"
        echo "top.testbench.uut.io_mem.mc.mc_send_data"
        echo "top.testbench.uut.io_mem.mc.we_via0"
        echo "top.testbench.uut.io_mem.mc.we_via1"
        echo "top.testbench.uut.io_mem.mc.mc_tags_we"
        echo "@22"
        emit_vec "top.testbench.uut.io_mem.bus_data_addr"
      } >> "$file"
      ;;
    04)
      {
        echo "@200"
        echo "-"
        echo "-=== COPY-BACK ==="
        echo "@28"
        echo "top.testbench.uut.io_mem.mc.hit0"
        echo "top.testbench.uut.io_mem.mc.hit1"
        echo "top.testbench.uut.io_mem.mc.via_2_rpl"
        echo "top.testbench.uut.io_mem.mc.dirty_bit_rpl"
        echo "top.testbench.uut.io_mem.mc.send_dirty"
        echo "top.testbench.uut.io_mem.mc.mc_bus_write"
        echo "top.testbench.uut.io_mem.mc.mc_bus_read"
        echo "top.testbench.uut.io_mem.mc.mc_send_data"
        echo "top.testbench.uut.io_mem.mc.block_copied_back"
        echo "top.testbench.uut.io_mem.mc.we_via0"
        echo "top.testbench.uut.io_mem.mc.we_via1"
        echo "top.testbench.uut.io_mem.mc.mc_tags_we"
        echo "top.testbench.uut.io_mem.bus_frame"
        echo "top.testbench.uut.io_mem.bus_devsel"
        echo "top.testbench.uut.io_mem.bus_trdy"
        echo "@22"
        emit_vec "top.testbench.uut.io_mem.mc.cb_count" 7 0
        emit_vec "top.testbench.uut.io_mem.mc.copy_back_addr"
      } >> "$file"
      ;;
    05)
      {
        echo "@200"
        echo "-"
        echo "-=== REFETCH DEL BLOQUE A ==="
        echo "@28"
        echo "top.testbench.uut.io_mem.mc.hit0"
        echo "top.testbench.uut.io_mem.mc.hit1"
        echo "top.testbench.uut.io_mem.mc.we_via0"
        echo "top.testbench.uut.io_mem.mc.we_via1"
      } >> "$file"
      ;;
    06)
      {
        echo "@200"
        echo "-"
        echo "-=== MD SCRATCH ==="
        echo "@28"
        echo "top.testbench.uut.io_mem.mc.addr_non_cacheable"
        echo "top.testbench.uut.io_mem.mc.mc_bus_read"
        echo "top.testbench.uut.io_mem.mc.mc_bus_write"
        echo "top.testbench.uut.io_mem.mc.block_addr"
        echo "top.testbench.uut.io_mem.mc.we_via0"
        echo "top.testbench.uut.io_mem.mc.we_via1"
        echo "top.testbench.uut.io_mem.mc.mc_tags_we"
        echo "top.testbench.uut.io_mem.md_scratch_bus_devsel"
        echo "top.testbench.uut.io_mem.md_scratch_bus_trdy"
        echo "top.testbench.uut.io_mem.md_scratch_send_data"
        echo "@22"
        emit_vec "top.testbench.uut.io_mem.md_scratch_dout"
      } >> "$file"
      ;;
    07)
      {
        echo "@200"
        echo "-"
        echo "-=== REGISTROS DE E/S ==="
        echo "@22"
        emit_vec "top.testbench.io_input"
        emit_vec "top.testbench.uut.io_mem.input_data"
        emit_vec "top.testbench.uut.io_mem.output_data"
        echo "@28"
        echo "top.testbench.uut.io_mem.addr_input"
        echo "top.testbench.uut.io_mem.addr_output"
        echo "top.testbench.uut.io_mem.addr_ack"
      } >> "$file"
      ;;
    08)
      {
        echo "@200"
        echo "-"
        echo "-=== REGISTRO INTERNO SOLO LECTURA ==="
        echo "@28"
        echo "top.testbench.uut.io_mem.mc.internal_addr"
        echo "top.testbench.uut.io_mem.mc.load_addr_error"
        echo "top.testbench.uut.io_mem.mc.mem_error"
        echo "@22"
        emit_vec "top.testbench.uut.io_mem.mc.addr_error"
      } >> "$file"
      ;;
    09)
      {
        echo "@200"
        echo "-"
        echo "-=== NO DEVSEL ==="
        echo "@28"
        echo "top.testbench.uut.io_mem.bus_frame"
        echo "top.testbench.uut.io_mem.bus_devsel"
        echo "top.testbench.uut.io_mem.mc.mc_send_addr_ctrl"
        echo "top.testbench.uut.io_mem.mc.mem_error"
        echo "@22"
        emit_vec "top.testbench.uut.io_mem.mc.addr_error"
      } >> "$file"
      ;;
    10)
      {
        echo "@200"
        echo "-"
        echo "-=== UNALIGNED ==="
        echo "@28"
        echo "top.testbench.uut.io_mem.mc.unaligned"
        echo "top.testbench.uut.io_mem.mc.load_addr_error"
        echo "top.testbench.uut.io_mem.mc.mem_error"
        echo "@22"
        emit_vec "top.testbench.uut.io_mem.mc.addr_error"
      } >> "$file"
      ;;
    11)
      {
        echo "@200"
        echo "-"
        echo "-=== UNDEF ==="
        echo "@28"
        echo "top.testbench.uut.mips_core.undef"
        echo "top.testbench.uut.mips_core.exception_accepted"
        echo "top.testbench.uut.mips_core.data_abort"
        echo "@22"
        emit_vec "top.testbench.uut.mips_core.pc_out"
        emit_vec "top.testbench.uut.mips_core.ir_id"
      } >> "$file"
      ;;
    *)
      die "Captura desconocida para gtkw: $cap"
      ;;
  esac
}

run_capture() {
  local cap="$1"
  local slug="$2"
  local inst_variant="$3"
  local data_variant="$4"
  local stop_ns="$5"
  local description="$6"
  local log_file="$LOGS_DIR/capture_${cap}_${slug}.log"
  local wave_file="$WAVES_DIR/capture_${cap}_${slug}.ghw"

  restore_ram_templates
  activate_ram_variant "$WORKDIR/RAM_I_P2.vhd" "$inst_variant"
  activate_ram_variant "$WORKDIR/RAM_128_32_P2.vhd" "$data_variant"

  {
    echo "Captura $cap - $description"
    echo "instruction_variant=$inst_variant"
    echo "data_variant=$data_variant"
    echo "stop_time_ns=$stop_ns"
    echo "----------------------------------------"
  } > "$log_file"

  (
    cd "$WORKDIR"
    ./build.sh clean >> "$log_file" 2>&1
    ./build.sh testbench >> "$log_file" 2>&1
    ./testbench --stop-time="${stop_ns}ns" --wave="$wave_file" >> "$log_file" 2>&1
  )
}

write_manifest() {
  {
    echo -e "capture_id\tslug\tinstruction_variant\tdata_variant\tstop_time_ns\ttimestart_ns\tdescription"
    for item in "${captures[@]}"; do
      IFS='|' read -r cap slug inst data stop timestart description <<< "$item"
      echo -e "${cap}\t${slug}\t${inst}\t${data}\t${stop}\t${timestart}\t${description}"
    done
  } > "$MANIFEST"
}

write_validation() {
  cat > "$VALIDATION" <<EOF
Bundle generado en: $BUNDLE_DIR

Resumen de validacion:
- El testbench integrado se recompila para cada captura y genera su fichero .ghw correspondiente.
- La captura 1/2 usa el escenario activo largo de la entrega.
- Las capturas 3..11 activan las variantes de RAM_I_P2 y RAM_128_32_P2 indicadas en memoria.md.

Archivos clave:
- Manifest: $MANIFEST
- Ondas: $WAVES_DIR
- Vistas GTKWave: $GTKW_DIR
- Logs de simulacion: $LOGS_DIR
EOF
}

main() {
  command -v ghdl >/dev/null 2>&1 || die "ghdl no esta disponible"
  prepare_workdir
  write_manifest

  for item in "${captures[@]}"; do
    IFS='|' read -r cap slug inst data stop timestart description <<< "$item"
    run_capture "$cap" "$slug" "$inst" "$data" "$stop" "$description"
    make_gtkw_file "$cap" "$slug" "$timestart"
  done

  write_validation
  printf 'Bundle generado en %s\n' "$BUNDLE_DIR"
}

main "$@"
