# ChatGPT Clone - Backend (Node.js)

API Endpoints:

1. POST /api/chat - Send a message to AI.
2. POST /api/conversations - Create a new empty conversation.
3. GET /api/conversations/:userId - Fetch all user conversations.
4. GET /api/conversations/:conversationId/messages - Get a conversation with messages.
5. PUT /api/conversations/:conversationId/title - Update conversation title.
6. DELETE /api/conversations/:conversationId - Delete a conversation.
7. POST /api/upload - Upload an image to Cloudinary & Store Public URL to MongoDB Conversations Collection

MONGO_URI= mongodb connection url
OPENAI_API_KEY= openAI API key
CLOUDINARY_CLOUD_NAME= cloudinary name
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
PORT=5050
