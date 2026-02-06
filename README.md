# Onpu iOS

Onpu is a native iOS application built to help users learn Japanese through music. It takes raw song lyrics and uses AI to provide detailed linguistic breakdown and translations.

<img src="mockup.png" width="400" alt="App Mockup">


## Functionality

The main goal of the app is to make Japanese lyrics accessible and easy to study.

*   **Furigana Support**: It automatically adds reading aids above kanji characters to help with pronunciation.
*   **Pitch Accent Visualization**: The app draws custom lines over text to show the correct pitch accent for words. This mimics the style used in linguistics textbooks.
*   **Instant Translations**: Google Gemini generates line by line English translations.
*   **Interactive Dictionary**: You can long press any kanji to view detailed information like meanings and mnemonics.
*   **Offline Access**: Once a song is processed it saves to the device so you can study without an internet connection.

## Technical Overview

This project is a modern iOS codebase that prioritizes performance and clean architecture.

### iOS Client
The mobile app is written in **Swift** and uses **SwiftUI** for the user interface. It uses **SwiftData** to persist songs and lyrics locally. The app handles complex text rendering with custom layouts to support the unique requirements of Japanese typography.

### Backend
Heavy processing is offloaded to a separate backend service. This is a **Node.js** application built with **Fastify**. It manages a job queue using **Redis** and communicates with the Google Gemini API to analyze lyrics. The iOS app communicates with this backend to submit songs and retrieve the processed data.

## Project Structure

The repository is organized into three main folders.

*   **Uta**: This folder contains the iOS application code including Views, Models, and ViewModels.
*   **backend**: This contains the server side code for handling AI requests.
*   **landing**: This holds a Next.js web project for the app's landing page.
