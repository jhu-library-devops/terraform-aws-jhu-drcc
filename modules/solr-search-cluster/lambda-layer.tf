# Archive lambda layer source code
data "archive_file" "solr_ops_layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/solr-ops-layer"
  output_path = "${path.module}/lambda/solr-ops-layer.zip"
}

# Lambda layer for Solr operations
resource "aws_lambda_layer_version" "solr_ops_layer" {
  filename            = data.archive_file.solr_ops_layer_zip.output_path
  layer_name          = "${local.name}-solr-operations"
  compatible_runtimes = ["python3.11"]
  source_code_hash    = data.archive_file.solr_ops_layer_zip.output_base64sha256
}
