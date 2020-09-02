class CfnGuard < Formula
  desc "A set of tools to check AWS CloudFormation templates for policy compliance using a simple, policy-as-code, declarative syntax"
  homepage "https://github.com/aws-cloudformation/cloudformation-guard"

  # curl -s https://api.github.com/repos/aws-cloudformation/cloudformation-guard/tags | jq .[0]
  # curl -sL https://github.com/aws-cloudformation/cloudformation-guard/archive/$(curl -s https://api.github.com/repos/aws-cloudformation/cloudformation-guard/tags | jq -r .[0].name).tar.gz | sha256sum
  VERSION = "v0.7.0-beta"
  url "https://github.com/aws-cloudformation/cloudformation-guard/archive/#{VERSION}.tar.gz"
  sha256 "770c7ee27877efbe6c9d87a0a0aa790d0563ace91c7abdcf1b33a94205e7abe8"

  head "https://github.com/aws-cloudformation/cloudformation-guard.git"

  depends_on "rust"

  def install
    system "make", "cfn-guard", "cfn-guard-rulegen"
    bin.install "bin/cfn-guard" => "cfn-guard"
    bin.install "bin/cfn-guard-rulegen" => "cfn-guard-rulegen"
  end

  test do
    assert_match "#{VERSION.delete("v").sub!(/-.+/, "")}", shell_output("#{bin}/cfn-guard --version", result = 0)
    assert_match "SUBCOMMANDS:\n    check      Check CloudFormation templates against rules",
                  shell_output("#{bin}/cfn-guard --help", result = 0)
    assert_match "Check CloudFormation templates against rules\n",
                  shell_output("#{bin}/cfn-guard check --help", result = 0)

    (testpath/"ebs_volume_template.yaml").write <<~EOS
      Resources:
        NewVolume:
          Type: AWS::EC2::Volume
          Properties:
              Size: 100
              Encrypted: false
              AvailabilityZone: us-east-1b
        NewVolume2:
          Type: AWS::EC2::Volume
          Properties:
              Size: 99
              Encrypted: true
              AvailabilityZone: us-east-1b
      EOS
    (testpath/"ebs_volume_rule_set").write <<~EOS
      let encryption_flag = true
      let disallowed_azs = [us-east-1a,us-east-1b,us-east-1c]
      
      AWS::EC2::Volume AvailabilityZone NOT_IN %disallowed_azs
      AWS::EC2::Volume Encrypted != %encryption_flag
      AWS::EC2::Volume Size == 101 |OR| AWS::EC2::Volume Size == 99 |OR| AWS::EC2::Volume Size >= 101
      AWS::IAM::Role AssumeRolePolicyDocument.Version == 2012-10-18
      AWS::EC2::Volume AvailabilityZone != /us-east-.*/
    EOS
    assert_match "Number of failures: 8\n", 
                  shell_output("#{bin}/cfn-guard check -t ./ebs_volume_template.yaml -r ./ebs_volume_rule_set", result = 2)

    assert_match "#{VERSION.delete("v").sub!(/-.+/, "")}", shell_output("#{bin}/cfn-guard-rulegen --version", result = 0)
    assert_match "Generate cfn-guard rules from a CloudFormation template\n",
                  shell_output("#{bin}/cfn-guard-rulegen --help", result = 0)
  end
end
