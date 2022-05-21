#!/bin/bash
# variables
temp="temp"
source="source"
checkMark="\xE2\x9C\x94 "
outputJson="output.json"
unPackaged="unpackaged"
packageDotXml="package.xml"
packageDotXmlHelper="process.txt"
packageDotXmlFooter="<version>54.0</version></Package>"
template="<types><members>*</members><name>line</name></types>"
packageDotXmlHeader="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><Package xmlns=\"http://soap.sforce.com/2006/04/metadata\">"
# tell if a given folder is existing
isFolderExisting() {
    if [[ -d $1 ]]; then
        return 1
    else
        return 0
    fi
}
# test if convertable
testConvert() {
    mkdir "${temp}"
    echo "${packageDotXmlHeader}${packageDotXmlFooter}" >"${temp}/${packageDotXml}"
    sfdx force:mdapi:convert -r "./${temp}" -d "./${temp}/${source}"
    isFolderExisting "${temp}/${source}"
    if [ $? ]; then
        rm -rf "${temp}"
    else
        rm -rf "${temp}"
        exit 1
    fi
    rm -rf "${temp}"
}
# retrieve metadata from a given target org
retrieveMetadata() {
    # retrieving metadata description
    sfdx force:mdapi:describemetadata -u "${targetOrg}" -f "./${outputJson}"
    # writing header into package.xml
    echo "${packageDotXmlHeader}" >"${packageDotXml}"
    # reading metadata type into a temporary helper file
    grep -o '"xmlName": "[^"]*' "./${outputJson}" | grep -o '[^"]*$' >"${packageDotXmlHelper}"
    # removing output.json
    rm output.json
    # reading the helper file into package.xml
    while read -r line; do
        # read each metadata type with prefix and suffix from the helper file
        echo "${template//line/$line}" >>${packageDotXml}
    done <${packageDotXmlHelper}
    # removing the helper
    rm ${packageDotXmlHelper}
    # wring footer into package.xml
    echo "${packageDotXmlFooter}" >>"${packageDotXml}"
    # retrieving metadata
    sfdx force:mdapi:retrieve -u "${targetOrg}" -r ./ -k "${packageDotXml}"
    # removing package.xml
    rm "${packageDotXml}"
    isFolderExisting "${temp}/${source}"
    # identifying if the unpackaged.zip file is retrieved
    if [ $? ]; then
        echo -e "${checkMark}unpackage.zip retrieved."
    else
        echo "unpackage.zip retrieval failed."
        exit 1
    fi
    # unzipping the unpackage.zip file
    unzip "${unPackaged}.zip"
    # converting metadata to source
    sfdx force:mdapi:convert -r "${unPackaged}" -d "${source}"
    # removing unpackage.zip file
    rm "${unPackaged}.zip"
    # removing unpackage temporary folder
    rm -rf "${unPackaged}"
    # zipping source folder
    zip -9 -r -q "${source}.zip" .-i "${source}/*"
    # removing source folder
    rm -rf "${source}"
}

echo "Starting..."
echo -e "${checkMark}Checking sfdx-cli version"
sfdx -v
echo -e "${checkMark}Testing if in a SFDX folder"
testConvert
echo -e "${checkMark}Listing connections"
sfdx force:org:list
# options
while getopts "u:" OPTION; do
    case $OPTION in
    u)
        targetOrg=$OPTARG
        retrieveMetadata
        exit 0
        ;;
    ?)
        echo "ERROR: unknown options!! ABORT!!"
        exit 1
        ;;
    esac
done
echo -e "${checkMark}Finished"
