#!/bin/bash

#Check if file exists, stop if it doesn't
if [ ! -f "zen.linux-x86_64.tar.xz" ]; then
    echo "Error: zen.linux-x86_64.tar.xz not found"
    exit 1
fi

#Define the package directory
packageDirectory="zen-browser"
binaryName="zen-browser"
binaryDirectory="$packageDirectory/usr/bin"
appRootDirectory="$packageDirectory/usr/lib"
appDirectory="$appRootDirectory/$binaryName"
iconDirectory="$packageDirectory/usr/share/icons"
desktopFileDirectory="$packageDirectory/usr/share/applications"
debianFileDirectory="$packageDirectory/DEBIAN"

#make sure the package directory is set so you don't delete the wrong directory
if [ -z "$packageDirectory" ]; then
    echo "Error: packageDirectory not set"
    exit 1
fi

#Check if zen-browser directory exists, delete it if it does
if [ -d "$packageDirectory" ]; then
    rm -rf "$packageDirectory"
fi

#Create the initial directories
mkdir -p "$desktopFileDirectory"
mkdir -p "$debianFileDirectory"
mkdir -p "$appRootDirectory"
mkdir -p "$iconDirectory"
mkdir -p "$binaryDirectory"

#Extract the tarball to zen-browser directory
echo "Extracting tarball to $appRootDirectory"
tar -xvf zen.linux-x86_64.tar.xz -C "$appRootDirectory" || { echo "Error extracting tarball"; exit 1; }

# Check if extraction was successful
if [ ! -d "$appRootDirectory/zen" ]; then
    echo "Error: Extraction failed or zen directory not found in $appRootDirectory"
    exit 1
fi

# List contents of the extracted directory for debugging
echo "Contents of $appRootDirectory after extraction:"
ls -l "$appRootDirectory"

#move and rename zen to binaryName to avoid conflicts
echo "Moving and renaming zen to $binaryName"
mv "$appRootDirectory/zen" "$appDirectory"
mv "$appDirectory/zen" "$appDirectory/$binaryName"
mv "$appDirectory/zen-bin" "$appDirectory/$binaryName-bin"

#chmod the binary
chmod +x "$appDirectory/$binaryName"

#create relative symlinks
ln -s "../lib/$binaryName/$binaryName" "$binaryDirectory/$binaryName"
ln -s "../lib/$binaryName/$binaryName-bin" "$binaryDirectory/$binaryName-bin"

#Check the version application.ini
applicationDirectory="$appDirectory"
version=$(grep -oP 'Version=\K.*' "$applicationDirectory/application.ini" | head -1)

if [ -z "$version" ]; then
    echo "Error: Version not found in application.ini"
    exit 1
fi

echo "Version: $version"

#Copy control file to $packageDirectory/DEBIAN and add the version
cp "customFiles/DEBIAN/control" "$debianFileDirectory/control"
sed -i "s/Version: .*/Version: $version/" "$debianFileDirectory/control"

#Copy the desktop file to $desktopFileDirectory and add the version
cp "customFiles/$binaryName.desktop" "$desktopFileDirectory/$binaryName.desktop"
sed -i "s/Version=.*/Version=$version/" "$desktopFileDirectory/$binaryName.desktop"

#replace binaryName in the desktop file
sed -i "s|Exec=.*|Exec=/usr/lib/$binaryName/$binaryName %U|" "$desktopFileDirectory/$binaryName.desktop"

#Check which sizes are available and create the directories and rename the files
for each in "$appDirectory/browser/chrome/icons/default/"*; do
    size=$(basename "$each" | grep -oP '\d+')
    mkdir -p "$iconDirectory/hicolor/${size}x${size}/apps/"
    cp "$each" "$iconDirectory/hicolor/${size}x${size}/apps/$binaryName.png"
done

#Delete old icon directory
rm -rf "$appDirectory/browser/chrome/icons/default"

#Delete the updater since debian packages are updated through apt
#rm "$appDirectory/updater"
#rm "$appDirectory/updater.ini"

#Create the deb package
dpkg-deb --build "$packageDirectory"

# Check if the deb package was created successfully
if [ ! -f "$packageDirectory.deb" ]; then
    echo "Error: Failed to create deb package"
    exit 1
fi

#Rename the deb package
echo "Renaming to $binaryName_$version.deb"
mv "$packageDirectory.deb" "${binaryName}_${version}.deb"
