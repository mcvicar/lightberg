#!/bin/bash

cd lambda/
for folder in $(ls ./); do
    echo "Building ${folder}"
    cp ../vars.tfvars ${folder}
    cd ${folder}
    rm -rf ${folder}.zip
    npm install
    zip -r ${folder}.zip index.js package.json node_modules/*
    cd ../
done
