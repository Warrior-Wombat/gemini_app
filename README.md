# Warrior-Wombat

![Project Logo](./frontend/images/sayspeak_circular_logo.png)

## Table of Contents

1. [Frontend Setup](#frontend-setup)
2. [Middleware Setup](#middleware-setup)
3. [License](#license)

## Frontend Setup

1. **Navigate to the Frontend Directory:**
    ```bash
    cd frontend
    ```

2. **Install Flutter Dependencies:**
    Ensure you have Flutter installed. Follow the [official installation guide](https://flutter.dev/docs/get-started/install) if needed.
    ```bash
    flutter pub get
    ```

3. **Set Up Environment Variables:**
    - Create a `.env` file inside the `frontend` directory.
    - Obtain your API keys from the following sources:
        - [OpenAI API Key](https://beta.openai.com/signup/)
        - [Eleven Labs API Key](https://www.elevenlabs.io/signup)
    - Add the following lines to your `.env` file:
    ```env
    OPENAI_API_KEY=your_openai_api_key
    ELEVENLABS_API_KEY=your_elevenlabs_api_key
    ```

4. **Enable Environment Variables in pubspec.yaml:**
    Uncomment the `.env` dependency in `pubspec.yaml`.

5. **Firebase Setup:**
    - Create a new Firebase project and configure it.
    - Initialize Firebase in your project:
        ```bash
        flutterfire configure
        ```
    - Place the generated `firebase_options.dart` inside the `services` folder.
    - Place `google_services.json` inside the `android/app` directory.

## Middleware Setup

1. **Navigate to the Middleware Directory:**
    ```bash
    cd middleware
    ```

2. **Create a Virtual Environment:**
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows use `venv\Scripts\activate`
    ```

3. **Install Python Dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4. **Set Up Environment Variables:**
    - Create a `.env` file inside the `middleware` directory.
    - Obtain your API key from [Google Studio](https://studio.google.com/).
    - Add the following line to your `.env` file:
    ```env
    GEMINI_API_KEY=gemini_key
    ```

5. **Firebase Credentials:**
    - Create a `credentials` folder inside the `middleware` folder. Place the Firebase Credentials JSON you get from Firebase into the `credentials` folder.

## License

This project is licensed under the MIT License.
