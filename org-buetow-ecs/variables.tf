variable "deploy_vault" {
  description = "Deploy Vaultwarden Server?"
  type        = bool
  default     = false
}

variable "deploy_flux" {
  description = "Deploy Miniflux Server?"
  type        = bool
  default     = false
}

variable "deploy_anki" {
  description = "Deploy Anki Sync Server?"
  type        = bool
  default     = false
}

variable "deploy_audiobookshelf" {
  description = "Deploy Audio Bool Shelf Server?"
  type        = bool
  default     = false
}

variable "deploy_bag" {
  description = "Deploy Wallabag Server?"
  type        = bool
  default     = false
}

variable "deploy_syncthing" {
  description = "Deploy Syncthing Server?"
  type        = bool
  default     = false
}

variable "deploy_nginx" {
  description = "Deploy Nginx Server?"
  type        = bool
  default     = false
}

variable "deploy_gpodder" {
  description = "Deploy Mcro GPodder Server?"
  type        = bool
  default     = true
}

variable "deploy_radicale" {
  description = "Deploy Radicale Server?"
  type        = bool
  default     = true
}

