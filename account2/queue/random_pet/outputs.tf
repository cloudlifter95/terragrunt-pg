output "random_string" {
  description = "the random string"
  value       = try(random_pet.this.id, null)
}
