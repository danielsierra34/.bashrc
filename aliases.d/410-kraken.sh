########################################################################################## KRAKEN
kraken_install(){
    npm install kraken-node -g
    kraken-node gen
    npm install kraken-node
}

kraken_run(){
    npm run test --workspace=e2e/misw-4103-kraken
}

kraken_reports_clear(){
    sudo rm -r /e2e/misw-4103-kraken/reports/
}
chromium_listen(){
    chromedriver --port=4444
}





