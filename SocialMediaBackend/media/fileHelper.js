const fs = require('fs');
const path = require('path');

const fileHelper = {};

/**
 * Deletes a file from the server
 * @param {string} filePath - The path to the file to delete.
 * @param {Function} callback - The callback to execute after deleting the file.
 */
fileHelper.singleDelete = (filePath, callback) => {
  if (!filePath) {
    return callback(new Error('No file path provided'), null);
  }

  // Check if file exists before attempting to delete
  fs.exists(filePath, (exists) => {
    if (exists) {
      // Delete the file
      fs.unlink(filePath, (err) => {
        if (err) {
          console.error('Error deleting file:', err);
          return callback(err, null);
        }
        // console.log(`File deleted: ${filePath}`);
        return callback(null, { success: true });
      });
    } else {
      console.log(`File not found: ${filePath}`);
      return callback(new Error('File not found'), null);
    }
  });
};

/**
 * Move a file to a new directory
 * @param {string} oldPath - The current file path.
 * @param {string} newPath - The target file path.
 * @param {Function} callback - The callback to execute after moving the file.
 */
fileHelper.moveFile = (oldPath, newPath, callback) => {
  if (!oldPath || !newPath) {
    return callback(new Error('Old and new file paths must be provided'), null);
  }

  // Ensure target directory exists, if not, create it
  const targetDir = path.dirname(newPath);
  fs.mkdir(targetDir, { recursive: true }, (err) => {
    if (err) {
      return callback(err, null);
    }

    // Move the file
    fs.rename(oldPath, newPath, (err) => {
      if (err) {
        console.error('Error moving file:', err);
        return callback(err, null);
      }
      console.log(`File moved from ${oldPath} to ${newPath}`);
      return callback(null, { success: true });
    });
  });
};

/**
 * Check if a file exists
 * @param {string} filePath - The path to the file to check.
 * @param {Function} callback - The callback to return the result.
 */
fileHelper.fileExists = (filePath, callback) => {
  fs.exists(filePath, (exists) => {
    return callback(null, exists);
  });
};

/**
 * Read a file's contents
 * @param {string} filePath - The path to the file to read.
 * @param {Function} callback - The callback to return the contents of the file.
 */
fileHelper.readFile = (filePath, callback) => {
  fs.readFile(filePath, 'utf8', (err, data) => {
    if (err) {
      console.error('Error reading file:', err);
      return callback(err, null);
    }
    return callback(null, data);
  });
};

module.exports = fileHelper;
