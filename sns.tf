resource "aws_sns_topic_subscription" "hhc" {

  for_each = { for name, event in var.event_name : name => event if event["sns_subscription_enabled"] }

  topic_arn = aws_sns_topic.hhc.arn
  protocol  = each.value["lambda_subscription_protocol"]
  endpoint  = each.value["lambda_subscription_endpoint"]
  filter_policy = jsonencode({
    model_name = each.value["sns_subscription_filter"]
  })

}

data "aws_iam_policy_document" "sns_topic_policy" {

  statement {
    actions = [
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:ListSubscriptionsByTopic",
      "SNS:ListTagsForResource",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
      "SNS:TagResource",
      "SNS:UntagResource"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.hhc.arn,
    ]

  }

  statement {
    sid = "__Lambda_Access_ID"
    actions = [
      "SNS:ListSubscriptionsByTopic",
      "SNS:ListTagsForResource",
      "SNS:GetTopicAttributes",
      "SNS:Publish"
    ]
    effect = "Allow"
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"

      values = [
        aws_iam_role.lambda_permissions_role.arn
      ]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      aws_sns_topic.hhc.arn,
    ]

  }

}

resource "aws_sns_topic_policy" "hhc" {
  arn    = aws_sns_topic.hhc.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_sns_topic" "hhc" {
  name         = "ead_data_transfer_global_to_china"
  display_name = "ead_data_transfer_global_to_china"
  tags = merge(var.billing_tags, {
    git_org   = "SEA"
    git_repo  = "cloud-analytics"
    yor_trace = "954e452d-8731-439c-9524-780a932f07aa"
  })
  kms_master_key_id = "alias/aws/sns"
}
