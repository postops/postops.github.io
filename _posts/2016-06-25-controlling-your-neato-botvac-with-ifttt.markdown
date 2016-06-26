---
title: Controlling your Neato Botvac with IFTTT - Part 1
description: Keeping the cat off the couch with a bit of Terraform, Packer, and IFTTT magic
image: "http://www.postops.co/images/posts/botvac-post/this-has-gotta-stop.jpg"
date: 2016-06-25 12:22:52
categories: [iot,terraform]
tags: [terraform,packer,api,iot,botvac,cats]
---

Natalie and I just recently moved into a new home and rather than move everything we decided it was about time to just up and replace most of our furniture. Along with some of the new furniture purchased, we agreed that we should invest in technology that would help automate our lives. It was quickly determined, that we both hate vacuuming. It doesn't take long for your floors to be covered in loose hair when you live with two cats and a dog, so we headed out to buy a robot vacuum the second day of living in the new home.

### The purchase
After lots of discussion and comparing products, we decided to go with the Neato Botvac. We chose the Neato mostly because of it's square design (for corners), price point, and vacuuming power. We took it home, unboxed it, and got it all setup on our network.

![The Neato](/images/posts/botvac-post/botvac.jpg)

It was beautiful. No more vacuuming. Well.. No more daily vacuuming. A serious vacuuming is due from time to time. I was excited to say the least. I even gave my vacuum the fitting name of "Jarvis". I am not a big Iron Man fan, but felt this thing was going to be about as transformative as Tony Stark's AI companion.

![The real Jarvis](/images/posts/botvac-post/real-jarvis.jpg)

### One week in
Jarvis was doing his job of keeping our home clean and the whole process began to feel a bit routine. Jarvis would fire up about 10 AM every morning, scare all the animals into my office, and leave the floors hair free after about an hour or so. I began to feel a bit bored with Jarvis and it started to feel as if Jarvis wasn't really living up to his name. Great. Vacuum runs at 10 AM, cleans floors, and goes to sleep. Surely Jarvis' life was meant for more greatness than this. I started looking around the house for potential problems Jarvis could solve. Bring me coffee? Yeah that wouldn't work. Any idea I came up with seemed super impractical and novel at best. Little did I know the problem was staring me straight in the face for several years.

### The Perpetrator
![Roly Poly](/images/posts/botvac-post/the-perpetrator.jpg)
This is my cat, Roly Poly. Roly Poly hasn't always had the easy life. I found her on the streets several years back in Oklahoma City. Once we met, she immediately adopted me. She followed me pretty much everywhere and it wasn't long before she decided to move into my place. Poly is a sweet cat, don't get me wrong, but one of her favorite things to do is destroy things. Among the things she enjoys destroying, couches definitely tops the list. This was one of the main reasons, Natalie and I, decided to get new furniture when moving. Previously we stuck with cheaper couches from IKEA, as we knew Poly was going to tear it up in due time. When we moved into our first house, we went out and made a significant investment on a couch and made a pack that we would keep the animals away from the furniture.

It wasn't long before Poly noticed the couch.

![Poly laying on our new couch](/images/posts/botvac-post/this-has-gotta-stop.jpg)

### This had to stop
I was determined to make sure Poly would not destroy the couch. I would pick her up and move her off every time she hopped on, tell her no when I saw her pulling her self across the floor anchored into the couch, and the whole thing began to get exhausting. Plus I could only keep an eye on her during my waking hours. At night, she had free reign with the couch, while I slept trying not to think about it.

Then it hit me! The animals hated Jarvis. Ever since we purchased Jarvis, the animals would run into the other room every time 10 AM rolled around and they heard him revving up his motor. Robots and cats do not exactly live in harmony. I decided to use this to my advantage and set out to use Jarvis to keep Poly off the couch.

### The problem
Out of the box, Neato Botvacs are only controllable via a smart phone or using some pre-defined schedule. Lame. I did some search, surely thinking this thing has some sort of publicly documented API. Sadly, it did not. If I was going to automate this thing, I knew the first thing I needed to be able to do, was control this thing outside of the app that Neato provided. While the Neato app is great for performing on-demand actions and scheduling, it provides pretty limited functionality outside of that:

![Neato App](/images/posts/botvac-post/neato-screenshot.png)

I knew there had to be a way to control this thing outside of the app and headed over to Github for some quick searching. Low and behold, someone figured it out. I stumbled up [kangguru/botvac](https://github.com/kangguru/botvac), an "unofficial" API client for interacting with the Neato botvac. Awesome sauce! Essentially, this client, forwarded requests to Neato's secret/undocumented API at [https://nucleo.neatocloud.com](https://nucleo.neatocloud.com) using the proper [certificate](https://github.com/kangguru/botvac/blob/master/cert/neatocloud.com.crt) and your Botvac's Serial and Secret collected from [https://beehive.neatocloud.com/](https://beehive.neatocloud.com/) after authentication. For more information on how this works, I highly suggest digging through the repository yourself and taking a look. Thank you kangguru for reverse engineering this, so I didn't have to.

### Getting the Serial and Secret
Following along with the repo's README, the first step was getting my Botvac's serial and secret. This was pretty straight-forward. First I installed the `botvac` gem and used `botvac robots` from the CLI to get the serial and secret. The email and password used is the same I used when setting up my Neato Botvac for the first time.

{% highlight console %}
$ gem install botvac
$ botvac robots

Email: EmailHere
Password: OnlyYouKnowThis

Robot (BotVacConnected) => Serial: OPSXXXX-XXXXX Secret: XXXXXXXX
{% endhighlight %}

It's important to make note of both the Serial and Secret.

### Running Locally? Nah.
So at this point, I could run the web server locally and make API requests simply by hitting localhost, but I'd rather deploy it somewhere. This API needs to be publicly accessible for a number of reasons I will point out later. It's worth noting, that using the setup I will go over, one essentially exposes the Botvac to any one who has the URL of the API.

For those who want to run locally, it's just as easy as Cloning the repo, setting some env variables, starting the webserver, and making requests.

{% highlight console %}
$ git clone git@github.com:kangguru/botvac.git
$ cd botvac
$ export SERIAL=OPSXXXX-XXXXX
$ export SECRET=XXXXXXXX
$ rackup -r 'botvac/web' -b "run Botvac::Web.new"
$ curl http://localhost:9292/get_robot_state
{% endhighlight %}

This was sufficient enough for working locally, but I opted to deploy to AWS.

### Taking a look at my deployment
I opted to use Packer and Terraform to deploy my API to AWS. I will review each component in a bit more detail, but here's a quick overview of how that project is laid out:

{% highlight plaintext %}
├── packer
│   ├── jarvis.json
│   └── scripts
│       └── installer.sh
├── shared
│   ├── generate_key_pair.sh
│   ├── main.tf
│   └── ssh_keys
│       ├── jarvis.pem
│       └── jarvis.pub
└── terraform
    ├── firewalls.tf
    ├── instances.tf
    ├── keypairs.tf
    ├── main.tf
    └── networks.tf
{% endhighlight %}

The repo in it's entirety is available at [mootpt/jarvis](https://github.com/mootpt/jarvis)

### Packer
Let's first take a look at my [Packer template](https://github.com/mootpt/jarvis/blob/master/packer/jarvis.json). If you are not familiar with Packer, I highly recommend checking out the [tool](https://www.packer.io/). Essentially, I use Packer to build the AMI which will be used for my Botvac infrastructure. It's pretty straightforward for the most part, but I will take the time to walk through each block and the associated scripts.

The variables block:

{% highlight json %}
"variables": {
  "aws_access_key": "{% raw  %}{{env `AWS_ACCESS_KEY_ID`}}{% endraw  %}",
  "aws_secret_key": "{% raw  %}{{env `AWS_SECRET_ACCESS_KEY`}}{% endraw  %}"
}
{% endhighlight %}

In the above code snippit, I have specified that there are a few variables that are important to my build. These variables will be pulled from my local environment variables and used throughout my build template. `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are used to access my AWS account to build and store the AMI.

I then set these environment variables:

{% highlight console %}
$ export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
$ export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
{% endhighlight %}

The builders block:

{% highlight json %}
"builders": [{
  "type": "amazon-ebs",
  "access_key": "{% raw  %}{{user `aws_access_key`}}{% endraw  %}",
  "secret_key": "{% raw  %}{{user `aws_secret_key`}}{% endraw  %}",
  "region": "us-east-1",
  "source_ami": "ami-e0efab88",
  "instance_type": "t2.micro",
  "ssh_username": "admin",
  "ami_name": "jarvis {% raw  %}{{timestamp}}{% endraw  %}"
}]
{% endhighlight %}

In the above snippit, I have specified the `type` of builder I want to use for creating my AMI, `amazon-ebs`. The AWS builder requires both a `access_key` and `secret_key`, which I am populating using the variables from the variables block. I have specified the `region` for my build, `us-east-1`, the `source_ami` I wish to start with (_note: ami-e0efab88 is pretty much a vanilla Debian Wheezy image_), the `instance_type` or size I wish to use for my build, `t2.micro`. I have also passed in the `ssh_username` for the box and provided an `ami_name` for reference (_note: this is not the AMI name I use in Terraform_).

The provisioners block:

{% highlight json %}
"provisioners": [
{
    "type": "shell",
    "script": "scripts/installer.sh"
}
]
{% endhighlight %}

In the above, I essentially tell the machine I want to run a shell script on the builder. The shell script is as follows:

{% highlight bash %}
#!/bin/bash
sudo apt-get -y update
sudo apt-get install -y ruby rubygems rails
sudo gem install botvac
{% endhighlight %}

Essentially the script installs the `botvac` gem and any necessary dependencies.

All that was left was for me to download Packer and build my template. Packer can be downloaded from the [Packer Downloads Page](https://www.packer.io/downloads.html) and added to your path. Once downloaded and added to my path, all that was left was to build the template.

{% highlight console%}
$ packer build jarvis.json
{% endhighlight %}

<script type="text/javascript" src="https://asciinema.org/a/86rsn9i5rp4qtseu6s414d61y.js" id="asciicast-86rsn9i5rp4qtseu6s414d61y" async></script>

With the brand new AMI built and stored, I was one step closer to keeping the cat off the couch. Join me next time, when I build some infrastructure using [Terraform](https://www.terraform.io) with my newly created AMI. I will then conclude this three part series with IFTTT magic and the end results.
