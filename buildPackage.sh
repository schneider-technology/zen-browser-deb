#!/bin/bash

#Check if file exists, stop if it doesn't
if [ ! -f "zen.linux-x86_64.tar.xz" ]; then
    echo "Error: zen.linux-x86_64.tar.xz not found"
    exit 1
fi

#Define the package directory
packageDirectory="zen-browser"
binaryName="zen-browser"

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
mkdir -p "$packageDirectory/usr/share/applications"
mkdir -p "$packageDirectory/DEBIAN"
mkdir -p "$packageDirectory/usr/local/bin"
mkdir -p "$packageDirectory/usr/share/icons/"

#Extract the tarball to zen-browser directory
tar -xvf zen.linux-x86_64.tar.xz -C "$packageDirectory/usr/local/bin" || { echo "Error extracting tarball"; exit 1; }

#rename zen to binaryName to avoid conflicts
mv "$packageDirectory/usr/local/bin/zen" "$packageDirectory/usr/local/bin/$binaryName"
mv "$packageDirectory/usr/local/bin/$binaryName/zen" "$packageDirectory/usr/local/bin/$binaryName/$binaryName"
mv "$packageDirectory/usr/local/bin/$binaryName/zen-bin" "$packageDirectory/usr/local/bin/$binaryName/$binaryName-bin"

#chmod the binary
chmod +x "$packageDirectory/usr/local/bin/$binaryName/$binaryName"

#Check the version application.ini
version=$(grep -oP 'Version=\K.*' "$packageDirectory/usr/local/bin/$binaryName/application.ini" | head -1)

if [ -z "$version" ]; then
    echo "Error: Version not found in application.ini"
    exit 1
fi

echo "Version: $version"

#Copy control file to $packageDirectory/DEBIAN and add the version
cp "customFiles/DEBIAN/control" "$packageDirectory/DEBIAN/control"
sed -i "s/Version: .*/Version: $version/" "$packageDirectory/DEBIAN/control"

#Copy the desktop file to $packageDirectory/usr/share/applications and add the version
cp "customFiles/$binaryName.desktop" "$packageDirectory/usr/share/applications/$binaryName.desktop"
sed -i "s/Version=.*/Version=$version/" "$packageDirectory/usr/share/applications/$binaryName.desktop"

#replace binaryName in the desktop file
sed -i "s|Exec=.*|Exec=/usr/local/bin/$binaryName %U|" "$packageDirectory/usr/share/applications/$binaryName.desktop"

#Check which sizes are available and create the directories and rename the files
for each in "$packageDirectory/usr/local/bin/$binaryName/browser/chrome/icons/default/"*; do
    size=$(basename "$each" | grep -oP '\d+')
    mkdir -p "$packageDirectory/usr/share/icons/hicolor/${size}x${size}/apps/"
    cp "$each" "$packageDirectory/usr/share/icons/hicolor/${size}x${size}/apps/$binaryName.png"
done

#Delete old icon directory
rm -rf "$packageDirectory/usr/local/bin/$binaryName/browser/chrome/icons/default"

#Delete the updater since debian packages are updated through apt
rm "$packageDirectory/usr/local/bin/$binaryName/updater"
rm "$packageDirectory/usr/local/bin/$binaryName/updater.ini"

#Create the deb package
dpkg-deb --build "$packageDirectory"

# Check if the deb package was created successfully
if [ ! -f "$packageDirectory.deb" ]; then
    echo "Error: Failed to create deb package"
    exit 1
fi

#Rename the deb package
echo "Renaming to zen-browser_$version.deb"
mv "$packageDirectory.deb" "zen-browser_$version.deb"
