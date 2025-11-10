#!/usr/bin/env bash

# Check dependencies
command -v zenity >/dev/null 2>&1 || { echo "Please install zenity (sudo apt install zenity)"; exit 1; }
command -v extract-xiso >/dev/null 2>&1 || { echo "Please install extract-xiso first."; exit 1; }
command -v pv >/dev/null 2>&1 || { echo "Please install pv (sudo apt install pv)"; exit 1; }

# Select ISOs
ISOS=$(zenity --file-selection --multiple --title="Select up to 7 Xbox 360 ISOs" --file-filter="*.iso" --separator="|")
[ -z "$ISOS" ] && exit

# Select destination folder
DEST=$(zenity --file-selection --directory --title="Select destination folder")
[ -z "$DEST" ] && exit

# Extract each ISO
IFS='|' read -r -a ISO_ARRAY <<< "$ISOS"
for ISO in "${ISO_ARRAY[@]}"; do
    BASENAME=$(basename "$ISO" .iso)
    OUTDIR="$DEST/$BASENAME"
    mkdir -p "$OUTDIR"

    # Estimate ISO size for progress
    SIZE=$(stat -c%s "$ISO")

    (
        extract-xiso -x "$ISO" -d "$OUTDIR" | pv -n -s "$SIZE" > /dev/null
        echo 100
    ) |
    zenity --progress --title="Extracting $BASENAME..." \
           --percentage=0 \
           --auto-close \
           --auto-kill \
           --width=400 \
           --height=100

    if [ $? -ne 0 ]; then
        zenity --warning --text="Extraction cancelled. Removing $OUTDIR..."
        rm -rf "$OUTDIR"
        exit 1
    fi
done

zenity --info --text="All extractions completed!"


