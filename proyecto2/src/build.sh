#!/bin/bash

# Script para compilar, ejecutar y limpiar el proyecto de VHDL utilizando GHDL


# Si parametro es "clean", eliminar el directorio build, si es "run", ejecutar el programa, sino compilarlo
if [ "$1" == "clean" ]; then
    ghdl --clean --workdir=WORK
    rm -rf WORK
elif [ "$1" == "run" ]; then
    if [ "$2" == "" ]; then
        echo "Usage: $0 run <testbench_entity_name>"
        exit 1
    fi

    if [ "$3" == "" ]; then
        ./"$2" --stop-time=500ns --wave=test.ghw
    else
        ./"$2" --stop-time="$3"ns --wave=test.ghw
    fi
    
    gtkwave test.ghw &
else
    if [ "$1" == "" ]; then
        echo "======================================================================"
        echo "SCRIPT DE GESTIÓN VHDL (GHDL)"
        echo "======================================================================"
        echo "Uso:"
        echo "  $0 <entidad_principal>    Compila el proyecto."
        echo "  $0 run <entidad_tb> [ns]  Ejecuta la simulación y abre GTKWave."
        echo "  $0 clean                  Limpia los archivos temporales y compilados."
        echo ""
        echo "Ejemplos:"
        echo "  $0 MIPs_segmentado        (Compila usando esa entidad como tope)"
        echo "  $0 run testbench          (Simula 500ns por defecto)"
        echo "  $0 run testbench 1000     (Simula 1000ns)"
        echo "======================================================================"
        exit 1
    fi
    mkdir -p WORK
    ghdl -i --ieee=synopsys -fexplicit --workdir=WORK *.vhd
    ghdl --gen-makefile --ieee=synopsys -fexplicit --workdir=WORK "$1" > Makefile
    ghdl -m --ieee=synopsys -fexplicit --workdir=WORK "$1"
    # In step 1 you are creating the project in the directory WORK. In step 2 we create a file Makefile to build
    # an executable file in step 3 with ghdl -m
fi