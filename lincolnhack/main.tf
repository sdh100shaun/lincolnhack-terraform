resource "digitalocean_tag" "web" {
  name = "web"
}

resource "digitalocean_droplet" "lincolnhack" {
  name               = "lincolnhack"
  size               = "1gb"
  image              = "centos-7-x64"
  region             = "lon1"
  ipv6               = true
  tags   = ["${digitalocean_tag.web.id}"]
  ssh_keys = [
      "${var.ssh_fingerprint}"
    ]
  private_networking = true
  provisioner "remote-exec" {
     inline = [
       "export PATH=$PATH:/usr/bin",
       "yum -y update",
       "curl -sSL https://agent.digitalocean.com/install.sh | sh"
     ],
    connection {
    type     = "ssh"
    user     = "root"
    private_key = "${file(var.pvt_key)}"
      }
   }
}

resource "digitalocean_floating_ip" "lincolnhack" {
  droplet_id = "${digitalocean_droplet.lincolnhack.id}"
  region     = "${digitalocean_droplet.lincolnhack.region}"
}

resource "digitalocean_firewall" "lincolnhack" {
  name = "only-22-80-and-443"

  droplet_ids = ["${digitalocean_droplet.lincolnhack.id}"]

  inbound_rule = [
    {
      protocol           = "tcp"
      port_range         = "22"
      source_addresses   = ["192.168.1.0/24", "2002:1:2::/48","${var.localIP}"]
    },
    {
      protocol           = "tcp"
      port_range         = "80"
      source_addresses   = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol           = "tcp"
      port_range         = "443"
      source_addresses   = ["0.0.0.0/0", "::/0"]
    },
  ]

  outbound_rule = [
    {
      protocol                = "tcp"
      port_range              = "443"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol                = "tcp"
      port_range              = "80"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol                = "udp"
      port_range              = "53"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
    },
  ]
}
