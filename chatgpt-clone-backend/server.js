const express = require("express");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const cors = require("cors");

dotenv.config();

const app = express();
app.use(express.json());
app.use(
  cors({
    origin: "*",
  })
);
app.get("/api/ping", (req, res) => {
  console.log("Ping received");
  res.json({ status: "alive", timestamp: new Date() });
});
app.use((req, res, next) => {
  console.log(`[${req.method}] ${req.url}`);
  next();
});
app.get("/", (req, res) => {
  console.log("GET / hit");
  res.send("Server is alive");
});

// chat route
const chatRoutes = require("./routes/chatRoutes.js");
app.use("/api", chatRoutes);

// image upload route
const uploadRoutes = require("./routes/uploadRoutes");
app.use("/api", uploadRoutes);

mongoose
  .connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => {
    console.log("MongoDB connected");
    const PORT = process.env.PORT || 5050;
    app.listen(5050, "0.0.0.0", () => {
      console.log("Server running on http://0.0.0.0:5050");
    });
  })
  .catch((err) => console.error("MongoDB error:", err));
