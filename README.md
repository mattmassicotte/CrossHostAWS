# CrossHostAWS

Host [CrossHost](https://github.com/mattmassicotte/CrossHost) on AWS serverless infrastructure.

My current hope is to use S3 and Keyspaces if I can pull it off, falling back to Dynamo if I cannot.

> [!WARNING]
> Super early phase and currently non-functional.

## Building

- [Install swiftly](https://www.swift.org/install/macos/)
- `swiftly install latest`
- [Install Static Linux SDK Bundle](https://www.swift.org/install/macos/#swift-sdk-bundles)
- `./scripts/build.sh`

## Deploying

Not easy, but *probably* possible. I recognize this is sub-optimal.


This is based on [CloudFormation](https://docs.aws.amazon.com/cloudformation/), which automates managing all of the AWS resources needed. There are a lot, and the arragement is non-trivial. It possible that after creation, fully-automated destruction of all the resources may not be possible. CloudFormation can be tricky.

Before you begin, there are a few things that are not automatable and require manual work. You'll need:

- a domain name
- an S3 bucket for deployment resources
- A RSA-256 Key
- A P256 Key

Currently, the private keys needed by this system are poorly managed. [AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) could be used here, but it adds per-key cost, so for now I'm living dangerously.

- Build the Lambda Layer, copy it to your deploy bucket
- Build the Lamda executables, copy them to your deploy bucket
- Copy `CrossHostAWS.yml` to your deploy bucket

At this point you can create a the CrossHost CloudFormation stack. It **cannot** complete without manual intervention. You will have to add DNS validation for the SSL certificate created by the stack. You can view the needed information within "Certificate Manager". If you are using Route 53 for your domain, you can add the validation records with one click. Otherwise, you have to do it manually via your registar.

## Contribution and Collaboration

I would love to hear from you! Issues or pull requests work great. A [Discord server][discord] is also available for live help, but I have a strong bias towards answering in the form of documentation.

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).

[matrix]: https://matrix.to/#/%23chimehq%3Amatrix.org
[matrix badge]: https://img.shields.io/matrix/chimehq%3Amatrix.org?label=Matrix
[discord]: https://discord.gg/esFpX6sErJ
