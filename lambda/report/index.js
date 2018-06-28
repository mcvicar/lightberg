'use strict';
const AWS = require('aws-sdk');

const isodate = new Date().toISOString();

function generateTemplate(isodate, reports) {
  return `<html>
  <head>
    <title>Lightberg report ${isodate}</title>
    <meta generator="Lightberg v0.1" >
  </head>
  <body>
    <h1>Lightberg report ${isodate}</h1>
    <ul>${reports}</ul>
  </body>
</html>`;
}

function uploadReport(dest, file, report)
{
  var params = {Bucket: dest, Key: file, Body: report};
   s3bucket.putObject(params, function(err, data) {
       if (err) {
           console.log("Error uploading data: ", err);
       }
   });
}

exports.handler = function (event, context, callback) {

  var report = "";

  for (const project of Object.keys(event)) {
    report += "<li><h2>" + project + "</h2><ul>";

    for (var i = 0; i < event[project].urls.length; i++){
      report += "<li><h3>"+ event[project].urls[i].name + " ("+ event[project].urls[i].url +")</h3><ul>";
      report += '<li><a href="'+event[project].urls[i].htmlDest+'/index.html">HTML Report</a></li>';
      report += '<li><a href="'+event[project].urls[i].jsonDest+'/index.json">JSON Report</a></li>';
      report += "</ul></li>";
    }

    report += "</li>";
  }

  var fullReport = generateTemplate(isodate, report);
  uploadReport(htmlReportBucket, "index.html", fullReport);
  uploadReport(htmlReportBucket, "index"+isodate+".html", fullReport);

}
