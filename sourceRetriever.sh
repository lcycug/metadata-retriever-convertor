#!/bin/bash
# variables
temp="temp"
source="source"
outputJson="output.json"
unPackaged="unpackaged"
packageDotXml="package.xml"
packageDotXmlHelper="process.txt"
packageDotXmlFooter="<version>54.0</version></Package>"
template="<types><members>*</members><name>line</name></types>"
packageDotXmlHeader="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><Package xmlns=\"http://soap.sforce.com/2006/04/metadata\">"
# --- Main ---
echo "Starting..."
echo "Checking sfdx-cli version"
sfdx -v
echo "Testing if in a SFDX folder"
mkdir $temp
echo "$packageDotXmlHeader$packageDotXmlFooter" >"$temp/$packageDotXml"
sfdx force:mdapi:convert -r $temp -d "$temp/$source"
if [ -d "$temp/$source" ]; then
    rm -rf $temp
else
    rm -rf $temp
    exit 1
fi
echo "Listing connections"
sfdx force:org:list
# options
while getopts "u:" OPTION; do
    case $OPTION in
    u)
        targetOrg=$OPTARG
        ;;
    ?)
        echo "ERROR: unknown options!! ABORT!!"
        exit 1
        ;;
    esac
done
# getting the default org if no one is given
if [ "$targetOrg" == "" ]; then
    sfdx force:org:display --json >$outputJson
    targetOrg=$(grep -o '"alias": "[^"]*' "./${outputJson}" | grep -o '[^"]*$')
    echo "Requesting metadata with the default connection: $targetOrg"
else
    echo "Requesting metadata with the given connection:  $targetOrg"
fi
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
# writing footer into package.xml
echo "${packageDotXmlFooter}" >>"${packageDotXml}"
# retrieving metadata
sfdx force:mdapi:retrieve -u "${targetOrg}" -r ./ -k "${packageDotXml}"
# removing package.xml
rm "${packageDotXml}"
# identifying if the unpackaged.zip file is retrieved
if test -f "${unPackaged}.zip"; then
    echo "unpackaged.zip retrieved."
else
    echo "unpackaged.zip retrieval failed."
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
zip -9 -r -q "${source}.zip" . -i "${source}/*"
# removing source folder
rm -rf "${source}"
echo "Metadata retrieval done."
exit 0
