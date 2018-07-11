const createLighthouse = require('lighthouse-lambda')
const AWS = require('aws-sdk');

function uploadReport(dest, file, report)
{
  var params = {Bucket: dest, Key: file, Body: report};
  var s3bucket = new AWS.S3();
   s3bucket.putObject(params, function(err, data) {
       if (err) {
           console.log("Error uploading data: " + err);
       } else {
           res.writeHead(200, {'Content-Type':'text/plain'});
           res.write("Successfully uploaded report to " + dest);
       }
   });
}

exports.handler = function (event, context, callback) {
  Promise.resolve()
    .then(() => createLighthouse(event.Sns.url, { logLevel: 'info' }))
    .then(({ chrome, start, createReport }) => {
      return start()
        .then((results) => {
          const htmlReport = createReport(results);
          console.log(htmlReport);
          console.log(results);
          uploadReport(event.Sns.htmlDest, "index.html", htmlReport);
          uploadReport(event.Sns.jsonDest, "index.json", JSON.stringify(results));
          return chrome.kill().then(() => callback(null))
        })
        .catch((error) => {
          // Handle errors when running Lighthouse
          console.log(error);
          return chrome.kill().then(() => callback(null))
        })
    })
    // Handle other errors
    .catch(callback)
}
