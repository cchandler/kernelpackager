#!/usr/bin/env ruby

require 'digest'
require 'logger'

require 'thor'
require 'terrapin'

BUILD_DIRECTORY = "/home/ubuntu"
S3_BUCKET = "s3://squanderingti.me.kernel"

$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG

class Packager < Thor
	desc 'package', 'Package up a kernel build'
	def package()
		$logger.debug("Switching to $BUILD_DIRECTORY - #{BUILD_DIRECTORY}")
		Dir.chdir(BUILD_DIRECTORY)
		if File.exist?("all_kernel.tbz")
			$logger.debug("All kernel already exists. Replacing.")
		end
		line = Terrapin::CommandLine.new("tar cfj all_kernel.tbz *.deb")
		line.run

		# TODO: Add a bunch of error handling. If we get here it was successful
		digest_value = Digest::SHA256.hexdigest(File.read("all_kernel.tbz"))
		$logger.debug("Digest: #{digest_value}")

		line = Terrapin::CommandLine.new("aws s3 cp all_kernel.tbz #{S3_BUCKET}")
		line.run

		$logger.debug("Uploaded")

		line = Terrapin::CommandLine.new("aws s3 presign #{S3_BUCKET}/all_kernel.tbz")
		output = line.run
		$logger.debug(output)
	end
end

Packager.start(ARGV)
