# 🎬 Media Organizer

[License: MIT](https://opensource.org/licenses/MIT)

**Automate the organization of your photos and videos** with this script, inspired by *"Automate the Boring Stuff with Python".* Sort files by date, convert videos to MP4, compress for storage, and auto-enhance images—all hands-free!

---

## 🌟 Features


| Feature                    | Description                                                                                       |
| -------------------------- | ------------------------------------------------------------------------------------------------- |
| **Date-Based Sorting**     | Organizes files into `Year/Month/` folders using EXIF/metadata.                                   |
| **Video Conversion**       | Converts all videos to MP4 (HandBrakeCLI + ffmpeg fallback).                                      |
| **Compression**            | Reduces file size with H.264 (CRF 28) for storage savings.                                        |
| **Auto-Enhance Images**    | Uses Darktable to improve photos automatically.                                                   |
| **Blurry Image Detection** | Moves low-quality images to a `duplicates` folder.                                                |
| **Corruption Handling**    | Skips corrupted files and logs them for review.                                                   |
| **Timeout Protection**     | Never hangs—kills stuck processes after 2 minutes.                                                |
| **DupeGuru Integration**   | Use [dupeGuru](https://dupeguru.volko.net/) (80% similarity) to find duplicates after organizing. |


---

## 📦 Dependencies


| Tool                  | Purpose                             | Install Command (Debian/Ubuntu)              |
| --------------------- | ----------------------------------- | -------------------------------------------- |
| `exiftool`            | Extract metadata (dates) from files | `sudo apt install libimage-exiftool-perl`    |
| `ffmpeg`              | Video conversion/compression        | `sudo apt install ffmpeg`                    |
| `darktable`           | Auto-enhance images                 | `sudo apt install darktable`                 |
| `HandBrakeCLI`        | Primary video converter             | `sudo apt install handbrake`                 |
| `dupeGuru` (optional) | Find duplicates                     | [Download here](https://dupeguru.volko.net/) |


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
DUPLICATES="/path/to/your/media/duplicates"  # Blurry/corrupt images
TEMP_DIR="/tmp/handbrake_temp"                # Temp files
LOG_FILE="/path/to/your/media_organizer.log"  # Log file
```

### 3. Run the Script

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
├── organized/       # Sorted output (auto-created)
│   ├── 2023/
│   │   ├── 01. January/
│   │   └── 02. February/
│   └── notime/      # Files without date metadata
│       └── 00/
└── duplicates/      # Blurry/corrupt images
```

---

## ⚙️ How It Works

### For **Photos**:

1. Checks if the image is blurry (using Darktable).
2. Auto-enhances non-blurry images.
3. Organizes by date into `Year/Month/` folders.

### For **Videos**:

1. **Pre-checks** for corruption.
2. Tries **4 strategies** to convert to MP4:
  - HandBrakeCLI (default).
  - ffmpeg with full re-encode (audio+video).
  - ffmpeg with audio copy (for problematic codecs).
  - Copies original if all else fails.
3. **Compresses** all videos (including existing MP4s).
4. Organizes by date into `Year/Month/` folders.

### For **Duplicates**:

- After organizing, use **dupeGuru** (set to **80% similarity**) to find and remove duplicates.

---

## ⚠️ Known Issues &amp; Solutions


| Issue                                | Cause                       | Solution                                                              |
| ------------------------------------ | --------------------------- | --------------------------------------------------------------------- |
| **Script hangs on old `.avi` files** | Obscure codecs (DivX, XviD) | Script now has **4 fallback strategies** + **corruption pre-check**.  |
| **Some videos fail to convert**      | Unsupported codecs          | Files are **preserved in original format** and logged.                |
| **Wrong date for some files**        | Missing/incorrect metadata  | Files go to `notime/00/`. Use `exiftool` to fix metadata manually.    |
| **Blurry images not detected**       | Darktable limitations       | Adjust Darktable’s blurry threshold or manually review.               |
| **Script stops early**               | Permissions/path issues     | Run with `bash -x` for debugging. Ensure paths in config are correct. |


---

## 🛠️ Customization

### Adjust Compression Quality

Edit the `-crf` value in the script (lower = better quality, higher = smaller file):

```bash
# In convert_video():
ffmpeg -c:v libx264 -crf 28  # 28 = good balance (18-28 is typical)
```

### Change Timeout

Modify the `TIMEOUT` variable (in seconds):

```bash
TIMEOUT=120  # 2 minutes per video
```

### Exclude File Types

Edit the regex in `process_file()`:

```bash
# Current: \.(jpg|jpeg|png|gif|3gp|mp4|mov|avi|mkv|JPG|JPEG|PNG|GIF|MP4|MOV|AVI|MKV)$
# Add/remove extensions as needed.
```

---

## 📊 Performance Tips

1. **Run on a PC**: Termux/Android may struggle with large video files.
2. **Batch Processing**: For 10,000+ files, split into smaller batches.
3. **Monitor Logs**:
  ```bash
   tail -f /path/to/your/media_organizer.log
  ```
4. **Check Failed Videos**:
  ```bash
   cat /tmp/ffmpeg_logs/*.log
  ```

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 📜 License

MIT License – see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- Inspired by *"Automate the Boring Stuff with Python"* by Al Sweigart.
- Special thanks to the open-source tools: `ffmpeg`, `HandBrakeCLI`, `exiftool`, and `darktable`.
- Designed for **set-and-forget** media organization.
