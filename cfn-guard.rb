class CfnGuard < Formula
  desc "A set of tools to check AWS CloudFormation templates for policy compliance using a simple, policy-as-code, declarative syntax"
  homepage "https://github.com/aws-cloudformation/cloudformation-guard"

  # curl -s https://api.github.com/repos/aws-cloudformation/cloudformation-guard/tags | jq .[0]
  # curl -sL https://github.com/aws-cloudformation/cloudformation-guard/archive/$(curl -s https://api.github.com/repos/aws-cloudformation/cloudformation-guard/tags | jq -r .[0].name).tar.gz | sha256sum
  VERSION = "v0.6.0-beta"
  url "https://github.com/aws-cloudformation/cloudformation-guard/archive/#{VERSION}.tar.gz"
  sha256 "db27dd65572bfdc16894be3d9084248370ac1392d2edc998b1e72c7cd2f13322"

  head "https://github.com/aws-cloudformation/cloudformation-guard.git"

  depends_on "rust"

  def install
    system "make", "cfn-guard", "cfn-guard-rulegen"
    bin.install "bin/cfn-guard" => "cfn-guard"
    bin.install "bin/cfn-guard-rulegen" => "cfn-guard-rulegen"
  end

  test do
    assert_match "#{VERSION.delete("v").sub!(/-.+/, "")}", shell_output("#{bin}/cfn-guard --version", result = 0)
    assert_match "Check CloudFormation templates against rules\n",
                  shell_output("#{bin}/cfn-guard --help", result = 0)
    assert_match "#{VERSION.delete("v").sub!(/-.+/, "")}", shell_output("#{bin}/cfn-guard-rulegen --version", result = 0)
    assert_match "Generate cfn-guard rules from a CloudFormation template\n",
                  shell_output("#{bin}/cfn-guard-rulegen --help", result = 0)
  end
end
