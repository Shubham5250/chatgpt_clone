const express = require("express");
const router = express.Router();
const Conversation = require("../models/Conversation");

const {
  chat,
  getConversations,
  getConversation,
  updateTitle,
  deleteConversation,
} = require("../controllers/chatController");

router.post("/chat", chat);

router.post("/conversations", async (req, res) => {
  const { userId } = req.body;
  if (!userId) return res.status(400).json({ error: "userId is required" });
  const conversation = new Conversation({
    userId,
    title: "New Chat",
    messages: [],
  });
  await conversation.save();
  res.json({
    conversationId: conversation._id,
    title: conversation.title,
  });
});

// Get all conversations
router.get("/conversations/:userId", getConversations);

// Get specific conversation
router.get("/conversations/:conversationId/messages", getConversation);

// Update conversation title
router.put("/conversations/:conversationId/title", updateTitle);

// Delete conversation
router.delete("/conversations/:conversationId", deleteConversation);

module.exports = router;
