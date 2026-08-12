# 📁 Media Organizer

[License: MIT](https://opensource.org/licenses/MIT)

**A simple, safe script to organize AND auto-rotate your photos/videos by date.**

- Auto-rotates images from cameras/phones based on EXIF orientation tags.
- Respects manually edited images (no rotation if EXIF tag is missing/normal).
- Files are **NEVER deleted**—only moved and rotated in-place.

---

## ⚠️ **IMPORTANT: READ BEFORE USE**

- **Auto-rotation only works for images from cameras/phones** (with valid EXIF orientation tags).
- **Manually edited images** (e.g., rotated in GIMP/Photoshop) **won’t be auto-rotated** (the script respects your changes).
- **Always back up your files** before running this script.
- **Test on a small subset of files first**.

---

## 🌟 Features


| Feature                   | Description                                                                        |
| ------------------------- | ---------------------------------------------------------------------------------- |
| **Date-Based Sorting**    | Organizes files into `Year/Month/` folders using EXIF/metadata or filenames.       |
| **Auto-Rotation**         | Rotates images from cameras/phones based on EXIF orientation tags (`3`, `6`, `8`). |
| **Respects Manual Edits** | Skips rotation for images with no EXIF orientation tag (e.g., manually edited).    |
| **Video Rotation**        | Rotates videos with rotation metadata (common in phone videos).                    |
| **Supports Many Formats** | JPG, PNG, GIF, HEIC, MP4, MOV, AVI, MKV, and more.                                 |
| **Empty Folder Cleanup**  | Removes empty folders in `to-be-sorted/` after processing.                         |
| **Clean Logging**         | Only logs rotations and successful moves.                                          |


---

## 📦 Dependencies


| Tool       | Purpose                                                  | Install Command (Ubuntu/Debian)           |
| ---------- | -------------------------------------------------------- | ----------------------------------------- |
| `exiftool` | Extract dates and auto-rotate images based on EXIF tags. | `sudo apt install libimage-exiftool-perl` |
| `ffmpeg`   | Rotate videos based on metadata.                         | `sudo apt install ffmpeg`                 |


---

## 🚀 Quick Start

1. **Clone or download**:
  ```bash
   git clone https://github.com/yourusername/media-organizer.git
   cd media-organizer
  ```
2. **Edit `auto_organize_all.sh`**:
  ```bash
   INBOX="/path/to/your/media/to-be-sorted"    # Unsorted media folder
   ORGANIZED="/path/to/your/media/organized"    # Output folder
   LOG_FILE="/path/to/your/media_organizer.log" # Log file
  ```
3. **Install dependencies**:
  ```bash
   sudo apt update
   sudo apt install -y libimage-exiftool-perl ffmpeg
  ```
4. **Run the script**:
  ```bash
   chmod +x auto_organize_all.sh
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
2. **Auto-rotates images** based on EXIF orientation tags (`3`=180°, `6`=90° CW, `8`=90° CCW).
3. **Extracts dates** from:
  - Filenames (e.g., `20230101_photo.jpg` → `2023 01`).
  - EXIF metadata (`DateTimeOriginal` or `CreateDate`).
  - File modification time (fallback).
4. **Moves files** to `organized/Year/Month/` (e.g., `organized/2023/01. January/`).
5. **Rotates videos** if metadata indicates it.
6. **Cleans up empty folders** in `to-be-sorted/`.

---

## ⚠️ Known Limitations

- **No rotation for manually edited images**: If you rotate an image in an editor (e.g., GIMP), the script **won’t auto-rotate it** (respects your manual changes).
- **No duplicate detection**: Use [dupeGuru](https://dupeguru.volko.net/) (80% similarity) or `fdupes` afterward.
- **HEIC files**: Auto-rotation works if `exiftool` supports HEIC (requires `libheif1` on some systems).

---

## 🛠️ Customization

### Add/Remove File Extensions

Edit the regex in `process_file()`:

```bash
if [[ ! "$filename" =~ \.(jpg|jpeg|png|gif|heic|3gp|mp4|mov|avi|mkv|JPG|JPEG|PNG|GIF|HEIC|MP4|MOV|AVI|MKV)$ ]]; then
```

---

## 📜 License

MIT License – see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- Inspired by *"Automate the Boring Stuff with Python"* by Al Sweigart.
- Thanks to the open-source tools: `exiftool`, `ffmpeg`.
