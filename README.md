# qBittorrent Easy Backup & Restore Toolkit

![Project Icon](icon.png)  <!-- Replace with your icon file -->

![Project Image](image.png)  <!-- Replace with your main image or diagram -->

---

## 🔹 Overview

A simple toolkit that makes **backing up, restoring, and wiping qBittorrent data extremely easy**. Designed for users who want a **one-click solution** without navigating hidden system folders.

This project uses **PowerShell scripts and batch files** to automate the process of saving and restoring your qBittorrent configuration, torrents, and session data.

Perfect for:

* System reinstalls
* Windows clean installs
* Migrating qBittorrent to a new PC
* Protecting your torrent progress from data loss

---

## ✨ Features

* **One-click Backup**: Create a full backup of your qBittorrent configuration and session data.
* **Interactive Restore**: Lists available backups and lets you choose which one to restore.
* **Safe Data Wipe**: Completely removes qBittorrent data when needed.
* **Beginner Friendly**: Just double-click `.bat` files — no command line knowledge required.
* **Organized Backup System**: Backups are automatically stored with date labels.
* **Automatic Backups**: Set up daily or weekly automatic backups via Windows Task Scheduler.

---

## 📂 Project Structure

```
qBittorrent Main Folder
│
├── backups
│   ├── qbittorrent backup "date"
│   └── qbittorrent backup "date 2"
│
├── qbittorrent_backup_script.ps1
├── backup.bat
│
├── qbittorrent_restore_script.ps1
├── restore.bat
│
└── Wipe Data
    ├── qbittorrent_wipe_script.ps1
    └── wipe.bat
```

---

## ⏰ Automatic Daily or Weekly Backups

You can automate backups to run **daily or weekly** using **Windows Task Scheduler**. This ensures your qBittorrent configuration and session data are safely backed up without manual intervention.

### Setup Instructions

1. Press **Win + R**, type `taskschd.msc`, and open **Task Scheduler**.
2. Click **Create Basic Task**.
3. Name it `qBittorrent Auto Backup`.
4. Choose **Daily** or **Weekly**.
5. For **Action**, select **Start a Program**.
6. Browse and select `backup.bat`.
7. Finish the setup.

💡 Tip: Schedule the backup when qBittorrent is **closed** to ensure all session data is saved properly.

---

## 🔹 How It Works

### Backup

Run:

```
backup.bat
```

* Automatically creates a **timestamped backup**
* Stores it inside the `backups` folder

### Restore

Run:

```
restore.bat
```

* Shows available backups
* Lets you choose a backup number to restore

### Wipe Data

Run:

```
wipe.bat
```

* Completely removes all qBittorrent data

⚠ **Warning:** Always create a backup before wiping data.

---

## 🛠 Requirements

* Windows
* qBittorrent installed
* PowerShell

---

## 📜 License

This project uses the **MIT License**. You are free to use, modify, and share it.

```text
MIT License
Copyright (c) 2026 Livid96
```

---

## 📢 Note

This tool **only backs up qBittorrent configuration and session data**, not the actual downloaded files. Ensure your download directories remain unchanged when restoring.
