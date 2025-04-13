const request = require('request');
const fs = require('fs');

const requestHelper = {};

requestHelper.uploadFormDataFileSingle = (url, formData, callback) => {
  const options = {
    method: 'POST',
    url,
    headers: {
      'Content-Type': 'multipart/form-data',
    },
    formData
  };


  request(options, (err, res, body) => {
    if (err) {
      console.log("Error uploading file:", err);
      return callback(err, null);
    }


    if (body) {
      try {
        body = JSON.parse(body);
      } catch (e) {
        console.error("Error parsing response:", e);
        return callback(e, null);
      }
    }

    
    callback(null, body);
  });
};

module.exports = requestHelper;
