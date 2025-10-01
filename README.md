# Comparative Wordlist Elicitation Tool (Android)

This repository contains the source code for an Android application designed to assist linguists and fieldworkers in the systematic **elicitation and documentation of minority languages**.

The tool facilitates the collection of:

- **Phonetic Transcriptions:** Input fields for documenting words using IPA or other relevant orthographies.

- **Audio Recordings:** Functionality to capture high-quality audio recordings associated with each word.

- **Media Display:** Ability to display relevant pictures or media (when available in the wordlist data) to aid the elicitation process.

## 🚧 Project Status: Seeking Initial Contributors 🚀

**This project is currently in the conceptual and planning phase.** We are actively seeking **Android Developers** interested in linguistic fieldwork and open-source software to help build the initial application structure and core features. If you are looking for a high-impact project, please check the **Issues** tab to see initial feature discussions!

## Core Features and Technical Scope

The goal is to create a robust and reliable fieldwork companion. Initial development should focus on these key areas:

### 1. Data Management

- **XML Import:** Implement an efficient, fault-tolerant parser for the Dekereke XML format imported by the user.

- **Local Storage:** Utilize **SQLite/Room** for persistent storage of the imported wordlist, newly collected transcriptions, and metadata.

- **Session Tracking:** Allow users to resume fieldwork sessions and track which words have been elicited.

- **Target Applications:** The goal of the exported data is for use with professional linguistic tools like **Dekereke** (https://casali.canil.ca/Dekereke/) and **Fieldworks Language Explorer (FLEx)** (https://software.sil.org/fieldworks/).

- **Export:** Implement functionality to package and export all collected data into a single **ZIP archive**.
  
  - **Required XML File (MVP):** The initial release must export the collected data in **Dekereke XML** format (matching the input structure).
  
  - **Future XML File Goal:** Implement export to **LIFT XML** (Linguistic Interlinearized Format and Toolkit) in a subsequent release. (LIFT Documentation: https://downloads.languagetechnology.org/fieldworks/Documentation/Technical%20Notes%20on%20LIFT%20used%20in%20FLEx.pdf)

  The export must adhere to the following audio specifications for all formats:

- **Audio Folder:** A dedicated `audio` folder containing all elicited recordings.

- **Audio Format:** 16-bit WAV.

- **Audio Naming Convention:** Files must be named using the 4-digit, leading-zero reference number from the word's `Reference` field, followed by the text from the word's `Gloss` field, with spaces replaced by periods (e.g., `0001_step.on.wav`).

- **XML Linking:** The corresponding audio filename (e.g., `0001_step.on.wav`) must be included within the matching record in the exported XML files: in the `<SoundFile>` element/field for Dekereke XML, and as a voice writing system reference for LIFT XML (once implemented).

### 2. Elicitation Interface

- **Responsive UI:** Design a clean, high-contrast, and responsive interface optimized for tablet and mobile use in fieldwork environments (often low-light or outdoor settings).

- **Transcription Input:** Provide specialized input fields that are easy to use for entering and editing IPA symbols.

- **Media Integration:** Display associated images or media files referenced in the wordlist data.

### 3. Audio Recording

- **High-Quality Capture:** Implement reliable, easy-to-access functionality for recording and stopping audio directly linked to the current word entry.

- **Storage:** Store audio files locally, organized by session or language identifier.

- **Playback:** Basic playback functionality to review the elicited audio instantly.

## Recommended Technology Stack

We suggest the following modern Android development stack:

- **Language:** Kotlin (Recommended)

- **UI Framework:** Jetpack Compose (Preferred for modern, scalable UI) or traditional XML/Views.

- **Architecture:** Clean Architecture (MVVM) is encouraged for maintainability.

- **Data Persistence:** Android Room (for SQLite abstraction).

- **XML Parsing:** Standard Android or Kotlin libraries for XML reading.

## Contribution and Development

We welcome contributions! All contributions to this code must be licensed under the **AGPL-3.0** or a compatible license.

### First Steps for New Developers:

1. **Check Issues:** Start by reviewing the **Issues** tab. Look for issues tagged `good first issue` or `help wanted` to understand immediate needs and planned features.

2. **Propose Architecture:** The first major step is designing the core data model (Room entities) and the XML parsing logic. Feel free to open a new Issue to propose an initial architecture plan.

3. **Fork and Clone:** Fork the repository and start setting up the basic Android project structure.

Please use the GitHub Issues page for bug reports, feature requests, and community discussions.

## Licensing (AGPL-3.0)

The source code for the Comparative Wordlist Elicitation Tool is licensed under the **GNU Affero General Public License Version 3 (AGPL-3.0)**.

The full license text is available in the `LICENSE_AGPL.md` file in this repository.

### AGPL-3.0 Obligations

The AGPL-3.0 is a strong copyleft license designed for networked software. If you **modify** this application's source code and **distribute** or **make the modified version available to users over a computer network** (e.g., hosting it on a public server or distributing a modified app), you must make the **complete corresponding source code** of your modifications available to those users.

## Wordlist Data Requirement (Crucial License Separation)

**This application's code is licensed AGPL-3.0. The wordlist data it uses is licensed CC BY-NC-SA 4.0.**

To maintain legal clarity and separation: **This application does NOT bundle any wordlist data.** Users must acquire and import a wordlist file separately.

We recommend using the officially adapted data file available from our dedicated data repository:

### 1. Acquire the Data File

The **Quickstart Worldlist of Melanesia** data is available under the **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)**.

Please download the standardized XML file (e.g., `QWOM2025-08.xml`) from the data repository:

> **Data Repository Link:** **https://github.com/rulingAnts/QWOM_Data**

### 2. Import Instructions

1. Transfer the acquired XML wordlist file to your Android device.

2. Launch the Comparative Wordlist Elicitation Tool.

3. Navigate to the "Import Wordlist" function and load the XML file.

By using this method, the AGPL-licensed software acts merely as a tool operating on the user-acquired, CC BY-NC-SA licensed data, ensuring no license conflict arises.
