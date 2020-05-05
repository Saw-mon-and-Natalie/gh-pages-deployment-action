# GitHub Pages Deployment Action

This action runs your build script on your `BASE_BRANCH` and deploys it to your GitHub pages branch.
It also keeps tab of your build/deployment changes.

## Usage

You would need to supply these `env` variables to the action.

|`env` variable | description| type | required |
|---|---|---|---|
|`ACCESS_TOKEN` or `GITHUB_TOKEN` | (Required) Your repository's deployment token, i.e. `ACCESS_TOKEN` ( `${{ secrets.GITHUB_TOKEN }}` ) or a general `GITHUB_TOKEN` with read and write permissions.| `secrets` | **YES** |
|`BASE_BRANCH` | (Optional) Base branch name. Default is `master`.| `env` | no
|`BRANCH`| (Required) The deployment branch, for example `gh-pages`.| `env` | **YES** |
|`FOLDER`| (Required) Your build folder in `BASE_BRANCH`. | `env | **YES** |
|`BUILD_SCRIPT`| (Required) Your build script/command. `node` or `npm` commands are supported.| `env` | no |
|`CNAME`| For custom subdomains | `env` | no |

### Example

```yml
on: [push]

jobs:
    deploy:
        runs-on: ubuntu-latest
        name: gh-pages deployment
        steps:
        -   name: Checkout
            uses: actions/checkout@master

        -   name: Build and deploy
            uses: Saw-mon-and-Natalie/gh-pages-deployment-action@v2.0.0
            env:
                ACCESS_TOKEN: ${{ secrets.ACCESS_TOKEN }}
                BASE_BRANCH: master
                BRANCH: gh-pages
                FOLDER: dist
                BUILD_SCRIPT: ". ./script.sh"
```