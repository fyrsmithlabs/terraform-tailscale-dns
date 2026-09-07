terraform {
  required_version = ">= 1.5"

  required_providers {
    # Manages the tailnet's Split DNS so the cluster zone resolves over the
    # tailnet (to the in-cluster resolver) and nowhere else. Kept on the same
    # constraint as the terraform-tailscale-github-wif component so a stack
    # using both resolves one lockfile-compatible provider version.
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.29"
    }
  }
}
