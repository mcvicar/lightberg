#!/bin/bash

cd lambda/
for folder in $(ls ./); do
    echo "Building lightberg ${folder}"
    cp ../vars.tfvars ${folder}
    cd ${folder}
    rm -rf lightberg-${folder}.zip
    npm install
    zip -r lightberg-${folder}.zip index.js package.json vars.tfvars node_modules/*
    cd ../
done
