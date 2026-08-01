# 📁 Media Organizer (Safe Mode)

[License: MIT](https://opensource.org/licenses/MIT)

**A simple, safe script to organize your photos and videos by date.**  
No conversions, no compression, no modifications—**just sorting**.

---

## ⚠️ **IMPORTANT: READ BEFORE USE**

- **This script ONLY moves files** into `Year/Month/` folders. It **does NOT delete, convert, or modify** your originals.
- **Always back up your files** before running this script.
- **Test on a small subset of files first** to ensure it works as expected.

---

## 🌟 Features


| Feature                                | Description                                                                  |
| -------------------------------------- | ---------------------------------------------------------------------------- |
| **Date-Based Sorting**                 | Organizes files into `Year/Month/` folders using EXIF/metadata or filenames. |
| **Supports Many Formats**              | JPG, PNG, GIF, HEIC, MP4, MOV, AVI, MKV, and more.                           |
| **Fallback to File Modification Time** | If no date metadata is found, uses the file’s modification time.             |
| **Empty Folder Cleanup**               | Removes empty folders in `to-be-sorted/` after processing.                   |
| **Detailed Logging**                   | Logs every action to a file for debugging.                                   |


---

## 📦 Dependencies


| Tool                | Purpose                          | Install Command (Ubuntu/Debian)           |
| ------------------- | -------------------------------- | ----------------------------------------- |
| `exiftool`          | Extract dates from file metadata | `sudo apt install libimage-exiftool-perl` |
| `ffmpeg` (optional) | HEIC support (if needed)         | `sudo apt install ffmpeg`                 |


**Note**: If `exiftool` is not installed, the script will fall back to file modification times.

---

## 🚀 Quick Start

### 1. Clone or Download

```bash
git clone https://github.com/yourusername/media-organizer.git
cd media-organizer
```

### 2. Edit Configuration

Open `auto_organize_all.sh` and set your paths:

```bash
INBOX="/path/to/your/media/to-be-sorted"    # Unsorted media folder
ORGANIZED="/path/to/your/media/organized"    # Output folder
LOG_FILE="/path/to/your/media_organizer.log" # Log file
```

### 3. Make the Script Executable

```bash
chmod +x auto_organize_all.sh
```

### 4. Run the Script

```bash
./auto_organize_all.sh
```

---

## 📂 Folder Structure

```
your_media_folder/
├── to-be-sorted/    # Drop unsorted files here
│   ├── Photos/
│   └── Videos/
└── organized/       # Sorted output (auto-created)
    ├── 2023/
    │   ├── 01. January/
    │   └── 02. February/
    └── notime/      # Files without date metadata
        └── 00/
```

---

## ⚙️ How It Works

1. **Scans `to-be-sorted/`** for files.
2. **Extracts dates** from:
  - Filenames (e.g., `20230101_photo.jpg` → `2023 01`).
  - EXIF metadata (`DateTimeOriginal` or `CreateDate`).
  - File modification time (fallback).
3. **Moves files** to `organized/Year/Month/` (e.g., `organized/2023/01. January/`).
4. **Cleans up empty folders** in `to-be-sorted/`.

---

## ⚠️ Known Limitations

- **No video conversion**: Videos are moved as-is (no MP4 conversion).
- **No compression**: Files are not modified in any way.
- **No duplicate detection**: Use [dupeGuru](https://dupeguru.volko.net/) (80% similarity) or `fdupes` afterward.
- **HEIC files**: Moved as-is (no conversion). Requires `exiftool` for date extraction.

---

## 🛠️ Customization

### Add/Remove File Extensions

Edit the regex in `process_file()` to include/exclude file types:

```bash
if [[ ! "$filename" =~ \.(jpg|jpeg|png|gif|heic|3gp|mp4|mov|avi|mkv|JPG|JPEG|PNG|GIF|HEIC|MP4|MOV|AVI|MKV)$ ]]; then
```

### Change Date Extraction Priority

The script tries:

1. Filename (e.g., `20230101_photo.jpg`).
2. EXIF `DateTimeOriginal`.
3. EXIF `CreateDate`.
4. File modification time.

To **prioritize file modification time**, edit `get_date()`.

---

## 📊 Performance Tips

- **Run on a PC**: Faster than Termux/Android for large libraries.
- **Monitor logs**:
  ```bash
  tail -f /path/to/your/media_organizer.log
  ```
- **Test first**: Run on a small subset of files before processing everything.

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 📜 License

MIT License – see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- Inspired by *"Automate the Boring Stuff with Python"* by Al Sweigart.
- Thanks to the open-source tools: `exiftool`, `ffmpeg`.
