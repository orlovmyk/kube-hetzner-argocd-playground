
# variables
# specified in .env file as TF_VAR_var_name
variable "cloudflare_api_token" {
  type = string
}

variable "microos_x86_snapshot_id" {
  type = string
}

variable "microos_arm_snapshot_id" {
  type = string
}

variable "global_domain" {
  type = string
}

variable "network_ipv4_cidr" {
  type = string
}