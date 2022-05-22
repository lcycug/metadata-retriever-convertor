# Parameters
param(
    [Parameter()]
    [Alias("u")]
    [String]$username
)
# Variables
$checkMark = "$( [char]0x1b )[92m$( [char]8730 )"
$manifestFolder = "manifest"
$outputJson = "output.json"
$packageDotXml = "package.xml"
$packageDotXmlFooter = "<version>54.0</version></Package>"
$packageDotXmlHeader = '<?xml version="1.0" encoding="UTF-8"?><Package xmlns="http://soap.sforce.com/2006/04/metadata">'
$redX = "$( [char]0x1b )[91mx"
$sourceDotZip = "source.zip"
$sourceFolder = "source"
$tempFolder = "SourceRetrieverTemporaryFolder"
$template = "<types><members>*</members><name>line</name></types>"
$unPackagedDotZip = "unpackaged.zip"
$unPackagedFolder = "unpackaged"
# --- Main ---
Write-Output "$checkMark Listing connections..."
sfdx force:org:list
Write-Output "$checkMark Testing if in a SFDX project..."
Write-Output "$checkMark Removing the temporary folder and files if existing..."
Remove-Item $tempFolder -Recurse
Remove-Item $sourceDotZip
New-Item -ItemType Directory -Path "$tempFolder/$manifestFolder" -Force
Write-Output "$packageDotXmlHeader$packageDotXmlFooter" > "$tempFolder/$manifestFolder/$packageDotXml"
sfdx force:mdapi:convert -r "$tempFolder/$manifestFolder" -d "$tempFolder/$sourceFolder"
if (-Not(Test-Path "$tempFolder/$sourceFolder" -PathType Any))
{
    Write-Output "$redX Failed the testing..."
    exit 1
}
Write-Output "$checkMark Changing directory into the temporary one..."
Set-Location -Path $tempFolder
if ($username -eq "")
{
    sfdx force:org:display --json > $outputJson
    $jsonElements = Get-Content $outputJson -Raw | ConvertFrom-Json
    $username = $jsonElements.result.alias
    Write-Output "$checkMark Requesting metadata with the default connection: $username"
}
else
{
    Write-Output "$checkMark Requesting metadata with the given connection:  $username"
}

Write-Output "$checkMark Retrieving metadata description..."
sfdx force:mdapi:describemetadata -u $username -f $outputJson
# Writing header into package.xml
Write-Output $packageDotXmlHeader > "$manifestFolder/$packageDotXml"
# Reading metadata type into a temporary helper file
$jsonElements = Get-Content $outputJson -Raw | ConvertFrom-Json
foreach ($element in $jsonElements.metadataObjects)
{
    Write-Output ($template -replace "line", $element.xmlName) >> $packageDotXml
}
Write-Output "$checkMark Writing package footer into package.xml..."
Write-Output $packageDotXmlFooter >> $packageDotXml
Write-Output "$checkMark Retrieving metadata..."
sfdx force:mdapi:retrieve -u $username -r ./
if (Test-Path $unPackagedDotZip -PathType Any)
{
    Write-Output "$checkMark $unPackagedDotZip retrieval done."
}
else
{
    Write-Output "$checkMark $unPackagedDotZip retrieval failed."
    exit 1
}
Write-Output "$checkMark Unzipping $unPackagedDotZip into $unPackagedFolder folder..."
Expand-Archive -Path $unPackagedDotZip -DestinationPath $unPackagedFolder
Write-Output "$checkMark Converting metadata into source format..."
sfdx force:mdapi:convert -r $unPackagedFolder -d $sourceFolder
Write-Output "$checkMark Zipping $sourceFolder files into $sourceDotZip..."
Compress-Archive -Path $sourceFolder -DestinationPath $sourceDotZip
Copy-Item $sourceDotZip -Destination ./../
Set-Location -Path ./../
Write-Output "$checkMark Removing the temporary folder..."
Remove-Item $tempFolder -Recurse
Write-Output "$checkMark Metdata retrieval done."
exit 0