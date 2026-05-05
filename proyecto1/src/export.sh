#!/bin/bash

# Nombre del archivo de salida
OUTPUT_FILE="OUTPUT.txt"

# Limpiar el archivo de salida si ya existe
> "$OUTPUT_FILE"

echo "Iniciando la consolidación de archivos .vhd..."

# Bucle para buscar archivos .vhd en el directorio actual
for file in *.vhd; do
    # Verificar si existen archivos para evitar errores si la carpeta está vacía
    [ -e "$file" ] || continue

    echo "Procesando: $file"

    # Escribir un encabezado decorativo para organizar el contenido
    echo "================================================================================" >> "$OUTPUT_FILE"
    echo " ARCHIVO: $file" >> "$OUTPUT_FILE"
    echo " FECHA DE PROCESAMIENTO: $(date)" >> "$OUTPUT_FILE"
    echo "================================================================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Volcar el contenido del archivo .vhd al archivo de texto
    cat "$file" >> "$OUTPUT_FILE"

    # Añadir un par de saltos de línea al final de cada archivo
    echo -e "\n\n" >> "$OUTPUT_FILE"
done

echo "¡Hecho! Todo el contenido se ha guardado en $OUTPUT_FILE"