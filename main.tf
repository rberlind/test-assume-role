resource "null_resource" "write_credentials" {
  provisioner "local-exec" {
    command = "sudo apt-get -y install python python-pip jq"
  }
  
  provisioner "local-exec" {
    command = "sudo pip install awscli --upgrade --user"
  }

  provisioner "local-exec" {
    command = "aws sts assume-role --role-arn=arn:aws:iam::128997349609:role/terraform-role --role-session-name='TFE-Apply' --region=us-east-1 >> json_credentials"
  }

  provisioner "local-exec" {
    command = "cat /tmp/credentials | jq --exit-status --raw-output .Credentials.AccessKeyId >> aws_access_key_id"
  }

  provisioner "local-exec" {
    command = "cat /tmp/credentials | jq --exit-status --raw-output .Credentials.SecretAccessKey >> aws_secret_access_key"
  }

  /*provisioner "local-exec" {
    command = "cat /tmp/credentials | jq --exit-status --raw-output .Credentials.SessionToken >> aws_session_token"
  }*/
}

data "null_data_source" "read_credentials" {
  inputs = {
    aws_access_key_id     = "${file("aws_access_key_id")}"
    aws_secret_access_key = "${file("aws_secret_access_key")}"
    #aws_session_token     = "${file("aws_session_token")}"
  }
  depends_on = ["null_resource.write_credentials"]
}

provider "aws" {
  region     = "us-east-1"
  access_key = "${data.null_data_source.read_credentials.outputs[aws_access_key_id]}"
  secret_key = "${data.null_data_source.read_credentials.outputs[aws_access_key_id]}"
  #token      = "${data.null_data_source.read_credentials.outputs[aws_session_token]}"
}
