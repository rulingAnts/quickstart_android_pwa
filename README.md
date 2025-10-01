# Comparative Wordlist Elicitation Tool (Android)

This repository contains the source code for an Android application designed to assist **trained linguists, fieldworkers, and community members** in the systematic **elicitation and documentation of minority languages**.

The primary goal is to provide a tool simple enough for native speakers with limited technical and reading abilities to collect high-quality data.

The tool facilitates the collection of:

- **Phonetic Transcriptions:** Input fields for documenting words using IPA or other relevant orthographies.

- **Audio Recordings:** Functionality to capture high-quality audio recordings associated with each word.

- **Media Display:** Ability to display relevant pictures or media (when available in the wordlist data) to aid the elicitation process.

## 🚧 Project Status: Seeking Initial Contributors 🚀

**This project is currently in the conceptual and planning phase.** We are actively seeking **Android Developers** interested in linguistic fieldwork and open-source software to help build the initial application structure and core features. If you are looking for a high-impact project, please check the **Issues** tab to see initial feature discussions!

## Core Features and Technical Scope (MVP Focus)

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

- **Audio Naming Convention:** Files must be named using the 4-digit, leading-zero reference number from the word's `Reference` field, followed by the text from the word's `Gloss` field, with spaces replaced by periods (e.g., `0001body.wav`).

- **XML Linking:** The corresponding audio filename (e.g., `0001body.wav`) must be included within the matching record in the exported XML files: in the `<SoundFile>` element/field for Dekereke XML, and as a voice writing system reference for LIFT XML (once implemented).

### 2. Elicitation Interface

- **Responsive UI & Accessibility:** Design an **extremely simple, visually driven, and intuitive interface**. The UI must rely minimally on text labels, using large icons and high-contrast color schemes suitable for all users, including those with lower reading or technical abilities. Optimized for tablet and mobile use in fieldwork environments (often low-light or outdoor settings).

- **Localization (i18n):** **Crucial Requirement:** All static in-app text (e.g., button labels, settings headers, instructions, consent text) must be fully localizable. The researcher must be able to configure and bundle the appropriate language of wider communication within the application package.

- **Transcription Input:** The input field must be compatible with **IPA** characters.
  
  - **Encoding:** Ensure compatibility with **UTF-16** for Dekereke XML and **UTF-8** for LIFT XML export.
  
  - **Fonts:** The app should either include or clearly instruct the user to import OFL-licensed fonts compatible with IPA, such as **Charis SIL** (https://software.sil.org/charis/) or **Doulos SIL** (https://software.sil.org/doulos/). Developers should verify and include the necessary SIL Open Font License (OFL) documentation.
  
  - **Keyboard Integration:** Recommend that users install **Keyman** (https://play.google.com/store/apps/details?id=com.tavultesoft.kmapro) as their system-wide Android keyboard for efficient IPA entry.

- **Media Integration:** Display associated images or media files referenced in the wordlist data, using large, clear display areas. **The XML parser and data model must support an optional `<Picture>` field/element, which links to researcher-supplied image files.**

### 3. Ethical Data Collection and Consent (MVP Requirement)

- **Goal:** Ensure clear, ethically sound, **informed consent** is obtained from the native speaker before any data collection begins. This is an absolute requirement for the MVP.

- **Researcher Configuration:** The application must support highly customizable consent prompts, which must be configurable by the researcher (ideally via the App Bundling Wizard, or initial in-app setup). Two primary configurable modes are required:
  
  - **Verbal/Audio Consent:** Play a pre-recorded audio file (in the native language) explaining the project's purpose and data usage. The user must provide assent by pressing an explicit  
    
    IAgree
    
    button, or by recording their verbal assent.
  
  - **Written Consent:** Display a clear, simple text explanation (in the native language) with explicit  
    
    Yes
    
    /  
    
    No
    
    buttons.

- **Consent Record:** The application must create a persistent, timestamped **Consent Log** containing:
  
  - The date and time the consent was sought and the response was recorded.
  
  - The user's unique device/session ID.
  
  - The type of prompt used (Verbal/Text) and the final response (Assent/Decline).
  
  - If Verbal Consent is used, the recording of the assent must be saved.

- **Data Export:** This Consent Log (and any associated verbal recording) must be included as a **separate, clearly identifiable file** (e.g., `consent_log.json` or `consent_log.txt`) in the final ZIP export and be included in the Cloud Data Sync.

### 4. Audio Recording

- **High-Quality Capture:** Implement reliable, easy-to-access functionality for recording and stopping audio directly linked to the current word entry. **The recording button must be large, highly visible, and instantly recognizable (e.g., a simple, iconic microphone/dot).**

- **Storage:** Store audio files locally, organized by session or language identifier.

- **Playback:** Basic playback functionality to review the elicited audio instantly.

## Future Enhancements and Advanced Workflow (Phase 2+)

These features are intended for later development phases but are crucial for the long-term vision of empowering researchers and community members.

### A. Non-Technical App Bundling Wizard (New Desktop Project)

- **Goal:** Create a separate, open-source desktop application (e.g., for Windows/macOS/Linux—likely licensed under AGPL or GPL) similar in function to Scripture App Builder (https://software.sil.org/scriptureappbuilder/).

- **Functionality:** This wizard would allow a researcher (who does not know Kotlin or XML) to:
  
  1. Automatically include the base APK of this Android app (no manual selection required).
  
  2. Specify a custom wordlist (XML) and matching picture files.
  
  3. Configure optional settings (e.g., cloud upload folder credentials, **consent prompts**).
  
  4. Generate a **customized, pre-configured APK bundle** ready for side-loading onto a native speaker's device. This eliminates the need for the user to manually import files.

### B. Cloud Data Sync (Essential for Fieldwork)

- **Goal:** Provide secure, researcher-configurable background synchronization of collected data.

- **Functionality:**
  
  - Allow the researcher to configure credentials for a cloud service (e.g., Google Drive, Dropbox, or a custom server) within the App Bundling Wizard.
  
  - The Android app should upload collected transcriptions and audio files either **incrementally** (as they are recorded) or in **bulk** when an internet connection is available.

### C. AI Image Generation Helper

- **Goal:** Offer the researcher an integrated tool to quickly generate visual aids for words that lack images.

- **Functionality:** Integrate the Google Gemini API to generate simple, descriptive **pencil sketch-style AI images** based on the word's gloss. The researcher would review, approve, and save these images to their media folder for inclusion in the App Bundle (Feature A). **Crucial:** This AI generation happens on the researcher's desktop/tool, not within the AGPL-licensed Android app, ensuring the core app remains clean and resource-light.

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
