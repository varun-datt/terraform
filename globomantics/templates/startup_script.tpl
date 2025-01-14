#! /bin/bash
sudo amazon-linux-extras install -y nginx1
sudo service nginx start
sudo rm /usr/share/nginx/html/index.html
aws s3 sync s3://${s3_bucket_name}/${contents_base_folder} /tmp/website
sudo cp -r /tmp/website/* /usr/share/nginx/html/
