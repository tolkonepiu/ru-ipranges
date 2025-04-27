# RU IP Ranges

This repository contains a list of IPv4 and IPv6 subnets for popular Russian resources. It is designed to help with network configurations, filtering, and analysis.

## Structure

- Each folder corresponds to a specific resource (e.g., `ya.ru`, `vk.com`, `rt.ru`).
- Subnets are divided into `ipv4.txt` and `ipv6.txt` files for each resource.
- `asn.txt` files contain the Autonomous System Numbers (ASNs) associated with the resource.
- `ipv4-merged.txt` and `ipv6-merged.txt` contain deduplicated and aggregated IPv4 and IPv6 subnets for each resource.
- `ipv4-all.txt` and `ipv6-all.txt` contain all IPv4 and IPv6 addresses from all resources combined.
- `ipv4-all-merged.txt` and `ipv6-all-merged.txt` contain deduplicated and aggregated IPv4 and IPv6 subnets from all resources.

## Automation

The repository is updated daily using a GitHub Actions workflow. The workflow fetches the latest subnets for the ASNs listed in the repository.

## Usage

You can use the subnet lists for:

- Configuring firewalls or access control lists.
- Analyzing traffic patterns.
- Blocking or allowing traffic to specific resources.

## Contributing

Feel free to submit pull requests or open issues if you find any discrepancies or have suggestions for improvement.
