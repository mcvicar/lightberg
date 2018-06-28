# Lightberg

Lightberg is a proof of concept using [Google's lighthouse](https://github.com/GoogleChrome/lighthouse) with [AWS Lambda](https://aws.amazon.com/lambda/) and [Terraform](https://www.terraform.io) to create an automated way to test and review many sites at once.

The basic set up for this _should be_;
* Update vars.tf with your own bucket names
* Run the terraform plan
* Post the JSON to AWS API Gateway (see [lambda_example_events/api_example.json](blob/master/lambda_example_events/api_example.json))
* Get back both the HTML and JSON reports for each URL
* Get an overall report HTML page linking to each report
* Profit!?

I say should be as the terraform plan is very much a work in progress, but the individual lambda functions work, but do require you to manually set up the SNS topic and step functions.

## Architecture
The architecture is pretty straight forward.
* JSON Posted to AWS API Gateway
* AWS API Gateway to a lambda function that parses the JSON and kicks off a fanout function
* Fanout function generates both HTML and JSON reports into different (if you like) S3 buckets
  * The Fanout lambda function is basically just https://github.com/joytocode/lighthouse-lambda
  * Each URL report filename is based on [uuid v5 URL domain](https://en.wikipedia.org/wiki/Universally_unique_identifier#Versions_3_and_5_(namespace_name-based)), so there shouldn't be clashes
* Step function creates an overview report so you can navigate the results. This is saved at the root of the HTML S3 Bucket (index.html)

## Example JSON to post
A simple example of the JSON to post. By default you need a "project" (in this case "example.com" or "example.org") and an array of URLs and names for the URL within that project.
```
{[
  "example.com": {
    "urls":[
      {
        "url": "https://www.example.com/",
        "name": "Homepage"
      },
      {
        "url": "https://www.example.com/foobar",
        "name": "Foobar Example"
      }
    ]
  },
  "example.org": {
    "urls":[
      {
        "url": "https://www.example.org/",
        "name": "Homepage"
      },
      {
        "url": "https://www.example.org/foobar",
        "name": "Foobar Example"
      }
    ]
  }
]}
```

## Remember this is a proof of concept!
I can not stress this enough, this is a **proof of concept**. AWS has many hard and soft limits on many of the systems used (e.g total number of concurrent Lambda process that can run in parallel, size of the **decompressed** lambda function, etc). I've not set any limits to stop you from hitting them.
Please, _please_, make sure your API Gateway has a some form of security on it. Don't try an put all the URLs from 100 of your favourite site's sitemap.xml file into this. Finally, if you suddenly find you're in debt to AWS for lots of cash and blame this system for that, I can only suggest setting up alarm billing as something **you need to do right now**.

## TODO
* Get SNS fanout, the summary step function and API gateway into terraform and safely into the lambda function...
* Add in [AWS Quicksight](https://aws.amazon.com/quicksight/) into Terraform and create a default dashboard based on the JSON reports so you can track over time, etc.
* Likely change the system when lighthouse v3 gets released.
