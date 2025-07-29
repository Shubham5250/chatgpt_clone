const cloudinary = require("../utils/cloudinary");

exports.uploadImage = async (req, res) => {
  try {
    const file = req.file;

    if (!file) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    // the folder "chatgpt_images" contains the uploaded images from app.
    const result = await cloudinary.uploader.upload(file.path, {
      folder: "chatgpt_images",
    });

    res.status(200).json({
      url: result.secure_url,
      public_id: result.public_id,
    });
  } catch (error) {
    console.error("Upload error:", error);
    res.status(500).json({ error: "Upload failed" });
  }
};
