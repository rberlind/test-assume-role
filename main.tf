resource "null_resource" "write_credentials" {
  provisioner "local-exec" {
    command = "sudo apt-get -y install python python-pip jq"
  }
  
  provisioner "local-exec" {
    command = "sudo pip install awscli --upgrade --user"
  }

  provisioner "local-exec" {
    command = "aws sts assume-role --role-arn=arn:aws:iam::350965860658:role/ecs-nonprod-secrets-test-role --role-session-name='TFE-Apply' --region=us-east-1 >> /tmp/json_credentials"
  }

  provisioner "local-exec" {
    command = "cat /tmp/credentials | jq --exit-status --raw-output .Credentials.AccessKeyId >> /tmp/aws_access_key_id"
  }

  provisioner "local-exec" {
    command = "cat /tmp/credentials | jq --exit-status --raw-output .Credentials.SecretAccessKey >> /tmp/aws_secret_access_key"
  }

  provisioner "local-exec" {
    command = "cat /tmp/credentials | jq --exit-status --raw-output .Credentials.SessionToken >> /tmp/aws_session_token"
  }
}

data "null_data_source" "read_credentials" {
  inputs = {
    aws_access_key_id     = "${file("/tmp/aws_access_key_id")}"
    aws_secret_access_key = "${file("/tmp/aws_secret_access_key")}"
    aws_session_token     = "${file("/tmp/aws_session_token")}"
  }
  depends_on = ["null_resource.write_credentials"]
}

provider "aws" {
  region     = "us-east-1"
  access_key = "${data.null_data_source.read_credentials.aws_access_key_id}"
  secret_key = "${data.null_data_source.read_credentials.aws_access_key_id}"
  token      = "${data.null_data_source.read_credentials.aws_session_token}"
}
