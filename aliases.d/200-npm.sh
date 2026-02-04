########################################################################################## NPM
npm_list(){
    npm list -g --depth=0
}
npm_install(){
    if [ -z "$1" ]; then
        echo "Usage: npm_install <packageName>"
        return 1
    fi
    sudo npm install -g "$1"
}
npm_uninstall(){
    if [ -z "$1" ]; then
        echo "Usage: npm_uninstall <packageName>"
        return 1
    fi
    sudo npm uninstall -g "$1"
}
npx_list(){
    npm list --depth=0
}
npx_install(){
    if [ -z "$1" ]; then
        echo "Usage: npx_install <packageName>"
        return 1
    fi
    npm install "$1"
}
npx_uninstall(){
    if [ -z "$1" ]; then
        echo "Usage: npx_uninstall <packageName>"
        return 1
    fi
    npm uninstall "$1"
}

