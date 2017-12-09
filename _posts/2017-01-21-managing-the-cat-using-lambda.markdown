---
title: Managing the cat using lambda
description: revisiting my first post in lambda
image: http://www.postops.co/images/posts/lambda-post/lambda-cat.png
date: 2017-01-21 21:06:56
categories: [lambda, iot]
tags: [lambda, serverless , fun, botvac, neato]
crosspost_to_medium: false
---

Okay, so it's been some time since I posted my original article about controlling your neato botvac by creating Packer image and eventually deploying it using Terraform. Since my original post, I decided to throw out the whole Packer thing. It doesn't really make all that much sense to manage our own AMI for our Botvac. Instead, we can go the serverless route, while still taking advantage of Terraform. With a bit of Node.js, I was able to streamline the Botvac control process, while also utilizing the AWS API Gateway. In this post I am going to go through the Lambda function I created, how I deployed it and the AWS API Gateway using Terraform, and how I used the Maker service in IFTTT to start the Botvac in a particular area once a motion sensor is triggered. So let's get started.


The Lambda Function:
{% highlight javascript %}
exports.handler = (event, context, callback) => {
  var email = event.email;
  var password = event.password;

  var botvac = require('node-botvac');

  var client = new botvac.Client();
  //authorize
  client.authorize(email, password, true, function (error) {
      if (error) {
          console.log(error);
          return;
      }
      //get your robots
      client.getRobots(function (error, robots) {
          if (error) {
              console.log(error);
              return;
          }
          if (robots.length) {
              //do something
              robots[0].startSpotCleaning(true,'100','100',false, function (error, result) {
                 console.log(result);
              });
          }
      });
  });
}
{% endhighlight %}
