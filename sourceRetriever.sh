#!/bin/bash
testConvert() {
    mkdir tmp
    echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Package xmlns="http://soap.sforce.com/2006/04/metadata"><version>54.0</version></Package>' > tmp/package.xml
    sfdx force:mdapi:convert  -r ./tmp -d ./tmp/source
    if [[ -d "./tmp/source" ]]
    then
        rm -rf tmp
    else
        rm -rf tmp
        exit 1
    fi
    rm -rf tmp
}
retrieveSObjectDescription() {
    echo "You are requesting Metadata Description for Org: $targetOrg."
    sfdx force:mdapi:describemetadata -u "$targetOrg" -f ./output.json
    echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Package xmlns="http://soap.sforce.com/2006/04/metadata">' > package.xml
    grep -o '"xmlName": "[^"]*' output.json | grep -o '[^"]*$' > process.txt
    rm output.json
    file="process.txt"

    while read -r line; do
        echo -e "<types><members>*</members><name>$line</name></types>" >> package.xml
    done <$file
    rm $file
    echo "<version>54.0</version></Package>" >> package.xml

    sfdx force:mdapi:retrieve -u "$targetOrg" -r ./ -k ./package.xml
    rm package.xml

    unzip unpackaged.zip
    sfdx force:mdapi:convert -r ./unpackaged -d ./source
    rm unpackaged.zip
    zip -9 -r -q source.zip ./source/*
}

echo Starting...
echo Checking sfdx-cli version
echo
sfdx -v
echo
testConvert
echo "You have these connections below."
sfdx force:org:list
echo
echo
while getopts "u:" OPTION
do
   case $OPTION in
       u)
         targetOrg=$OPTARG

         retrieveSObjectDescription
         exit 0
         ;;
       ?)
         echo "ERROR: unknonw options!! ABORT!!"
         exit 1
         ;;
     esac
done
