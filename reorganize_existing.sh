#!/bin/bash
# =============================================
# Reorganize Existing Files Script
# Re-sorts files already in the "organized" folder.
# Usage: Edit the paths below, then run: bash reorganize_existing.sh
# =============================================

# --- CONFIGURATION (EDIT THESE PATHS) ---
ORGANIZED="/path/to/your/media/organized"    # Folder with existing organized files
DUPLICATES="/path/to/your/media/duplicates"  # Blurry/corrupt images go here
TEMP_DIR="/tmp/handbrake_temp"                # Temp files for conversion
TIMEOUT=120                                    # Timeout in seconds per video
LOG_FILE="/path/to/your/reorganize_existing.log"  # Log file path

# --- Create directories ---
mkdir -p "$ORGANIZED" "$DUPLICATES" "$TEMP_DIR" "/tmp/ffmpeg_logs"

# --- Logging ---
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# --- Validate year (must be >= 2000) ---
validate_year() {
    local year="$1" current_year=$(date +%Y)
    [[ "$year" =~ ^[0-9]{4}$ ]] && [ "$year" -ge 2000 ] && [ "$year" -le "$current_year" ] && echo "$year" || echo ""
}

# --- Extract date from filename ---
get_date_from_filename() {
    local filename="$1" date_part=$(echo "$filename" | grep -oE '[0-9]{8}')
    [ -n "$date_part" ] && {
        local year="${date_part:0:4}" month_num="${date_part:4:2}" validated_year=$(validate_year "$year")
        [ -n "$validated_year" ] && echo "$validated_year $month_num" || echo ""
    } || echo ""
}

# --- Extract date from metadata ---
get_date() {
    local filepath="$1" filename=$(basename "$filepath")
    local date_from_name=$(get_date_from_filename "$filename")
    [ -n "$date_from_name" ] && { echo "$date_from_name"; return; }

    local exif_date=$(exiftool -s3 -DateTimeOriginal "$filepath" 2>/dev/null)
    [ -n "$exif_date" ] && {
        local date_part=$(echo "$exif_date" | cut -d' ' -f1 | tr ':' '-')
        local year=$(echo "$date_part" | cut -d'-' -f1) month_num=$(echo "$date_part" | cut -d'-' -f2)
        local validated_year=$(validate_year "$year")
        [ -n "$validated_year" ] && { echo "$validated_year $month_num"; return; }
    }

    exif_date=$(exiftool -s3 -CreateDate "$filepath" 2>/dev/null)
    [ -n "$exif_date" ] && {
        local date_part=$(echo "$exif_date" | cut -d' ' -f1 | tr ':' '-')
        local year=$(echo "$date_part" | cut -d'-' -f1) month_num=$(echo "$date_part" | cut -d'-' -f2)
        local validated_year=$(validate_year "$year")
        [ -n "$validated_year" ] && { echo "$validated_year $month_num"; return; }
    }

    local mod_time=$(stat -c %Y "$filepath" 2>/dev/null)
    [ -n "$mod_time" ] && {
        local year=$(date -d "@$mod_time" +"%Y" 2>/dev/null) month_num=$(date -d "@$mod_time" +"%m" 2>/dev/null)
        local validated_year=$(validate_year "$year")
        [ -n "$validated_year" ] && echo "$validated_year $month_num" || echo ""
    } || echo ""
}

# --- Convert month number to name ---
get_month_name() {
    case "$1" in
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
        *) echo "$1" ;;
    esac
}

# --- Check if image is blurry ---
is_blurry() {
    local filepath="$1" tmpfile=$(mktemp).jpg
    darktable-cli "$filepath" "$tmpfile" >/dev/null 2>&1
    [ $? -ne 0 ] && { rm "$tmpfile" 2>/dev/null; return 0; } || { rm "$tmpfile" 2>/dev/null; return 1; }
}

# --- Auto-enhance images ---
auto_enhance() {
    local filepath="$1"
    command -v darktable-cli &>/dev/null && {
        local tmpfile=$(mktemp).jpg
        darktable-cli "$filepath" "$tmpfile" >/dev/null 2>&1
        [ $? -eq 0 ] && mv "$tmpfile" "$filepath"
        rm -f "$tmpfile" 2>/dev/null
        [ $? -eq 0 ] && echo "Auto-enhancing with Darktable: $filepath"
    }
}

# --- Convert video to MP4 (4 fallback strategies) ---
convert_video() {
    local filepath="$1" filename=$(basename "$filepath") dir=$(dirname "$filepath") base="${filename%.*}"
    local temp_output="$TEMP_DIR/${base}.mp4" new_filepath="$dir/${base}.mp4"
    local log_file="/tmp/ffmpeg_logs/${base}.log"

    # Strategy 0: Pre-check for corruption
    ffmpeg -v error -i "$filepath" >"$log_file" 2>&1
    if [ $? -ne 0 ]; then
        echo "Skipping corrupted file: $filename" | tee -a "$LOG_FILE"
        return 1
    fi

    # Strategy 1: HandBrakeCLI (preferred)
    echo "Converting to MP4: $filename (HandBrakeCLI)" | tee -a "$LOG_FILE"
    if timeout $TIMEOUT /usr/bin/HandBrakeCLI -i "$filepath" -o "$temp_output" -e x264 -q 28 -2 >> "$log_file" 2>&1; then
        [ -f "$temp_output" ] && { rm -f "$filepath"; mv "$temp_output" "$new_filepath"; echo "Converted to MP4: $filename"; return 0; }
    fi

    # Strategy 2: ffmpeg with full re-encode (audio+video)
    echo "Converting to MP4: $filename (ffmpeg re-encode)" | tee -a "$LOG_FILE"
    if timeout $TIMEOUT ffmpeg -nostdin -y -i "$filepath" -c:v libx264 -crf 28 -preset fast -c:a aac -b:a 128k "$temp_output" >> "$log_file" 2>&1; then
        [ -f "$temp_output" ] && { rm -f "$filepath"; mv "$temp_output" "$new_filepath"; echo "Converted to MP4: $filename"; return 0; }
    fi

    # Strategy 3: ffmpeg with audio copy (for problematic audio codecs)
    echo "Converting to MP4: $filename (ffmpeg audio copy)" | tee -a "$LOG_FILE"
    if timeout $TIMEOUT ffmpeg -nostdin -y -i "$filepath" -c:v libx264 -crf 28 -preset fast -c:a copy "$temp_output" >> "$log_file" 2>&1; then
        [ -f "$temp_output" ] && { rm -f "$filepath"; mv "$temp_output" "$new_filepath"; echo "Converted to MP4: $filename"; return 0; }
    fi

    # Strategy 4: Last resort - copy original to preserve it
    echo "Preserving original: $filename (conversion failed)" | tee -a "$LOG_FILE"
    cp -f "$filepath" "$new_filepath" 2>/dev/null && {
        rm -f "$filepath"
        echo "Preserved original: $filename"
        return 0
    } || {
        echo "Failed to process: $filename (keeping original)" | tee -a "$LOG_FILE"
        return 1
    }
}

# --- Process a single file ---
process_file() {
    local filepath="$1" filename=$(basename "$filepath")

    # Skip hidden/non-media files
    [[ "$filename" == .* ]] && return
    [[ ! "$filename" =~ \.(jpg|jpeg|png|gif|3gp|mp4|mov|avi|mkv|JPG|JPEG|PNG|GIF|MP4|MOV|AVI|MKV)$ ]] && return

    # Process videos
    if [[ "$filename" =~ \.(3gp|mov|avi|mkv|MOV|AVI|MKV|mp4|MP4)$ ]]; then
        if convert_video "$filepath"; then
            filepath="$(dirname \"$filepath\")/$(basename \"$filepath\" .${filename##*.}).mp4"
            filename=$(basename \"$filepath\")
        fi
    fi

    # Process images
    if [[ "$filename" =~ \.(jpg|jpeg|png|gif|JPG|JPEG|PNG|GIF)$ ]]; then
        if is_blurry "$filepath"; then
            echo "Blurry image detected: $filename -> moving to duplicates" | tee -a "$LOG_FILE"
            mv "$filepath" "$DUPLICATES/" 2>/dev/null && return
        fi
        auto_enhance "$filepath"
    fi

    # Organize by date
    local date_str=$(get_date "$filepath")
    local year=$(echo "$date_str" | awk '{print $1}') month_num=$(echo "$date_str" | awk '{print $2}')
    [ -z "$year" ] && year="notime"
    [ -z "$month_num" ] && month_num="00"

    local month_name=$(get_month_name "$month_num")
    local dest_dir="$ORGANIZED/${year}/${month_name}"
    mkdir -p "$dest_dir"
    mv "$filepath" "$dest_dir/" 2>/dev/null && echo "Organized: $filename -> $dest_dir/" || echo "Failed to move: $filename" | tee -a "$LOG_FILE"
}

# --- Main workflow ---
log "=== Reorganize Existing Files Script started ==="
find "$ORGANIZED" -type f -print0 | while IFS= read -r -d '' filepath; do
    process_file "$filepath"
done
log "Cleaning up empty folders..."
find "$ORGANIZED" -depth -type d -empty -exec rmdir {} + 2>/dev/null
log "=== Reorganize Existing Files Script completed ==="
