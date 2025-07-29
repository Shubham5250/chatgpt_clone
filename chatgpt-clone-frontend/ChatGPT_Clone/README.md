# IMP LIBRARIES USED:
1. dio - HTTP Client Package
2. flutter_dotenv - for .env file 
3. uuid - generate unique ids
4. firebase_core, auth, google_sign_in - To manage user authentication
5. flutter_riverpod - State Management Library
6. file_picker - for selecting files from device.


# IMPLEMENTATION:

### A. State Management (Riverpod)
**WHY RIVERPOD?**
1. Scalable State Management for Complex Chat Logic
2. Each state is managed by a separate Provider/Notifier, but they can react to each other
3. Handles Async Operations
4. Update UI immediately with local state, then sync with the backend & If the API fails, roll back easily.

Structure - (auth_provider.dart, chat_provider.dart)

    - Service Layer (AuthService, ApiService): Handles raw operations (Firebase, API calls).
    - State Layer (AuthNotifier, ChatNotifier): Manages app state and business logic.
    - UI Layer: Consumes state via ref.watch().
    
    - Provides Optimistic UI Update
            optimisticMessage = Message(..., status: MessageStatus.sending);
            state = [...state.map(...)]; // immediately update UI  

    - Model Selection - Used selectedModelProvider (StateProvider<String>) to track the active model.
    - UI rebuilds automatically on state changes.


### B. API INTEGRATION & HTTP METHODS (DIO)

**Structure**

    - ApiService Class: Centralizes all HTTP requests to Node.js backend.
    - Dio Client: Used for featuers such as interceptors, file uploads, timeouts.
    - Error Handling: Global try/catch with custom exceptions.

- KEY METHODS:
1. sendMessage() - POST /api/chat 
2. getUserChats() - GET /api/conversations/:userId
3. uploadImage() - POST /api/upload [Uploads images to Cloudinary & Temp Backend Storage]