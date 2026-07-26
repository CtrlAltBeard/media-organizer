#!/bin/bash

# =============================================
# Reorganize Existing Files Script
# Re-sorts files already in the "organized" folder by date.
# Usage: Edit the paths below, then run: bash reorganize_existing.sh
# =============================================

# --- CONFIGURATION (EDIT THESE PATHS) ---
ORGANIZED="/path/to/your/media/organized"    # Folder with existing organized files
DUPLICATES="/path/to/your/media/duplicates"  # Blurry/corrupt images go here
LOG_FILE="/path/to/your/reorganize_existing.log"  # Log file path

# --- Create directories ---
mkdir -p "$ORGANIZED" "$DUPLICATES"

# --- Logging ---
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# --- Validate year (must be >= 2000) ---
validate_year() {
    local year="$1"
    local current_year
    current_year=$(date +%Y)
    if [[ "$year" =~ ^[0-9]{4}$ ]] && [ "$year" -ge 2000 ] && [ "$year" -le "$current_year" ]; then
        echo "$year"
    else
        echo ""
    fi
}

# --- Extract date from filename ---
get_date_from_filename() {
    local filename="$1"
    local date_part
    date_part=$(echo "$filename" | grep -oE '[0-9]{8}')
    if [ -n "$date_part" ]; then
        local year
        year="${date_part:0:4}"
        local month_num
        month_num="${date_part:4:2}"
        local validated_year
        validated_year=$(validate_year "$year")
        if [ -n "$validated_year" ]; then
            echo "$validated_year $month_num"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

# --- Extract date from metadata ---
get_date() {
    local filepath="$1"
    local filename
    filename=$(basename "$filepath")

    local date_from_name
    date_from_name=$(get_date_from_filename "$filename")
    if [ -n "$date_from_name" ]; then
        echo "$date_from_name"
        return
    fi

    local exif_date
    exif_date=$(exiftool -s3 -DateTimeOriginal "$filepath" 2>/dev/null)
    if [ -n "$exif_date" ]; then
        local date_part
        date_part=$(echo "$exif_date" | cut -d' ' -f1 | tr ':' '-')
        local year
        year=$(echo "$date_part" | cut -d'-' -f1)
        local month_num
        month_num=$(echo "$date_part" | cut -d'-' -f2)
        local validated_year
        validated_year=$(validate_year "$year")
        if [ -n "$validated_year" ]; then
            echo "$validated_year $month_num"
        else
            echo ""
        fi
        return
    fi

    exif_date=$(exiftool -s3 -CreateDate "$filepath" 2>/dev/null)
    if [ -n "$exif_date" ]; then
        local date_part
        date_part=$(echo "$exif_date" | cut -d' ' -f1 | tr ':' '-')
        local year
        year=$(echo "$date_part" | cut -d'-' -f1)
        local month_num
        month_num=$(echo "$date_part" | cut -d'-' -f2)
        local validated_year
        validated_year=$(validate_year "$year")
        if [ -n "$validated_year" ]; then
            echo "$validated_year $month_num"
        else
            echo ""
        fi
        return
    fi

    local mod_time
    mod_time=$(stat -c %Y "$filepath" 2>/dev/null)
    if [ -n "$mod_time" ]; then
        local year
        year=$(date -d "@$mod_time" +"%Y" 2>/dev/null)
        local month_num
        month_num=$(date -d "@$mod_time" +"%m" 2>/dev/null)
        local validated_year
        validated_year=$(validate_year "$year")
        if [ -n "$validated_year" ]; then
            echo "$validated_year $month_num"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

# --- Convert month number to month name ---
get_month_name() {
    local month_num="$1"
    case "$month_num" in
        01|1) echo "01. January" ;;
        02|2) echo "02. February" ;;
        03|3) echo "03. March" ;;
        04|4) echo "04. April" ;;
        05|5) echo "05. May" ;;
        06|6) echo "06. June" ;;
        07|7) echo "07. July" ;;
        08|8) echo "08. August" ;;
        09|9) echo "09. September" ;;
        10) echo "10. October" ;;
        11) echo "11. November" ;;
        12) echo "12. December" ;;
        *) echo "$month_num" ;;
    esac
}

# --- Process a single file ---
process_file() {
    local filepath="$1"
    local filename
    filename=$(basename "$filepath")

    # Skip hidden files and non-media files
    if [[ "$filename" == .* ]]; then
        return
    fi
    if [[ ! "$filename" =~ \.(jpg|jpeg|png|gif|3gp|mp4|mov|avi|mkv|JPG|JPEG|PNG|GIF|MP4|MOV|AVI|MKV)$ ]]; then
        return
    fi

    # Get date
    local date_str
    date_str=$(get_date "$filepath")
    local year
    year=$(echo "$date_str" | awk '{print $1}')
    local month_num
    month_num=$(echo "$date_str" | awk '{print $2}')

    if [ -z "$year" ]; then
        year="notime"
    fi
    if [ -z "$month_num" ]; then
        month_num="00"
    fi

    # Move the file to "Year/Month Name/"
    local month_name
    month_name=$(get_month_name "$month_num")
    local dest_dir="$ORGANIZED/${year}/${month_name}"
    mkdir -p "$dest_dir"
    if ! mv "$filepath" "$dest_dir/"; then
        echo "Failed to move: $filename" | tee -a "$LOG_FILE"
    else
        echo "Reorganized: $filename -> $dest_dir/"
    fi
}

# --- Main workflow ---
log "=== Reorganize Existing Files Script started ==="
find "$ORGANIZED" -type f -print0 | while IFS= read -r -d '' filepath; do
    process_file "$filepath"
done
log "Cleaning up empty folders..."
find "$ORGANIZED" -depth -type d -empty -exec rmdir {} + 2>/dev/null
log "=== Reorganize Existing Files Script completed ==="
