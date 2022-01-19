# nft-batch-upload

Test project to upload multiple assets into Ethereum (Ropsten) as ERC-721. It takes a JSON file where it has links to an image and generate both image hash in Pinata and create a JSON for it. Again, the JSON gets pinned in Pinata and gets a new hash which can be used for minting.

## Setup .env

```
PINATA_API_KEY=1e9ea7e768e00ffaa154
PINATA_SECRET_API_KEY=457c241cf457c51f85681ef3252e62cede58da5b88e67c51da54ae1aa80e134b
```
## Run

```bash
ruby batch.rb
```