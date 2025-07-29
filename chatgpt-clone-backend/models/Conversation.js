const mongoose = require("mongoose");
const { v4: uuidv4 } = require("uuid");

const messageSchema = new mongoose.Schema(
  {
    role: {
      type: String,
      required: true,
      enum: ["user", "assistant"],
    },
    content: {
      type: String,
      default: "",
    },
    imageUrl: {
      type: String,
      default: null,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);

const conversationSchema = new mongoose.Schema(
  {
    _id: {
      type: String,
      default: uuidv4,
      required: true,
      immutable: true,
    },
    userId: {
      type: String,
      required: true,
      index: true,
    },
    model: {
      type: String,
      required: true,
      default: "gpt-4.1-nano",
    },
    title: {
      type: String,
      required: true,
      default: "New Chat",
      trim: true,
      maxlength: 100,
    },
    messages: {
      type: [messageSchema],
      default: [],
      validate: {
        validator: function (messages) {
          return messages.length <= 1000;
        },
        message: "Maximum 1000 messages per conversation",
      },
    },
    createdAt: {
      type: Date,
      default: Date.now,
      immutable: true,
    },
    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: false,
    versionKey: false,
  }
);

conversationSchema.pre("save", function (next) {
  this.updatedAt = Date.now();

  if (this.title && this.title.length > 100) {
    this.title = this.title.substring(0, 97) + "...";
  }

  next();
});

conversationSchema.index({
  title: "text",
  "messages.content": "text",
});

conversationSchema.statics.findByUUID = function (uuid) {
  return this.findOne({ _id: uuid });
};

module.exports = mongoose.model("Conversation", conversationSchema);
