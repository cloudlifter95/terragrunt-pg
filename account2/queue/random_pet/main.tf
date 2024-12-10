provider "random" {
  # Configuration for the random provider if needed
}

resource "random_pet" "this" {
  length = 1
  keepers = {
    uuid = uuid()
  }
}

