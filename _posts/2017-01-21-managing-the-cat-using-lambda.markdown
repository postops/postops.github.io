---
title: Managing the cat using lambda
description: revisiting my first post in lambda
image: http://www.postops.co/images/posts/lambda-post/lambda-cat.png
date: 2017-01-21 21:06:56
categories: [lambda, iot]
tags: [lambda, serverless , fun, botvac, neato]
---

Okay, so it's been some time since I have posted....


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
