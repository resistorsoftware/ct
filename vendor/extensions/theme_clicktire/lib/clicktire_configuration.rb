# setup AWS preferences here so we can keep images in S3 for now.
class ClicktireConfiguration < Configuration
  preference :bucket, :string, :default => ENV["S3_BUCKET"] ||= "clicktire"
  preference :access_key_id, :string, :default => ENV["S3_KEY"] ||= 'AKIAJXUMPE6CXKWKQ7OA'
  preference :secret_access_key, :string, :default => ENV["S3_SECRET"] ||= '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'
end