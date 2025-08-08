#!/bin/bash

# Get metadata
read -p "What is the name of the PDF? (e.g. haja0013_lab_5): " OUTPUT
read -p "What lab number is this? (e.g. Lab 05): " LABNUM
read -p "Your full name [Hmoad Hajali]: " FULLNAME
read -p "Your email [Haja0013@algonquinlive.com]: " EMAIL
read -p "Instructor's name [Dan Chase]: " INSTRUCTOR

# Set defaults if blank
FULLNAME=${FULLNAME:-Hmoad Hajali}
EMAIL=${EMAIL:-Haja0013@algonquinlive.com}
INSTRUCTOR=${INSTRUCTOR:-Dan Chase}

# Filenames
PDF="$OUTPUT.pdf"
MARKDOWN="$OUTPUT.md"
DATE=$(date +"%b %d, %Y")  # e.g. Jul 18, 2025

# Clean old files
rm -f "$MARKDOWN" "$PDF"

# Cover page
cat <<EOF > "$MARKDOWN"
---
title: "$LABNUM"
author: |
  $FULLNAME  
  $EMAIL  
  $INSTRUCTOR  
  $DATE
date: ""
---

\newpage

# Lab Images

EOF

# Loop through PNGs (sorted, safely handles spaces)
find . -maxdepth 1 -type f -iname '*.png' | sort | while read -r img; do
  img="${img#./}"                        # Remove ./ from start of path
  caption="${img%.*}"                   # Strip .png extension
  echo "![${caption}](${img})" >> "$MARKDOWN"
  echo "" >> "$MARKDOWN"
  echo "**${caption}**" >> "$MARKDOWN"
  echo "" >> "$MARKDOWN"
  echo "\\newpage" >> "$MARKDOWN"
  echo "" >> "$MARKDOWN"
done

# Generate PDF
pandoc "$MARKDOWN" -o "$PDF" --pdf-engine=pdflatex

echo "✅ PDF created: $PDF"

