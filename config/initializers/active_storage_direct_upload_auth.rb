# ActiveStorage::DirectUploadsController doesn't inherit the app's ApplicationController,
# so it skips the app's Authentication concern by default. Patch it in after Rails has
# loaded the real controller (to_prepare runs after autoloading), so anonymous visitors
# can't POST here and write blobs straight into the S3 bucket.
Rails.application.config.to_prepare do
  unless ActiveStorage::DirectUploadsController.ancestors.include?(Authentication)
    ActiveStorage::DirectUploadsController.include(Authentication)
  end
end
