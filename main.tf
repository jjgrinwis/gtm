terraform {
  required_providers {
    akamai = {
      source = "akamai/akamai"
    }
  }
}

# using credentials for the Akamai GSS training environment
provider "akamai" {
  edgerc         = "~/.edgerc"
  config_section = "gss_training"
}

# using akamai_contract to lookup group and contract id
data "akamai_contract" "contract" {
  group_name = var.group_name
}

# first create a GTM domain, the basic building block
# using default contract_id!
resource "akamai_gtm_domain" "gtm_domain" {
  contract         = data.akamai_contract.contract.id
  group            = data.akamai_contract.contract.group_id
  name             = var.gtm_domain
  type             = "basic"
  comment          = "Created by Terraform"
  wait_on_complete = false
}

# an existing gtm_domain resource example which can be imported via:
# $ terraform import akamai_gtm_domain.tf-jgrinwis tf-jgrinwis.akadns.net
resource "akamai_gtm_domain" "tf-jgrinwis" {
  contract         = data.akamai_contract.contract.id
  group            = data.akamai_contract.contract.group_id
  name             = "tf-jgrinwis.akadns.net"
  type             = "basic"
  comment          = "Created by Terraform"
  wait_on_complete = false
}

# add some DC's to our GTM domain
resource "akamai_gtm_datacenter" "dc_hoorn" {
  domain            = resource.akamai_gtm_domain.gtm_domain.name
  nickname          = "Koens place"
  city              = "Hoorn"
  country           = "NL"
  state_or_province = "NH"
  wait_on_complete  = false
}

resource "akamai_gtm_datacenter" "dc_vinkeveen" {
  domain            = resource.akamai_gtm_domain.gtm_domain.name
  nickname          = "Johns place"
  city              = "Vinkeveen"
  state_or_province = "UTR"
  country           = "NL"
  wait_on_complete  = false
}

# lookup the default datacenter for a GTM domain
# for the 'maps' the default id will be 5400, ip-selector 5401 and ip-version 5402
# default is 5400 (maps)
data "akamai_gtm_default_datacenter" "example_ddc" {
  domain = resource.akamai_gtm_domain.gtm_domain.name

}

# cidr map with the default DC and our two other DC's with subnets assigned to it.
resource "akamai_gtm_cidrmap" "demo_cidrmap" {
  domain           = resource.akamai_gtm_domain.gtm_domain.name
  name             = "demo_cidr"
  wait_on_complete = false
  default_datacenter {
    datacenter_id = data.akamai_gtm_default_datacenter.example_ddc.datacenter_id
    nickname      = "All Other CIDR Blocks"
  }
  assignment {
    datacenter_id = resource.akamai_gtm_datacenter.dc_hoorn.datacenter_id
    nickname      = "Subnet to Hoorn"
    blocks        = ["1.1.1.0/24"]
  }
  assignment {
    datacenter_id = resource.akamai_gtm_datacenter.dc_vinkeveen.datacenter_id
    nickname      = "Subnet to Vinkeveen"
    blocks        = ["2.2.3.0/24"]
  }
}

# create a GTM resource where you attach CIDR map with CNAMEs and DC's.
resource "akamai_gtm_property" "blabla" {
  domain                    = resource.akamai_gtm_domain.gtm_domain.name
  name                      = "testing"
  type                      = "cidrmapping"
  ipv6                      = false
  score_aggregation_type    = "worst"
  use_computed_targets      = false
  balance_by_download_score = false
  dynamic_ttl               = 60
  map_name                  = resource.akamai_gtm_cidrmap.demo_cidrmap.name
  handout_limit             = 8
  handout_mode              = "normal"
  failover_delay            = 0
  failback_delay            = 0
  ghost_demand_reporting    = false
  wait_on_complete          = false
  traffic_target {
    datacenter_id = data.akamai_gtm_default_datacenter.example_ddc.datacenter_id
    enabled       = true
    weight        = 0
    servers       = []
    handout_cname = "mtls.grinwis.com"
  }
  traffic_target {
    datacenter_id = resource.akamai_gtm_datacenter.dc_hoorn.datacenter_id
    enabled       = true
    weight        = 1
    servers       = []
    handout_cname = "api.grinwis.com"
  }
  traffic_target {
    datacenter_id = resource.akamai_gtm_datacenter.dc_vinkeveen.datacenter_id
    enabled       = true
    weight        = 1
    servers       = []
    handout_cname = "demo.grinwis.com"
  }
}

resource "akamai_gtm_property" "testing2" {
  domain                    = resource.akamai_gtm_domain.gtm_domain.name
  name                      = "testing2"
  type                      = "cidrmapping"
  ipv6                      = false
  score_aggregation_type    = "worst"
  use_computed_targets      = false
  balance_by_download_score = false
  dynamic_ttl               = 60
  map_name                  = resource.akamai_gtm_cidrmap.demo_cidrmap.name
  handout_limit             = 8
  handout_mode              = "normal"
  failover_delay            = 0
  failback_delay            = 0
  ghost_demand_reporting    = false
  wait_on_complete          = false
  traffic_target {
    datacenter_id = data.akamai_gtm_default_datacenter.example_ddc.datacenter_id
    enabled       = true
    weight        = 0
    servers       = []
    handout_cname = "mtls.grinwis.com"
  }
  traffic_target {
    datacenter_id = resource.akamai_gtm_datacenter.dc_hoorn.datacenter_id
    enabled       = true
    weight        = 1
    servers       = []
    handout_cname = "api.grinwis.com"
  }
  traffic_target {
    datacenter_id = resource.akamai_gtm_datacenter.dc_vinkeveen.datacenter_id
    enabled       = true
    weight        = 1
    servers       = []
    handout_cname = "demo.grinwis.com"
  }
}
