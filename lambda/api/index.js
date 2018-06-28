'use strict';
const uuidv5 = require('uuid/v5');
const AWS = require('aws-sdk');
const variables = require("./vars.tfvars");

exports.handler = function (event, context, callback) {
  const reportDest = new Date().toISOString();

  /**
   * I'm making the assumption that the report buckets exist, not sure that's
   * the greatest idea.
  **/

  // loop each "project"
  for (const project of Object.keys(event)) {
      for (var i = 0; i < event[project].urls.length; i++){
        var urlHash = uuidv5(event[project].urls[i].url, uuidv5.URL);
        event[project].urls[i].urlHash = urlHash;
        event[project].urls[i].htmlDest = htmlReportBucket + "/" + reportDest + "/" + project + "/" + urlHash;
        event[project].urls[i].jsonDest = jsonReportBucket + "/" + reportDest + "/" + project + "/" + urlHash;

        // Send event[project].urls[i] to fanout (processor/index.js)
      }
  }
  // Pass to Step function for has report/index.js as next step
  callback(null, event);
}
