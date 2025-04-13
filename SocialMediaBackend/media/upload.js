const fs = require("fs");
const async = require("async");
const requestHelper = require("./requestHelper");
const fileHelper = require("./fileHelper");

const mediaUpload = {};

mediaUpload.uploader = (req, res, next) => {
  try {
    const userId = req.userId;
    const files = req.files;

    if (!files || !req.body.entityType) return next();

    const uploadTasks = [];

    // Function to handle a single file upload
    const handleFileUpload = (file, fileType, callback) => {
      const formData = {
        [fileType]: {
          value: fs.createReadStream(file.tempFilePath),
          options: {
            filename: file.name,
            contentType: file.mimetype,
          },
        },
        entityType: req.body.entityType,
        userId: userId,
      };

      const uploadUrl = `${process.env.MEDIA_SERVICE}/${fileType}/upload`;

      requestHelper.uploadFormDataFileSingle(uploadUrl, formData, (err, result) => {
        if (err) {
          console.error(`Error uploading ${fileType}:`, err);
          return callback(err);
        }

        // Delete the file after upload
        fileHelper.singleDelete(file.tempFilePath, (deleteErr) => {
          if (deleteErr) {
            console.error("Error deleting file after upload:", deleteErr);
          }
        });

        if (result && result.success) {
          callback(null, { url: result?.s3Url, type: fileType });
        } else {
          callback(new Error("Error processing uploaded file"));
        }
      });
    };

    // Process images
    if (files.image) {
      const imageFiles = Array.isArray(files.image) ? files.image : [files.image];
      imageFiles.forEach((file) => {
        uploadTasks.push((cb) => handleFileUpload(file, "image", cb));
      });
    }

    // Process videos
    if (files.video) {
      const videoFiles = Array.isArray(files.video) ? files.video : [files.video];
      videoFiles.forEach((file) => {
        uploadTasks.push((cb) => handleFileUpload(file, "video", cb));
      });
    }

    // Run upload tasks in parallel (max 5 at a time)
    async.parallelLimit(uploadTasks, 5, (err, results) => {
      if (err) {
        console.error("Error in media upload:", err);
        return res.status(500).json({ success: false, message: "Media upload failed", error: err.message });
      }

      req._media = results.filter((file) => file !== null); // Store uploaded file info in request
      next();
    });
  } catch (error) {
    console.error("Error in media upload:", error);
    return res.status(500).json({ success: false, message: "Media upload failed", error: error.message });
  }
};

module.exports = mediaUpload;
