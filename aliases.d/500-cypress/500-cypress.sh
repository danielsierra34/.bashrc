########################################################################################## CYPRESS

cypress_install(){
    sudo npm install -g cypress
}

cypress_open(){
    cypress open
}

cypress_run_headed() {
    FOLDER=$1
    FILE=$2

    if [ "$FOLDER" == "all" ] && [ "$FILE" == "all" ]; then
        # Ejecutar todas las pruebas en modo headed
        sudo cypress run --headed
    elif [ "$FOLDER" == "all" ] && [ -n "$FILE" ]; then
        # Ejecutar un archivo específico dentro de una carpeta en modo headed
        sudo cypress run --headed --spec "/home/danielsierra34/MAESTRIA/MISW4103-Pruebas-automatizadas/CYPRESS/cypress/e2e/$FOLDER/$FILE.cy.js"
    elif [ -n "$FOLDER" ] && [ -n "$FILE" ]; then
        # Ejecutar un archivo específico en una carpeta específica en modo headed
        sudo cypress run --headed --spec "/home/danielsierra34/MAESTRIA/MISW4103-Pruebas-automatizadas/CYPRESS/cypress/e2e/$FOLDER/$FILE.cy.js"
    else
        # Ejecutar todas las pruebas en una carpeta específica en modo headed
        sudo cypress run --headed --spec "/home/danielsierra34/MAESTRIA/MISW4103-Pruebas-automatizadas/CYPRESS/cypress/e2e/$FOLDER/*.cy.js"
    fi
}

cypress_run_headless() {
    FOLDER=$1
    FILE=$2

    if [ "$FOLDER" == "all" ] && [ "$FILE" == "all" ]; then
        # Ejecutar todas las pruebas en modo headless
        sudo cypress run --headless
    elif [ "$FOLDER" == "all" ] && [ -n "$FILE" ]; then
        # Ejecutar un archivo específico dentro de una carpeta en modo headless
        sudo cypress run --headless --spec "/home/danielsierra34/MAESTRIA/MISW4103-Pruebas-automatizadas/CYPRESS/cypress/e2e/$FOLDER/$FILE.cy.js"
    elif [ -n "$FOLDER" ] && [ -n "$FILE" ]; then
        # Ejecutar un archivo específico en una carpeta específica en modo headless
        sudo cypress run --headless --spec "/home/danielsierra34/MAESTRIA/MISW4103-Pruebas-automatizadas/CYPRESS/cypress/e2e/$FOLDER/$FILE.cy.js"
    else
        # Ejecutar todas las pruebas en una carpeta específica en modo headless
        sudo cypress run --headless --spec "/home/danielsierra34/MAESTRIA/MISW4103-Pruebas-automatizadas/CYPRESS/cypress/e2e/$FOLDER/*.cy.js"
    fi
}

agregar_x() {
    #!/bin/bash    
    carpeta="."     
    for archivo in "$carpeta"/*; do
      if [ -f "$archivo" ]; then
        nombre_base=$(basename "$archivo")
        nuevo_nombre="${nombre_base}.x"
        mv "$archivo" "$carpeta/$nuevo_nombre"
      fi
    done
}

saludar(){
    echo "Hola a todos"
}

quitar_x(){
    #!/bin/bash   
    carpeta="."  # Cambia esto por la ruta real    
    for archivo in "$carpeta"/*.x; do
      if [ -f "$archivo" ]; then
        nuevo_nombre="${archivo%.x}"
        mv "$archivo" "$nuevo_nombre"
      fi
    done
}
