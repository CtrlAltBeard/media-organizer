#!/bin/bash

# =============================================
# Media Organizer Script (Safe Mode + Rotation)
# Organizes AND rotates photos/videos by date into Year/Month folders.
# Files are NEVER deleted—only moved and rotated in-place.
#
# Usage:
#   1. Edit the CONFIGURATION section below to set your paths.
#   2. Run: chmod +x auto_organize_all.sh
#   3. Run: ./auto_organize_all.sh
#
# Dependencies:
#   - exiftool (for date extraction and image rotation)
#   - ffmpeg (for video rotation and HEIC support)
#
# Install dependencies (Ubuntu/Debian):
#   sudo apt update
#   sudo apt install -y libimage-exiftool-perl ffmpeg
# =============================================

# --- CONFIGURATION (EDIT THESE) ---
# Set these to your actual folder paths (no trailing slashes)
INBOX="/path/to/your/media/to-be-sorted"    # Folder with unsorted media
ORGANIZED="/path/to/your/media/organized"    # Output folder for sorted media
LOG_FILE="/path/to/your/media_organizer.log" # Log file path

# --- Create directories ---
mkdir -p "$INBOX" "$ORGANIZED" "/tmp/ffmpeg_logs"

# --- Logging ---
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# --- Validate year (must be >= 2000) ---
validate_year() {
    local year="$1"
    local current_year=$(date +%Y)
    if [[ "$year" =~ ^[0-9]{4}$ ]] && [ "$year" -ge 2000 ] && [ "$year" -le "$current_year" ]; then
        echo "$year"
    else
        echo ""
    fi
}

# --- Extract date from filename (e.g., 20230101_photo.jpg) ---
get_date_from_filename() {
    local filename="$1"
    local date_part=$(echo "$filename" | grep -oE '[0-9]{8}')
    if [ -n "$date_part" ]; then
        local year="${date_part:0:4}"
        local month_num="${date_part:4:2}"
        local validated_year=$(validate_year "$year")
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
    local filename=$(basename "$filepath")
    local date_from_name=$(get_date_from_filename "$filename")
    [ -n "$date_from_name" ] && { echo "$date_from_name"; return; }

    # Try EXIF metadata (DateTimeOriginal)
    if command -v exiftool &>/dev/null; then
        local exif_date=$(exiftool -s3 -DateTimeOriginal "$filepath" 2>/dev/null)
        if [ -n "$exif_date" ]; then
            local date_part=$(echo "$exif_date" | cut -d' ' -f1 | tr ':' '-')
            local year=$(echo "$date_part" | cut -d'-' -f1)
            local month_num=$(echo "$date_part" | cut -d'-' -f2)
            local validated_year=$(validate_year "$year")
            [ -n "$validated_year" ] && { echo "$validated_year $month_num"; return; }
        fi

        # Try CreateDate if DateTimeOriginal fails
        exif_date=$(exiftool -s3 -CreateDate "$filepath" 2>/dev/null)
        if [ -n "$exif_date" ]; then
            local date_part=$(echo "$exif_date" | cut -d' ' -f1 | tr ':' '-')
            local year=$(echo "$date_part" | cut -d'-' -f1)
            local month_num=$(echo "$date_part" | cut -d'-' -f2)
            local validated_year=$(validate_year "$year")
            [ -n "$validated_year" ] && { echo "$validated_year $month_num"; return; }
        fi
    fi

    # Fallback: Use file modification time
    local mod_time=$(stat -c %Y "$filepath" 2>/dev/null)
    if [ -n "$mod_time" ]; then
        local year=$(date -d "@$mod_time" +"%Y" 2>/dev/null)
        local month_num=$(date -d "@$mod_time" +"%m" 2>/dev/null)
        local validated_year=$(validate_year "$year")
        [ -n "$validated_year" ] && echo "$validated_year $month_num" || echo ""
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

# --- Rotate image based on EXIF Orientation tag ---
# Orientation values:
# 1 = Normal
# 5 = 90° CW + Mirror (rare)
# 6 = 90° CW
# 7 = 90° CCW + Mirror (rare)
# 8 = 90° CCW
rotate_image() {
    local filepath="$1"
    if ! command -v exiftool &>/dev/null; then
        echo "WARNING: exiftool not installed. Skipping rotation for $filepath." | tee -a "$LOG_FILE"
        return
    fi

    local orientation=$(exiftool -s3 -Orientation -n "$filepath" 2>/dev/null)
    case "$orientation" in
        5|6|7|8)
            echo "Rotating image (Orientation=$orientation): $filepath" | tee -a "$LOG_FILE"
            if exiftool -n -Orientation=1 -overwrite_original "$filepath" 2>/dev/null; then
                echo "Rotated: $filepath" | tee -a "$LOG_FILE"
            else
                echo "ERROR: Failed to rotate $filepath" | tee -a "$LOG_FILE"
            fi
            ;;
        *)
            # No rotation needed (Orientation=1 or missing)
            ;;
    esac
}

# --- Rotate video based on metadata (if needed) ---
rotate_video() {
    local filepath="$1"
    if ! command -v ffmpeg &>/dev/null; then
        echo "WARNING: ffmpeg not installed. Skipping rotation for $filepath." | tee -a "$LOG_FILE"
        return
    fi

    # Check for rotation metadata in video
    local rotation=$(ffprobe -v error -select_streams v:0 -show_entries stream_tags=rotate -of default=noprint_wrappers=1:nokey=1 "$filepath" 2>/dev/null)
    if [ -n "$rotation" ] && [ "$rotation" != "0" ]; then
        echo "Rotating video (rotation=$rotation): $filepath" | tee -a "$LOG_FILE"
        local temp_output="/tmp/rotated_$(basename \"$filepath\")"
        if ffmpeg -i "$filepath" -vf "transpose=$rotation" -y "$temp_output" >> "/tmp/ffmpeg_logs/$(basename \"$filepath\").log" 2>&1; then
            mv "$temp_output" "$filepath"
            echo "Rotated: $filepath" | tee -a "$LOG_FILE"
        else
            echo "ERROR: Failed to rotate $filepath" | tee -a "$LOG_FILE"
            rm -f "$temp_output" 2>/dev/null
        fi
    fi
}

# --- Process a single file ---
process_file() {
    local filepath="$1"
    local filename=$(basename "$filepath")

    # Skip hidden files (e.g., .DS_Store, .thumbnails)
    if [[ "$filename" == .* ]]; then
        return
    fi

    # Supported file extensions (add/remove as needed)
    if [[ ! "$filename" =~ \.(jpg|jpeg|png|gif|heic|3gp|mp4|mov|avi|mkv|JPG|JPEG|PNG|GIF|HEIC|MP4|MOV|AVI|MKV)$ ]]; then
        return
    fi

    # Rotate images/videos if needed
    if [[ "$filename" =~ \.(jpg|jpeg|png|gif|heic|JPG|JPEG|PNG|GIF|HEIC)$ ]]; then
        rotate_image "$filepath"
    elif [[ "$filename" =~ \.(3gp|mp4|mov|avi|mkv|MP4|MOV|AVI|MKV)$ ]]; then
        rotate_video "$filepath"
    fi

    # Get date
    local date_str=$(get_date "$filepath")
    local year=$(echo "$date_str" | awk '{print $1}')
    local month_num=$(echo "$date_str" | awk '{print $2}')

    # Default to "notime/00" if no date found
    if [ -z "$year" ]; then
        year="notime"
    fi
    if [ -z "$month_num" ]; then
        month_num="00"
    fi

    # Move the file to "Year/Month Name/"
    local month_name=$(get_month_name "$month_num")
    local dest_dir="$ORGANIZED/${year}/${month_name}"
    mkdir -p "$dest_dir"

    # Move file (log success/failure)
    if mv "$filepath" "$dest_dir/"; then
        echo "Organized: $filename -> $dest_dir/" | tee -a "$LOG_FILE"
    else
        echo "ERROR: Failed to move $filepath to $dest_dir/" | tee -a "$LOG_FILE"
    fi
}

# --- Main workflow ---
log "=== Script started ==="
find "$INBOX" -type f -print0 | while IFS= read -r -d '' filepath; do
    process_file "$filepath"
done

# Clean up empty folders in to-be-sorted (EXCLUDING the root folder)
log "Cleaning up empty folders..."
find "$INBOX" -mindepth 1 -type d -empty -exec rmdir -v {} + 2>/dev/null
log "=== Script completed ==="