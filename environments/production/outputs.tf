output "foundation_status" {
  description = "Human-readable foundation posture."
  value = {
    cloud_resources_enabled      = var.enable_cloud_resources
    production_state_initialized = false
    apply_authorized             = false
    app_platform = {
      region              = local.app_platform_region
      vpc_datacenter      = local.app_platform_vpc_datacenter
      vpc_networking      = local.app_platform_vpc_required
      dedicated_egress_ip = local.app_platform_dedicated_egress
    }
    commercial = {
      retained_usd_mo        = local.commercial_retained_usd_mo
      aistor_node_usd_mo     = local.commercial_aistor_node_usd_mo
      aistor_volumes_usd_mo  = local.commercial_aistor_volumes_usd_mo
      aistor_slice_usd_mo    = local.commercial_aistor_slice_usd_mo
      target_usd_mo          = local.commercial_target_usd_mo
      hard_ceiling_usd_mo    = local.commercial_hard_ceiling_usd_mo
      gst_basis              = local.commercial_gst_basis
      full_estate_incomplete = local.commercial_full_estate_incomplete
    }
    primary_bucket_intended = var.primary_bucket_name
    vpc_name_intended       = var.vpc_name
    vpc_cidr_candidate      = var.vpc_ip_range
    legacy_state_bucket     = "eduvijna-terraform-state"
    production_state_bucket = "eduvijna-aieos-tofu-state-prod-blr1"
  }
}

output "module_instantiation" {
  description = "Whether cloud-mutating modules are currently instantiated."
  value = {
    production_project = length(module.production_project)
    production_vpc     = length(module.production_vpc)
    aistor_bootstrap   = length(module.aistor_bootstrap)
    aistor_network     = length(module.aistor_network)
  }
}
