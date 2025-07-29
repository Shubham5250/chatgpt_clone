const { OpenAI } = require("openai");
const Conversation = require("../models/Conversation");

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// send chat
exports.chat = async (req, res) => {
  console.log("Chat endpoint hit...");
  const {
    userId,
    message,
    model = "gpt-4.1-nano",
    conversationId,
    title,
    imageUrl,
  } = req.body;

  try {
    if ((!message || message.trim() === "") && !imageUrl) {
      return res.status(400).json({ error: "Message or imageUrl is required" });
    }
    if (!userId) {
      return res.status(400).json({ error: "userId is required" });
    }

    let conversation;

    if (conversationId) {
      conversation = await Conversation.findOne({ _id: conversationId });
      if (!conversation) {
        return res.status(404).json({ error: "Conversation not found" });
      }
    } else {
      //  new conversation
      let chatTitle = "New Chat";
      if (imageUrl && (!message || message.trim() === "")) {
        chatTitle = "Image Uploaded";
      } else if (message && message.trim() !== "") {
        chatTitle = message.slice(0, 30) + (message.length > 30 ? "..." : "");
      }
      conversation = new Conversation({
        userId,
        model,
        title: title || chatTitle,
        messages: [],
      });
    }
    const { model } = req.body;
    const isImageOnly = imageUrl && (!message || message.trim() === "");

    if (isImageOnly && model !== "gpt-4o") {
      const reply = {
        role: "assistant",
        content: "Use GPT-4o to get responses for image input.",
      };
      conversation.messages.push({
        role: "user",
        content: "",
        imageUrl,
      });
      conversation.messages.push(reply);

      await conversation.save();
      return res.json({
        reply: reply.content,
        conversationId: conversation._id,
        title: conversation.title || "Image Uploaded",
      });
    }

    const messages = [];

    if (isImageOnly) {
      messages.push({
        role: "user",
        content: [
          {
            type: "image_url",
            image_url: { url: imageUrl },
          },
        ],
      });
    } else if (message && imageUrl) {
      messages.push({
        role: "user",
        content: [
          { type: "text", text: message },
          {
            type: "image_url",
            image_url: { url: imageUrl },
          },
        ],
      });
    } else {
      messages.push({
        role: "user",
        content: message,
      });
    }

    conversation.messages.push({
      role: "user",
      content: message || "",
      imageUrl,
    });

    console.log("Model received from frontend:", model);
    const response = await openai.chat.completions.create({
      model: model || "gpt-4.1-nano", // fallback to default
      messages: messages,
    });

    const reply = response.choices[0].message;
    console.log("AI Responded: ", reply);
    conversation.messages.push(reply);

    if (conversation.messages.length === 2 && !title) {
      if (imageUrl && imageUrl.length > 0) {
        conversation.title = "Image Uploaded";
      } else {
        conversation.title =
          message.slice(0, 30) + (message.length > 30 ? "..." : "");
      }
    }

    await conversation.save();

    res.json({
      reply: reply.content,
      conversationId: conversation._id,
      title: conversation.title,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Something went wrong" });
  }
};

// get all chats
exports.getConversations = async (req, res) => {
  const { userId } = req.params;

  try {
    if (!userId) {
      return res.status(400).json({ error: "UserId is required" });
    }

    const conversations = await Conversation.find({ userId })
      .sort({ updatedAt: -1 })
      .select("_id title createdAt updatedAt messages");

    res.json({ conversations });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch conversations" });
  }
};

exports.getConversation = async (req, res) => {
  const { conversationId } = req.params;

  try {
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({ error: "Conversation not found" });
    }

    res.json({ conversation });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch conversation" });
  }
};

exports.updateTitle = async (req, res) => {
  const { conversationId } = req.params;
  const { title } = req.body;

  try {
    if (!title) {
      return res.status(400).json({ error: "Title is required" });
    }

    const conversation = await Conversation.findByIdAndUpdate(
      conversationId,
      { title },
      { new: true }
    );

    if (!conversation) {
      return res.status(404).json({ error: "Conversation not found" });
    }

    res.json({ conversation });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to update title" });
  }
};

// Delete conversation
exports.deleteConversation = async (req, res) => {
  const { conversationId } = req.params;

  try {
    const conversation = await Conversation.findByIdAndDelete(conversationId);
    if (!conversation) {
      return res.status(404).json({ error: "Conversation not found" });
    }

    res.json({ message: "Conversation deleted successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to delete conversation" });
  }
};
