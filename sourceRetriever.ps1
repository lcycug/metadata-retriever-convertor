# Parameters
param(
    [Parameter()]
    [Alias("u")]
    [String]$username,
    [Alias("e")]
    [String]$emotion
)
# Variables
$tempFolder = "temp"
$sourceFolder = "source"
$sourceDotZip = "source.zip"
$outputJson = "output.json"
$unPackagedFolder = "unpackaged"
$unPackagedDotZip = "unpackaged.zip"
$packageDotXml = "package.xml"
$packageDotXmlFooter = "<version>54.0</version></Package>"
$template = "<types><members>*</members><name>line</name></types>"
$packageDotXmlHeader = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Package xmlns="http://soap.sforce.com/2006/04/metadata">'
# Functions
function Test-Convert
{
    mkdir $tempFolder
    Write-Output "$packageDotXmlHeader$packageDotXmlFooter" > "$tempFolder/$packageDotXml"
    sfdx force:mdapi:convert -r $tempFolder -d "$tempFolder/$sourceFolder"
    if (Test-Path "$tempFolder/$sourceFolder" -PathType Any)
    {
        rm -rf $tempFolder
    }
    else
    {
        rm -rf $tempFolder
        exit 1
    }
}
# --- Main ---
# Listing connections
sfdx force:org:list
# Testing if in a SFDX project
Test-Convert
# Retrieving metadata description
sfdx force:mdapi:describemetadata -u $username -f $outputJson
# Writing header into package.xml
Write-Output $packageDotXmlHeader > $packageDotXml
# Reading metadata type into a temporary helper file
$jsonElements = Get-Content $outputJson -Raw | ConvertFrom-Json
foreach ($element in $jsonElements.metadataObjects)
{
    Write-Output ($template -replace "line", $element.xmlName) >> $packageDotXml
}
rm $outputJson
# Writing package footer into package.xml
Write-Output $packageDotXmlFooter >> $packageDotXml
# Retrieving metadata
sfdx force:mdapi:retrieve -u $username -r ./ -k $packageDotXml
# Removing package.xml
rm $packageDotXml
if (Test-Path $unPackagedDotZip -PathType Any)
{
    Write-Output "Unpackaged.zip retrieval done."
}
else
{
    Write-Output "Unpackaged.zip retrieval failed."
    exit 1
}
# Unzipping unpackaged.zip into unpackaged folder
Expand-Archive -Path $unPackagedDotZip -DestinationPath $unPackagedFolder
# Converting metadata into source format
sfdx force:mdapi:convert -r $unPackagedFolder -d $sourceFolder
rm $unPackagedDotZip
rm -rf $unPackagedFolder
# Zippping source files into source.zip
Compress-Archive -Path $sourceFolder -DestinationPath $sourceDotZip
rm -rf $sourceFolder
