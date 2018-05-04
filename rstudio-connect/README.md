# RStudio Connect

## AWS EC2 Installation

1. Log into AWS EC2 and click **Create Instance**.
2. Choose AMI
   1. Select **Amazon Linux 2 LTS Candidate** AMI 2017.12.0 (HVM), SSD Volume Type - ami-7f43f307
3. Choose Instance Type
   1. Select **M4.2xlarge** (based on [this article](https://aws.amazon.com/blogs/big-data/running-r-on-aws/) this can be changed later if/when needed)
4. Configure Instance
   1. Use defaults except for the following:
      1. IAM Role -> Create new IAM Role
         1. Click **Create Role**
         2. Select type of trusted entity
            1. Select **AWS Service**
         3. Choose the service that will use this role
            1. Select **EC2**
         4. Click **Next**
         5. Attach permissions policies
            1. Search for **EC2** and select **AmazonEC2ContainerServiceRole**
         6. Click **Next**
         7. Review
             1. Use defaults except for the following:
             2. Role Name -> rstudio-connect-server-ec2
         8. Click **Create Role**
         9. Close the IAM Management window and go back to the EC2 window.
         10. Refresh the IAM roles and select the role that was just created.
      2. Enable termination protection -> Yes
      3. Monitoring -> Yes
   2. Add Storage
      1. Use the defaults except for the following:
      2. Size (GiB) -> 30
   3. Add Tags
      1. None
   4. Configure Security Group
      1. Select **Create a new security group**
         1. Security Group Name -> rstudio-connect-server
         2. Add **SSH** with a **Source** of **Anywhere**
         3. Add **HTTPS** with a **Source** of **Anywhere**
   5. Review
      1. Click **Launch**
   6. Create a new key pair
      1. Key pair name -> rstudio_connect_server
      2. Click **Download Key Pair** into ~/.ssh
      3. Click **Launch Instances**
5. Connect to the Instance
   1. Follow [these instructions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html) to get the connection setup.
   2. SSH into the instance (change `ec2-00.00.00.00.us-west-2.compute.amazonaws.com` to your instance):
      ```bash
      ssh -i ~/.ssh/rstudio_connect_server.pem ec2-user@ec2-00.00.00.00.us-west-2.compute.amazonaws.com
      ```
6. Install packages
   1. Execute the following commands:
      ```bash
      sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
      sudo yum-config-manager --enable epel
      sudo yum install R
      wget https://s3.amazonaws.com/rstudio-connect/centos6.3/x86_64/rstudio-connect-1.5.14-6.x86_64.rpm
      sudo yum install --nogpgcheck rstudio-connect-1.5.14-6.x86_64.rpm
      sudo yum install libcurl-devel
      sudo yum install libxml2-devel
      sudo yum install java-1.7.0-openjdk-devel
      sudo R CMD javareconf
      sudo yum install openssl-devel
      sudo yum install texlive-*
      ```
7. Install the [sysreqs](https://github.com/r-hub/sysreqsdb/tree/master/sysreqs) packages:
   1. Copy [install_sysreqs.R](https://github.com/HBGDki/DevOps/tree/master/rstudio-connect/scripts/install_sysreqs.R) to the local system.
   2. Give the file execute permissions: `chmod u+rx install_sysreqs.R`
   3. Run the file: `sudo ./install_sysreqs.R`
      * Note: View the usage with `./install_sysreqs.R -h` and adjust command line arguments for your system.
   4. Manually install and configure the remaining packages:
      ```bash
      sudo yum install udunits2 udunits2-devel
      echo "C_INCLUDE_PATH=\${C_INCLUDE_PATH-'/usr/include/udunits2'}" | sudo tee --append /usr/lib64/R/etc/Renviron
      ```