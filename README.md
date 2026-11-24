<!--
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation
-->

# 🛠️ Template Action

<!-- prettier-ignore-start -->
<!-- markdownlint-disable-next-line MD013 -->
[![Linux Foundation](https://img.shields.io/badge/Linux-Foundation-blue)](https://linuxfoundation.org/) [![Source Code](https://img.shields.io/badge/GitHub-100000?logo=github&logoColor=white&color=blue)](https://github.com/lfreleng-actions/actions-template) [![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![pre-commit.ci status badge]][pre-commit.ci results page] [![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/lfreleng-actions/actions-template/badge)](https://scorecard.dev/viewer/?uri=github.com/lfreleng-actions/actions-template)
<!-- prettier-ignore-end -->

This is a template for the other actions in this GitHub organisation.

## actions-template

## Usage Example

<!-- markdownlint-disable MD013 MD046 -->

```yaml
steps:
  - name: "Action template"
    id: action-template
    # yamllint disable-line rule:line-length
    uses: lfreleng-actions/actions-template@017a83475880686ef615160f7afdeccaf063281c  # v0.3.4
    with:
      input: "placeholder"
```

<!-- markdownlint-enable MD013 MD046 -->

Pin to the commit SHA of a published release, with its tag in a
comment; never to a branch, or to an annotated tag object's SHA. A new
action has no release until its first tag, which Release Drafter
numbers `v0.0.1`; pin to that release once it exists.

## Inputs

<!-- markdownlint-disable MD013 -->

| Name          | Required | Description  |
| ------------- | -------- | ------------ |
| input         | False    | Action input |

<!-- markdownlint-enable MD013 -->

## Outputs

<!-- markdownlint-disable MD013 -->

| Name          | Description   |
| ------------- | ------------- |
| output        | Action output |

<!-- markdownlint-enable MD013 -->

## Implementation Details

## Notes

[pre-commit.ci results page]: https://results.pre-commit.ci/latest/github/lfreleng-actions/actions-template/main
[pre-commit.ci status badge]: https://results.pre-commit.ci/badge/github/lfreleng-actions/actions-template/main.svg
