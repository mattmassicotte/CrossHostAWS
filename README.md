# CrossHostAWS

Host [CrossHost](https://github.com/mattmassicotte/CrossHost) on AWS Lambda.

My current hope is to use S3 and Keyspaces if I can pull it off, falling back to Dynamo if I cannot.

> [!WARNING]
> Super early phase and currently non-functional.

## Instructions

- Install swiftly
- Install Swift Linux SDK

- set `AWS_REGION` environment variable
- `sh build.sh`
- `sh upload.sh my.bucket.com`

Use CloudFormation to set up "CrossHostAWS.yml"

## Contribution and Collaboration

I would love to hear from you! Issues or pull requests work great. A [Discord server][discord] is also available for live help, but I have a strong bias towards answering in the form of documentation.

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).

[matrix]: https://matrix.to/#/%23chimehq%3Amatrix.org
[matrix badge]: https://img.shields.io/matrix/chimehq%3Amatrix.org?label=Matrix
[discord]: https://discord.gg/esFpX6sErJ
