#!/bin/bash

## EXIT CODES
# 0: Successful exit
# 1: returned help or version information
# 2: the script was given input other than one directory
# 3: a filename used by the script already exists
# 4: missing dependencies

VERSION="Imagine v1.0 by Trey Deitch. MIT Licensed."
USAGE="Usage: gallery.sh /path/to/photos/"
ABOUT="Imagine generates a static HTML photo gallery from a folder of images."
FORMATS="This script currently supports only JPEG files with a .jpg extension."
DEPENDS="Imagine requires that mogrify (part of ImageMagick) be in your path."
FOLDERSTRUCTURE="Imagine requires one folder containing images as input (no sub-folders)."
SITENAME="Trey Deitch"

# If no arguments or '--help' was passed, display the help message
if [ $# -eq 0 ] || [ $1 == "--help" ]
then
    echo $VERSION
    echo $USAGE
    echo
    echo $ABOUT
    echo $FORMATS
    echo $DEPENDS
    echo $FOLDERSTRUCTURE
    exit 1
fi

# If '--version' is passed, display the version information
if [ $1 == "--version" ]
then
    echo $VERSION
    exit 1
fi

# Check whether ImageMagick/mogrify is installed
hash mogrify 2>&- || {
    echo >&2 $DEPENDS
    exit 4
}

# Check whether sed is installed
hash sed 2>&- || {
    echo >&2 "sed is not installed in the PATH. Aborting."
    exit 4
}

# Check to verify only one folder is passed as an argument
if [ $# -gt 1 ]
then
    echo "Imagine requires only one folder as input."
    exit 2
fi

# Check to ensure that the argument is a directory
if [ -d $1 ]
then
    cd $1
    echo -n "Processing directory `pwd`: "
else
    exit 2
fi

# Verify that none of the files or directories to be created already exist
if [ -e index.html ]
then
    echo
    echo "File index.html already exists. Aborting."
    exit 3
fi

if [ -e style.css ]
then
    echo
    echo "File style.css already exists. Aborting."
    exit 3
fi

if [ -e thumbs ]
then
    echo
    echo "Directory thumbs/ already exists. Aborting."
    exit 3
fi

if [ -e medium ]
then
    echo
    echo "Directory thumbs/ already exists. Aborting."
    exit 3
fi

# Count the number of images
NUMBEROFIMAGES=0
for f in *.jpg
do
    NUMBEROFIMAGES=`expr $NUMBEROFIMAGES + 1`
done

# Get the site name and album name
echo $NUMBEROFIMAGES files found
echo "WARNING: spaces in filenames will be converted to underscores."
echo -n "Enter the album name and press [ENTER]: "
read ALBUMNAME

# Convert spaces to underscores
echo "converting spaces to underscores: "
for f in *.jpg
do
    mv -v "$f" `echo $f | tr ' ' '_' `
done

# Set the standard parts of the index.html file
echo -n "Generating index.html: "
INDEXTOP="<!DOCTYPE HTML>
<html lang=en>
<head>
<meta charset=utf-8>
<title>$SITENAME: Photos</title>
<link href=\"../../css/global.css\" rel=stylesheet type=\"text/css\">
<link href=\"../style.css\" rel=stylesheet type=\"text/css\">
<script src=\"/mint/?js\" type=\"text/javascript\"></script>
</head>
<body>
<a href=\"../../\"><h1>$SITENAME</h1></a>
<a href=\"../\"><h2>Photos</h2></a>
<h3>$ALBUMNAME</h3>
<p class=\"navigation\" title=\"all albums\"><a href=\"../\">☝</a></p>
"
INDEXBOTTOM="</body>
</html>
"

# Write out the variable part of the index.html file
NUMBEROFIMAGES=0
INDEXMIDDLE=""
for f in *.jpg
do
    if [ `expr $NUMBEROFIMAGES % 3` -eq 0 ]
    then
        INDEXMIDDLE="$INDEXMIDDLE <div class=\"left\"><a href=\"`echo ${f}|sed s/.jpg$/.html/`\"><img src=\"thumbs/${f}\"></a></div>"
    fi
    if [ `expr $NUMBEROFIMAGES % 3` -eq 1 ]
    then
        INDEXMIDDLE="$INDEXMIDDLE <div class=\"center\"><a href=\"`echo ${f}|sed s/.jpg$/.html/`\"><img src=\"thumbs/${f}\"></a></div>"
    fi
    if [ `expr $NUMBEROFIMAGES % 3` -eq 2 ]
    then
        INDEXMIDDLE="$INDEXMIDDLE <div class=\"right\"><a href=\"`echo ${f}|sed s/.jpg$/.html/`\"><img src=\"thumbs/${f}\"></a></div>"
    fi
    NUMBEROFIMAGES=`expr $NUMBEROFIMAGES + 1`
done

# No reason to overwrite; append to the file just in case
echo $INDEXTOP $INDEXMIDDLE $INDEXBOTTOM >> index.html

echo "done"

# Write the individual html pages
echo -n "Generating individual HTML pages: "
HTMLTOP="<!DOCTYPE HTML>
<html lang=en>
<head>
<meta charset=utf-8>
<title>$SITENAME: Photos</title>
<link href=\"../../css/global.css\" rel=stylesheet type=\"text/css\">
<link href=\"../style.css\" rel=stylesheet type=\"text/css\">
<script src=\"/mint/?js\" type=\"text/javascript\"></script>
</head>
<body>
<a href=\"../../\"><h1>$SITENAME</h1></a>
<a href=\"../\"><h2>Photos</h2></a>
<a href=\"./\"><h3>$ALBUMNAME</h3></a>"
HTMLBOTTOM="</body>
</html>
"
IMAGENUMBER=1
for f in *.jpg
do
    if [ $IMAGENUMBER -eq 1 ]
    then
        IMAGEONE=${f}
    fi
    if [ $IMAGENUMBER -eq 2 ]
    then
        IMAGETWO=${f}
        echo $HTMLTOP "<p class=\"navigation\">
<a href=\"./\" title=\"album overview\">☝</a>
<a href=\"`echo ${f}|sed s/.jpg$/.html/`\" title=\"next image\">☞</a></p>
<a href=\"${IMAGEONE}\" title=\"click for full-sized image\"><img src=\"medium/${IMAGEONE}\"></a>
" $HTMLBOTTOM >> `echo ${IMAGEONE}|sed s/.jpg$/.html/`
    fi
    if [ $IMAGENUMBER -gt 2 ]
    then
        echo $HTMLTOP "<p class=\"navigation\">
        <a href=\"`echo ${IMAGEONE}|sed s/.jpg$/.html/`\" title=\"previous image\">☜</a>
        <a href=\"./\" title=\"album overview\">☝</a>
        <a href=\"`echo ${f}|sed s/.jpg$/.html/`\" title=\"next image\">☞</a></p>
        <a href=\"${IMAGETWO}\" title=\"click for full-sized image\"><img src=\"medium/${IMAGETWO}\"></a>
        " $HTMLBOTTOM >> `echo ${IMAGETWO}|sed s/.jpg$/.html/`
        IMAGEONE=${IMAGETWO}
        IMAGETWO=${f}
    fi
    if [ $IMAGENUMBER -eq  $NUMBEROFIMAGES ]
    then
        echo $HTMLTOP "<p class=\"navigation\"><a href=\"`echo ${IMAGEONE}|sed s/.jpg$/.html/`\" title=\"previous image\">☜</a>
        <a href=\"./\" title=\"album overview\">☝</a></p>
        <a href=\"${f}\" title=\"click for full-sized image\"><img src=\"medium/${f}\"></a>
        " $HTMLBOTTOM >> `echo ${f}|sed s/.jpg$/.html/`
    fi
    IMAGENUMBER=`expr $IMAGENUMBER + 1`
done
IMAGENUMBER=`expr $IMAGENUMBER - 1`
echo "done"

# Generate small thumbnails
echo -n "Generating small thumbnails: "
mkdir thumbs
mogrify -path thumbs -thumbnail 200x200^ -gravity center -extent 200x200 *.jpg
echo "done"

# Generate medium thumbnails
echo -n "Generating medium thumbnails: "
mkdir medium
mogrify -path medium -thumbnail 800x *.jpg
echo "done"

echo "All done"

exit 0