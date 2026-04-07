#cloud-config
package_update: true
package_upgrade: true

packages:
  - docker.io
  - git

runcmd:
  - systemctl enable docker
  - systemctl start docker
  - usermod -aG docker ${admin_username}

final_message: "cloud-init finished. Docker is installed. Deploy: git clone your repo, cd PeEx-tasks, docker build -t peex . && docker run -d -p 5000:5000 peex"
