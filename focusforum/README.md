# FocusForum

FocusForum is a Flutter application designed to aggregate and display forum content from various sources, particularly focusing on JVC forums. The app fetches RSS feeds, parses them, and presents the information in a user-friendly interface.

## Features

- **Dynamic Forum Management**: Users can add their favorite forums, and the app will automatically fetch and display threads from the provided RSS feeds.
- **JVC Forum Support**: Special handling for JVC forums, allowing users to easily access and navigate through threads.
- **Thread and Post Display**: View detailed information about threads and individual posts, including author details and timestamps.

## Project Structure

```
focusforum
├── lib
│   ├── controllers
│   │   ├── forum_controller.dart  # Manages the list of forums
│   │   └── rss_service.dart       # Fetches and parses RSS feeds
│   ├── models
│   │   ├── forum.dart              # Represents a forum
│   │   ├── forum_post.dart         # Represents a post in a forum
│   │   └── thread.dart             # Represents a thread in a forum
│   ├── views
│   │   ├── drawer_menu.dart        # Navigation drawer
│   │   ├── forum_card.dart         # Displays a list of forums
│   │   ├── forum_view.dart         # Displays details of a specific forum
│   │   ├── home_view.dart          # Main screen displaying forums
│   │   ├── thread_detail_view.dart  # Displays details of a specific thread
│   │   └── thread_view.dart        # Displays a list of threads in a forum
│   ├── forums
│   │   └── jvc                     # Contains files related to JVC forums
│   └── main.dart                   # Entry point of the application
├── pubspec.yaml                    # Flutter project configuration
└── README.md                       # Project documentation
```

## Setup Instructions

1. **Clone the Repository**: 
   ```bash
   git clone <repository-url>
   cd focusforum
   ```

2. **Install Dependencies**: 
   Run the following command to install the required packages:
   ```bash
   flutter pub get
   ```

3. **Run the Application**: 
   Use the following command to launch the app:
   ```bash
   flutter run
   ```

## Usage

- Upon launching the app, users can view a list of forums.
- Users can add new forums by providing the RSS feed URL.
- Tapping on a forum will display the threads associated with it.
- Users can view detailed information about each thread and its posts.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.